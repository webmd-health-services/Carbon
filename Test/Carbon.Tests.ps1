
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve) -Verbose:$false
}

Describe 'Carbon' {
    Context 'Obsolete Functions' {
        $testCases = @(
            # Carbon.Windows.Installer
            @{
                Name = 'Get-CProgramInstallInfo'
                MigratedTo = 'Carbon.Windows.Installer'
                MigratedAs = 'Get-CInstalledProgram'
            },
            # Carbon.Windows.Service
            @{
                Name = 'Assert-CService'
                CmdArgs = @{ Name = 'W32Time' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Get-CServiceAcl'
                CmdArgs = @{ Name = 'W32Time' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Get-CServiceConfiguration'
                CmdArgs = @{ Name = 'W32Time' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Get-CServicePermission'
                CmdArgs = @{ Name = 'W32Time' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Get-CServiceSecurityDescriptor'
                CmdArgs = @{ Name = 'W32Time' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Grant-CServiceControlPermission'
                CmdArgs = @{ ServiceName = 'W32Time' ; Identity = 'IDoNotExist' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Grant-CServicePermission'
                CmdArgs = @{ Name = 'W32Time' ; Identity = 'IDoNotExist' ; QueryConfig = $true }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Install-CService'
                CmdArgs = @{ Name = 'IDoNotExist' ; Path = $PSCommandPath ; Dependency = 'IDoNotExist' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Restart-CRemoteService'
                CmdArgs = @{ Name = 'IDoNotExist' ; ComputerName = '.' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Revoke-CServicePermission'
                CmdArgs = @{ Name = 'IDoNotExist' ; Identity = 'IDoNotExist' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Set-CServiceAcl'
                CmdArgs = @{ Name = 'IDoNotExist' ; Dacl = (Get-CServiceAcl -Name 'W32Time' -NoWarn) }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Test-CService'
                CmdArgs = @{ Name = 'W32Time' }
                MigratedTo = 'Carbon.Windows.Service'
            },
            @{
                Name = 'Uninstall-CService'
                CmdArgs = @{ Name = 'IDoNotExist' }
                MigratedTo = 'Carbon.Windows.Service'
            }
        )

        BeforeAll {
            Remove-Module 'Carbon' -ErrorAction Ignore
            Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve)
        }

        Context '<Name>' -ForEach $testCases {
            It 'can hide its obsolete warning' {
                if (-not (Test-Path -Path 'variable:CmdArgs'))
                {
                    $CmdArgs = @{}
                }

                $warnings = @('should be replaced')
                try
                {
                    & $Name @CmdArgs -WarningVariable 'warnings' -Nowarn -ErrorAction SilentlyContinue
                }
                catch
                {

                }
                $warnings | Should -BeNullOrEmpty
            }

            It 'warns it is obsolete' {
                if (-not (Test-Path -Path 'variable:CmdArgs'))
                {
                    $CmdArgs = @{}
                }

                $warnings = @()
                try
                {
                    & $Name @CmdArgs -WarningVariable 'warnings' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                }
                catch
                {
                }

                $warnings | Should -Not -BeNullOrEmpty
                $warnings | Should -BeLike "*${Name}*"
                if ($MigratedTo)
                {
                    $warnings | Should -BeLIke "*MOVED to new ""${MigratedTo}"" module*"
                }

                if ((Test-Path -Path 'variable:MigratedAs'))
                {
                    $warnings | Should -BeLike "*${MigratedAs}*"
                }
            }
        }
    }
}