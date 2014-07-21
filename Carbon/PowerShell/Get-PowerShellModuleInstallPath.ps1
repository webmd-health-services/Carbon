
function Get-PowerShellModuleInstallPath
{
    <#
    .SYNOPSIS
    Returns the path to the directory where you can install custom modules.

    .DESCRIPTION
    Custom modules should be installed under the `Program Files` directory. This function looks at the `PSModulePath` environment variable to find the install location under `Program Files`. If that path doesn't exist or isn't part of the `PSModulePath` environment variable, returns the module path under `$PSHOME`. If that path doesn't exist or isn't part of the `PSModulePath` environment variable, an error is written and nothing is returned.

    .EXAMPLE
    Get-PowerShellModuleInstallPath

    Demonstrates how to get the path where modules should be installed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
    )

    Set-StrictMode -Version 'Latest'

    $modulePaths = $env:PSModulePath -split ';' 
    $installRoot = $modulePaths | Where-Object { $_ -like ('{0}\*' -f $env:ProgramFiles) }
    if( -not $installRoot -or -not (Test-Path -Path $installRoot -PathType Container) )
    {
        Write-Verbose ('Module path under ''{0}'' not found.' -f $env:ProgramFiles)
        $installRoot = $modulePaths | Where-Object { $_ -like ('{0}\*' -f $env:SystemRoot) }
        if( -not $installRoot -or -not (Test-Path -Path $installRoot -PathType Container) )
        {
            Write-Verbose ('Module path under ''{0}'' not found.' -f $env:SystemRoot)
            Write-Error ('Module path under ''{0}'' and ''{1}'' not found.' -f $env:ProgramFiles,$env:SystemRoot)
            return
        }
    }

    return $installRoot

}