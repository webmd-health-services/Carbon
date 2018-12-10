
function Import-WhiskeyPowerShellModule
{
    <#
    .SYNOPSIS
    Imports a PowerShell module.

    .DESCRIPTION
    The `Import-WhiskeyPowerShellModule` function imports a PowerShell module that is needed/used by a Whiskey task. Since Whiskey tasks all run in the module's scope, the imported modules are imported into the global scope. If a module with the same name is currently loaded, it is removed and re-imported.
    
    The module must be installed in Whiskey's PowerShell modules directory. Use the `RequiresTool` attribute on a task to have Whiskey install a module in this directory or the `GetPowerShellModule` task to install a module in the appropriate place.

    Pass the name of the modules to the `Name` parameter.

    .EXAMPLE
    Import-WhiskeyPowerShellModule -Name 'BuildMasterAutomtion'

    Demonstrates how to use this method to import a single module.

    .EXAMPLE
    Import-WhiskeyPowerShellModule -Name 'BuildMasterAutomtion','ProGetAutomation'

    Demonstrates how to use this method to import multiple modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]
        # The module names to import.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    & {
        $VerbosePreference = 'SilentlyContinue'
        Get-Module -Name $Name | Remove-Module -Force -WhatIf:$false
    }

    $searchPaths = & {
                        Join-Path -Path (Get-Location).ProviderPath -ChildPath $powerShellModulesDirectoryName
                        Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
                   }

    foreach( $moduleName in $Name )
    {
        foreach( $searchDir in  $searchPaths )
        {
            $moduleDir = Join-Path -Path $searchDir -ChildPath $moduleName
            if( (Test-Path -Path $moduleDir -PathType Container) )
            {
                Write-Debug -Message ('PSModuleAutoLoadingPreference = "{0}"' -f $PSModuleAutoLoadingPreference)
                Write-Verbose -Message ('Import PowerShell module "{0}" from "{1}".' -f $moduleName,$searchDir)
                & {
                    $VerbosePreference = 'SilentlyContinue'
                    Import-Module -Name $moduleDir -Global -Force
                }
                break
            }
        }

        if( -not (Get-Module -Name $moduleName) )
        {
            Write-Error -Message ('Module "{0}" does not exist. Make sure your task uses the "RequiresTool" attribute so that the module gets installed automatically.' -f $moduleName)
        }
    }
}