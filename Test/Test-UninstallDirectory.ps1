
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

function Start-Test
{
    $dir = Join-Path -Path $env:TEMP -ChildPath ([IO.Path]::GetRandomFileName())
    Install-Directory -Path $dir
}

function Stop-Test
{
    if( (Test-Path -Path $dir -PathType Container) )
    {
        Remove-Item -Path $dir -Recurse
    }
}

function Test-ShouldRemoveDirectory
{
    Uninstall-Directory -Path $dir
    Assert-NoError
    Assert-DirectoryDoesNotExist $dir
}

function Test-ShouldHandleDirectoryThatDoesNotExist
{
    Uninstall-Directory -Path $dir
    Uninstall-Directory -Path $dir
    Assert-NoError
    Assert-DirectoryDoesNotExist $dir
}

function Test-ShouldDeleteRecursively
{
    $filePath = Join-Path -Path $dir -ChildPath 'file'
    New-Item -Path $filePath -ItemType 'File'
    Uninstall-Directory -Path $dir -Recurse
    Assert-NoError
    Assert-DirectoryDoesNotExist $dir
}