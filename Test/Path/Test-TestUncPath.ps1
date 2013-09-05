
function Setup
{
    & (Join-Path -Path $TestDir -ChildPath ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
}

function Test-ShouldTestUncPath
{
    Assert-True (Test-UncPath -Path '\\computer\share')
}

function Test-ShouldTestRelativePath
{
    Assert-False (Test-UncPath -Path '..\..\foo\bar')
}

function Test-ShouldTestNtfsPath
{
    Assert-False (Test-UncPath -Path 'C:\foo\bar\biz\baz\buz')
}
