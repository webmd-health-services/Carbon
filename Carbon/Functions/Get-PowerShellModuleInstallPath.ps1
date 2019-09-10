
function Get-CPowerShellModuleInstallPath
{
    <#
    .SYNOPSIS
    Returns the path to the directory where you can install custom modules.

    .DESCRIPTION
    Custom modules should be installed under the `Program Files` directory. This function looks at the `PSModulePath` environment variable to find the install location under `Program Files`. If that path isn't part of the `PSModulePath` environment variable, returns the module path under `$PSHOME`. If that isn't part of the `PSModulePath` environment variable, an error is written and nothing is returned.

    `Get-CPowerShellModuleInstallPath` is new in Carbon 2.0.

    .EXAMPLE
    Get-CPowerShellModuleInstallPath

    Demonstrates how to get the path where modules should be installed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $modulePaths = $env:PSModulePath -split ';'

    $programFileModulePath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
    if( (Test-Path -Path 'Env:\ProgramW6432') )
    {
        $programFileModulePath = Join-Path -Path $env:ProgramW6432 -ChildPath 'WindowsPowerShell\Modules'
    }

    $installRoot = $modulePaths | 
                        Where-Object { $_.TrimEnd('\') -eq $programFileModulePath } |
                        Select-Object -First 1
    if( $installRoot )
    {
        return $programFileModulePath
    }

    $psHomeModulePath = Join-Path -Path $env:SystemRoot -ChildPath 'system32\WindowsPowerShell\v1.0\Modules'

    $installRoot = $modulePaths | 
                        Where-Object { $_.TrimEnd('\') -eq $psHomeModulePath } |
                        Select-Object -First 1
    if( $installRoot )
    {
        return $psHomeModulePath
    }

    Write-Error -Message ('PSModulePaths ''{0}'' and ''{1}'' not found in the PSModulePath environment variable.' -f $programFileModulePath,$psHomeModulePath)
}
