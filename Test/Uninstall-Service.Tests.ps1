
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:serviceBaseName = 'CarbonUninstallServiceTest'
    $script:serviceName = $script:serviceBaseName
    $script:servicePath = Join-Path -Path $PSScriptRoot -ChildPath 'Service\NoOpService.exe' -Resolve

    function Uninstall-TestService
    {
        if( (Get-Service $script:serviceName -ErrorAction Ignore) )
        {
            Stop-Service $script:serviceName
            & C:\Windows\system32\sc.exe delete $script:serviceName
        }
    }

    function GivenServiceStillRunsAfterStop
    {
        Mock -CommandName 'Stop-Service' -ModuleName 'Carbon'
    }

    function ThenServiceUninstalled
    {
        param(
            [Parameter(Mandatory)]
            [string]
            $Named
        )

        while( (Get-Service $Named -ErrorAction Ignore) )
        {
            Write-Verbose -Message ('Waiting for "{0}" to get uninstalled.' -f $Named) -Verbose
            Start-Sleep -Seconds 1
        }

        Get-Service $Named -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    function WhenUninstalling
    {
        param(
            [Parameter(Mandatory)]
            [string]
            $Named,

            $WithTimeout
        )

        $optionalParams = @{ }
        if( $WithTimeout )
        {
            $optionalParams['StopTimeout'] = $WithTimeout
        }

        Uninstall-CService -Name $Named @optionalParams
    }
}

AfterAll {
    Uninstall-TestService
}

Describe 'Uninstall-CService' {
    BeforeEach {
        $Global:Error.Clear()
        Uninstall-TestService
        Install-CService -Name $script:serviceName -Path $script:servicePath
    }

    It 'should remove service' {
        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty
        $output = Uninstall-CService -Name $script:serviceName
        $output | Should -BeNullOrEmpty
        $service = Get-Service -Name $script:serviceName -ErrorAction SilentlyContinue
        $service | Should -BeNullOrEmpty
    }

    It 'should not remove non existent service' {
        Uninstall-CService -Name "IDoNotExist"
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should support what if' {
        Uninstall-CService -Name $script:serviceName -WhatIf
        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty
    }

    It 'when service doesn''t stop' {
        GivenServiceStillRunsAfterStop
        WhenUninstalling $script:serviceName
        ThenServiceUninstalled $script:serviceName
    }

    It 'when waiting for service to really stop' {
        GivenServiceStillRunsAfterStop
        WhenUninstalling $script:serviceName -WithTimeout (New-TimeSpan -Seconds 1)
        ThenServiceUninstalled $script:serviceName
    }

    It 'when service never stops' {
        GivenServiceStillRunsAfterStop
        Mock -CommandName 'Get-Process' -ModuleName 'Carbon' { return [pscustomobject]@{ Id = $Id[0] } }
        Mock -CommandName 'Start-Sleep' -ModuleName 'Carbon'
        WhenUninstalling $script:serviceName  -ErrorAction SilentlyContinue
        $Global:Error[0] | Should -Match 'Failed to kill'
        ThenServiceUninstalled $script:serviceName
    }

    It 'when service stops before getting killed' {
        GivenServiceStillRunsAfterStop
        $global:callCount = 0
        Mock -CommandName 'Get-Process' -ModuleName 'Carbon' -MockWith {
            $global:callCount++
            if( $global:callCount -eq 1 )
            {
                [pscustomobject]@{ Id = $Id[0] }
            }
            else
            {
                foreach( $item in $ID )
                {
                    $process = [Diagnostics.Process]::GetProcessById($item)
                    if( $process )
                    {
                        $process.Kill()
                        $process.WaitForExit()
                    }
                }
            }
        }
        Mock -CommandName 'Stop-Process' -ModuleName 'Carbon' -MockWith {
            Write-Error 'FUBAR!' -ErrorAction $PesterBoundParameters['ErrorAction'] }
        WhenUninstalling $script:serviceName
        $Global:Error | Where-Object { $_ -match 'FUBAR' } | Should -BeNullOrEmpty
        ThenServiceUninstalled $script:serviceName
        Remove-Variable -Name 'callCount' -Scope Global
    }
}