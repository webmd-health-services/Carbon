
function Get-CPowerShellModuleInstallPath
{
    <#
    .SYNOPSIS
    Returns the path to the directory where you can install custom modules.

    .DESCRIPTION
    Custom modules should be installed under the `Program Files` directory. This function looks at the `PSModulePath`
    environment variable to find the install location under `Program Files`. If that path isn't part of the
    `PSModulePath` environment variable, returns the module path under `$PSHOME`. If that isn't part of the
    `PSModulePath` environment variable, an error is written and nothing is returned.

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

    $edition = 'WindowsPowerShell'
    if ($PSVersionTable['PSEdition'] -eq 'Core')
    {
        $edition = 'PowerShell'
    }

    $programFileModulePath =
        Join-Path -Path ([Environment]::GetFolderPath('ProgramFiles')) -ChildPath "${edition}\Modules"
    if (([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess))
    {
        $programFileModulePath =
            Join-Path -Path ([Environment]::GetFolderPath('ProgramFilesX86')) -ChildPath "${edition}\Modules"
    }

    $modulePaths = $env:PSModulePath -split ';'

    $installRoot = $modulePaths | Where-Object { $_.TrimEnd('\') -eq $programFileModulePath } | Select-Object -First 1
    if ($installRoot)
    {
        return $programFileModulePath
    }

    $psHomeModulePath = Join-Path -Path $PSHOME -ChildPath 'Modules'

    $installRoot = $modulePaths | Where-Object { $_.TrimEnd('\') -eq $psHomeModulePath } | Select-Object -First 1
    if ($installRoot)
    {
        return $psHomeModulePath
    }

    $msg = "PSModulePaths ""${programFileModulePath}"" and ""${psHomeModulePath}"" not found in the PSModulePath " +
           'environment variable.'
    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
}
