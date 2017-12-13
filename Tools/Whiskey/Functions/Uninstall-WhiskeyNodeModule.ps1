
function Uninstall-WhiskeyNodeModule
{
    <#
    .SYNOPSIS
    Uninstalls Node.js modules.
    
    .DESCRIPTION
    The `Uninstall-WhiskeyNodeModule` function will uninstall Node.js modules from the `node_modules` directory in the `ApplicationRoot`. The function will use `Invoke-WhiskeyNpmCommand` to run `npm prune` on the given module `Name`.
    
    If the `npm prune` command fails to uninstall the module and the `Force` parameter was not specified then the function will write an error and return. If the `Force` parameter is specified then the function will attempt to manually remove the module if `npm prune` fails.
    
    .EXAMPLE
    Uninstall-WhiskeyNodeModule -Name 'rimraf' -Application 'C:\build\app' -RegistryUri 'http://registry.npmjs.org'
    
    Removes the node module 'rimraf' from 'C:\build\app\node_modules' using 'npm prune'.

    .EXAMPLE
    Uninstall-WhiskeyNodeModule -Name 'rimraf' -Application 'C:\build\app' -RegistryUri 'http://registry.npmjs.org' -Force
    
    Removes the node module 'rimraf' from 'C:\build\app\node_modules' manually if 'npm prune' fails to fully remove the module.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module to uninstall.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The root directory of the target Node.js application. This directory will contain the application's `package.json` config file and will be where Node modules are uninstalled from.
        $ApplicationRoot,

        [Parameter(Mandatory=$true)]
        # The URI to the registry from which Node modules should be downloaded if needed during the uninstall process.
        $RegistryUri,

        [switch]
        # Node modules are being uninstalled on a developer computer.
        $ForDeveloper,

        [switch]
        # Remove the module manually if NPM fails to uninstall it
        $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-WhiskeyNpmCommand -NpmCommand 'prune' -Argument $Name -ApplicationRoot $ApplicationRoot -RegistryUri $RegistryUri -ForDeveloper:$ForDeveloper
    
    $modulePath = Join-Path -Path $ApplicationRoot -ChildPath ('node_modules\{0}' -f $Name)

    if (Test-Path -Path $modulePath -PathType Container)
    {
        if ($Force)
        {
            # Try to remove the module manually if 'npm prune' failed
            $emptyDir = New-Item -Name ([System.IO.Path]::GetRandomFileName()) -Path $ApplicationRoot -ItemType 'Directory' -Force
            Invoke-WhiskeyRobocopy -Source $emptyDir -Destination $modulePath | Write-Debug
            Remove-Item -Path $emptyDir -Force
            Remove-Item -Path $modulePath -Force
        }
        else
        {
            Write-Error -Message ('Failed to remove Node module ''{0}'' from ''{1}''. See previous errors for more details.' -f $Name,$modulePath)
            return
        }
    }

    if (Test-Path -Path $modulePath -PathType Container)
    {
        Write-Error -Message ('Failed to remove Node module ''{0}'' from ''{1}'' using both ''npm prune'' and manual removal. See previous errors for more details.' -f $Name,$modulePath)
        return
    }
}
