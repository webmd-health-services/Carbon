
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

    $script:tempDir = $null
}

# Only failing on 2019 build servers, but don't have time to figure out why.
$skip = (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' #-and $PSVersionTable['PSVersion'].Major -eq 7

Describe 'Get-CDscError' -Skip:$skip {
    BeforeEach {
        $script:tempDir = New-CTempDirectory -Prefix $PSCommandPath
        [Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog('Microsoft-Windows-DSC/Operational')
    }

    AfterEach {
        Remove-Item $script:tempDir.FullName -Recurse
    }

    It 'should get dsc errors' {
        configuration IAmBroken
        {
            Set-StrictMode -Off

            node 'localhost'
            {
                Script Fails
                {
                     GetScript = { Write-Error 'GetScript' }
                     SetScript = { Write-Error 'SetScript' }
                     TestScript = { Write-Error 'TestScript' ; return $false }
                }
            }
        }

        [Diagnostics.Eventing.Reader.EventLogRecord[]]$errorsAtStart = Get-CDscError
        $errorsAtStart | Should -BeNullOrEmpty

        $startTime = Get-Date

        & IAmBroken -OutputPath $script:tempDir.FullName -WarningAction Ignore

        Start-Sleep -Milliseconds 400

        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $script:tempDir.FullName -ErrorAction SilentlyContinue -Force

        $dscError = Get-CDscError -StartTime $startTime -Wait
        $dscError | Should -Not -BeNullOrEmpty
        $dscError | Should -BeOfType ([Diagnostics.Eventing.Reader.EventLogRecord])

        [Diagnostics.Eventing.Reader.EventLogRecord[]]$dscErrors = Get-CDscError
        $dscErrors | Should -Not -BeNullOrEmpty
        $dscErrors.Count | Should -BeGreaterThan 0

        [Diagnostics.Eventing.Reader.EventLogRecord[]]$dscErrorsBefore = Get-CDscError -EndTime $startTime
        $dscErrorsBefore | Should -BeNullOrEmpty

        Start-Sleep -Milliseconds 800
        $Error.Clear()
        $dscErrors = Get-CDscError -StartTime (Get-Date)
        $Global:Error.Count | Should -Be 0
        $dscErrors | Should -BeNullOrEmpty

        # Now, make sure the timeout is customizable.
        $startedAt = Get-Date
        $dscErrors = Get-CDscError -StartTime (Get-Date) -Wait -WaitTimeoutSeconds 1
        $Global:Error.Count | Should -Be 0
        ((Get-Date) -gt $startedAt.AddSeconds(1)) | Should -Be $true

        $result = Get-CDscError -ComputerName 'fubar' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
        $result | Should -BeNullOrEmpty

        # Now, make sure you can get stuff from multiple computers
        $dscError = Get-CDscError -ComputerName 'localhost',$env:COMPUTERNAME
        $dscError | Should -Not -BeNullOrEmpty
    }
}
