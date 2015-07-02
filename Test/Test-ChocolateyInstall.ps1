
$chocolateyInstall = Join-Path -Path $PSScriptRoot -ChildPath '..\tools\chocolateyInstall.ps1' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$destinationDir = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath 'Carbon'

function Start-Test
{
    Stop-Test
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
}

function Test-ShouldCopyIntoModuleInstallDirectory
{
    Assert-DirectoryDoesNotExist $destinationDir
    & $chocolateyInstall
    Assert-DirectoryExists $destinationDir 
    $sourceCount = (Get-ChildItem $destinationDir -Recurse | Measure-Object).Count
    $destinationCount = (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon') -Recurse | Measure-Object).Count
    Assert-Equal  $sourceCount $destinationCount
}

function Test-ShouldRemoveWhatIsThere
{
    New-Item -Path $destinationDir -ItemType 'Directory'
    $deletedRecurseFilePath = Join-Path -Path $destinationDir -ChildPath 'should\deleteme.txt'
    $deletedRootFilePath = Join-Path -Path $destinationDir -ChildPath 'deleteme.txt'
    New-Item -Path $deletedRecurseFilePath -ItemType 'File' -Force
    New-Item -Path $deletedRootFilePath -ItemType 'File' -Force

    Assert-FileExists $deletedRootFilePath
    Assert-FileExists $deletedRecurseFilePath

    & $chocolateyInstall

    Assert-FileDoesNotExist $deletedRootFilePath
    Assert-FileDoesNotExist $deletedRecurseFilePath
}

function Test-ShouldHandleModuleInUse
{
    & $chocolateyInstall

    $markerFile = Join-Path -Path $destinationDir -ChildPath 'shouldnotgetdeleted'
    New-Item -Path $markerFile -ItemType 'file'
    Assert-FileExists $markerFile

    $carbonDllPath = Join-Path -Path $destinationDir -ChildPath 'bin\Carbon.dll' -Resolve

    $preCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'

    $file = [IO.File]::Open($carbonDllPath, 'Open', 'Read', 'Read')
    try
    {
        & $chocolateyInstall
    }
    catch
    {
    }
    finally
    {
        $file.Close()
    }
    Assert-Error -Last -Regex 'Access to the path .* denied'
    Assert-FileExists $markerFile

    $postCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    Assert-Equal $preCount $postCount 'some files were deleted during upgrade'
}
