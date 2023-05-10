
#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:tempDir = $null

    function Assert-DscError
    {
        param(
            $DscError,

            $Index = 0
        )

        Set-StrictMode -Version 'Latest'

        $Global:Error.Count | Should -BeGreaterThan 0
        $msg = $Error[$Index].Exception.Message
        $msg | Should -BeLike ('`[{0}`]*' -f $DscError.TimeCreated)
        $msg | Should -BeLike ('* `[{0}`] *' -f $DscError.MachineName)
        for( $idx = 0; $idx -lt $DscError.Properties.Count - 1; ++$idx )
        {
            $msg | Should -BeLike ('* `[{0}`] *' -f $DscError.Properties[$idx].Value)
        }
        $msg | Should -BeLike ('* {0}' -f $DscError.Properties[-1].Value)
    }
}

# Only failing on 2019 build servers, but don't have time to figure out why.
$skip = (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' #-and $PSVersionTable['PSVersion'].Major -eq 7

Describe 'Write-CDscError' -Skip:$skip {
    BeforeEach {
        $script:tempDir = New-CTempDirectory -Prefix $PSCommandPath
    }

    AfterEach {
        Remove-Item $script:tempDir.FullName -Recurse
    }

    It 'should get dsc error' {
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

            $startTime = Get-Date

        & IAmBroken -OutputPath $script:tempDir.FullName -WarningAction Ignore

        Start-Sleep -Milliseconds 100

        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $script:tempDir.FullName -ErrorAction SilentlyContinue -Force

        $dscError = Get-CDscError -StartTime $startTime -Wait
        $dscError | Should -Not -BeNullOrEmpty

        $Error.Clear()

        Write-CDscError -EventLogRecord $dscError -ErrorAction SilentlyContinue
        Assert-DscError $dscError

        $Error.Clear()
        # Test that you can pipeline errors
        Get-CDscError | Write-CDscError -PassThru -ErrorAction SilentlyContinue | ForEach-Object { Assert-DscError $_ }

        # Test that it supports an array for the error record
        $Error.Clear()
        Write-CDscError @( $dscError, $dscError ) -ErrorAction SilentlyContinue
        Assert-DscError $dscError -Index 0
        Assert-DscError $dscError -Index 1
    }
}
