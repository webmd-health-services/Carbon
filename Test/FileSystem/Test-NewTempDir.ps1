

function SetUp()
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown()
{
    Remove-Module Carbon
}

function Test-NewTempDir
{
    $tmpDir = New-TempDir 
    Assert-DirectoryExists $tmpDir
}