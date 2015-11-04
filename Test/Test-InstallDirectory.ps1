
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

$root = $env:TEMP

function Test-ShouldCreateDirectory
{
    $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
    Assert-DirectoryDoesNotExist $dir
    Install-Directory -Path $dir
    try
    {
        Assert-NoError
        Assert-DirectoryExists $dir
    }
    finally
    {
        Remove-Item $dir
    }
}

function Test-ShouldHandleExistingDirectory
{
    $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
    Assert-DirectoryDoesNotExist $dir
    Install-Directory -Path $dir
    try
    {
        Install-Directory -Path $dir
        Assert-NoError
        Assert-DirectoryExists $dir
    }
    finally
    {
        Remove-Item $dir
    }
}

function Test-ShouldCreateMissingParents
{
    $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
    $dir = Join-Path -Path $dir -ChildPath ([IO.Path]::GetRandomFileName())
    Assert-DirectoryDoesNotExist $dir
    Install-Directory -Path $dir
    try
    {
        Assert-NoError
        Assert-DirectoryExists $dir
    }
    finally
    {
        Remove-Item $dir
    }
}