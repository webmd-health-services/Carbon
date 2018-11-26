
function Uninstall-WhiskeyPowerShellModule
{
    <#
    .SYNOPSIS
    Removes downloaded PowerShell modules.
    
    .DESCRIPTION
    The `Uninstall-WhiskeyPowerShellModule` function deletes downloaded PowerShell modules from Whiskey's local "PSModules" directory.

    .EXAMPLE
    Uninstall-WhiskeyPowerShellModule -Name 'Pester'

    This example will uninstall the PowerShell module `Pester` from Whiskey's local `PSModules` directory.
    
    .EXAMPLE
    Uninstall-WhiskeyPowerShellModule -Name 'Pester' -ErrorAction Stop

    Demonstrates how to fail a build if uninstalling the module fails by setting the `ErrorAction` parameter to `Stop`.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module to uninstall.
        $Name,

        [string]
        $Version = '*.*.*',

        # Modules are saved into a PSModules directory. The "Path" parameter is the path where this PSModules directory should be, *not* the path to the PSModules directory itself, i.e. this is the path to the "PSModules" directory's parent directory.
        $Path = (Get-Location).ProviderPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Get-Module -Name $Name | Remove-Module -Force

    $modulesRoot = Join-Path -Path $Path -ChildPath $powerShellModulesDirectoryName
    # Remove modules saved by either PowerShell4 or PowerShell5
    $moduleRoots = @( ('{0}\{1}' -f $Name, $Version), ('{0}' -f $Name)  )
    foreach ($item in $moduleRoots)
    {
        $removeModule = (Join-Path -Path $modulesRoot -ChildPath $item )
        if( Test-Path -Path $removeModule -PathType Container )
        {
            Remove-Item -Path $removeModule -Recurse -Force
            return
        }
    }
}
