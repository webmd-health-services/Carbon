
$JunctionPath = $null

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $JunctionPath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Junction $JunctionPath $TestDir
}

function TearDown
{
    if( Test-Path $JunctionPath -PathType Container )
    {
        cmd /c rmdir $JunctionPath
    }
    Remove-Module Carbon
}

function Invoke-RemoveJunction($junction)
{
    Remove-Junction $junction
}

function Test-ShouldRemoveJunction
{
    Invoke-RemoveJunction $JunctionPath
    Assert-LastProcessSucceeded 'Failed to delete junction.'
    Assert-DirectoryDoesNotExist $JunctionPath 'Failed to delete junction.'
}

function Test-ShouldDoNothingIfJunctionActuallyADirectory
{
    $realDir = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Item $realDir -ItemType 'Directory'
    Invoke-RemoveJunction $realDir 2> $null
    Assert-DirectoryExists $realDir 'Real directory was removed.'
    Assert-Equal 1 $error.Count "Didn't write out any errors."
    Remove-Item $realDir
}

function Test-ShouldDoNothingIfJunctionActuallyAFile
{
    $path = [IO.Path]::GetTempFileName()
    Invoke-RemoveJunction $path 2> $null
    Assert-FileExists $path 'File was deleted'
    Assert-Equal 1 $error.Count "Didn't write out any errors."
    Remove-Item $path
}

function Test-ShouldSupportWhatIf
{
    Remove-Junction -Path $JunctionPath -WhatIf
    Assert-DirectoryExists $JunctionPath
    Assert-FileExists (Join-Path $JunctionPath Test-RemoveJunction.ps1)
    Assert-DirectoryExists $TestDir
}

