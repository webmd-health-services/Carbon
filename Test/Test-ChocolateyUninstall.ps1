
$chocolateyInstall = Join-Path -Path $PSScriptRoot -ChildPath '..\tools\chocolateyInstall.ps1' -Resolve
$chocolateyUninstall = Join-Path -Path $PSScriptRoot -ChildPath '..\tools\chocolateyUninstall.ps1' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$destinationDir = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath 'Carbon'

function Start-Test
{
    & $chocolateyInstall
    Assert-NoError
    Assert-DirectoryExists $destinationDir
}

function Stop-Test
{
    $moduleDir = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath 'Carbon'
    if( (Test-PathIsJunction -Path $moduleDir) )
    {
        Uninstall-Junction -Path $moduleDir
    }
    elseif( (Test-Path -Path $moduleDir -PathType Container) )
    {
        Remove-Item -Path $moduleDir -Recurse -Force
    }

    Get-ChildItem -Path (Get-PowerShellModuleInstallPath) -Filter 'Carbon*.*' | Remove-Item -Recurse -Force
}

function Test-ShouldRemoveCarbonModule
{
    & $chocolateyUninstall -Verbose
    Assert-CarbonUninstalled
}

function Test-ShouldDeleteNothingIfModuleInUse
{
    $preCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'

    $carbonDllPath = Join-Path -Path $destinationDir -ChildPath 'bin\Carbon.dll' -Resolve
    $file = [IO.File]::Open($carbonDllPath, 'Open', 'Read', 'Read')
    try
    {
        & $chocolateyUninstall
    }
    catch
    {
    }
    finally
    {
        $file.Close()
    }
    Assert-Error
    Assert-DirectoryExists $destinationDir

    # Make sure no files were deleted during a failed uninstall
    $postCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    Assert-Equal $preCount $postCount 'some files were deleted during failed uninstall'
}

function Test-ShouldDeleteIfModuleNotInstalled
{
    & $chocolateyUninstall
    Assert-CarbonUninstalled

    & $chocolateyUninstall
    Assert-NoError
}

function Assert-CarbonUninstalled
{
    Assert-DirectoryDoesNotExist $destinationDir
    Assert-Null (Get-ChildItem -Path (Get-PowerShellModuleInstallPath) -Filter 'Carbon*')
}