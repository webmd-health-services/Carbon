

function SetUp()
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown()
{
    Remove-Module Carbon
}

function Test-GetFullPath
{
    $fullpath = Get-FullPath (Join-Path $TestDir '..\Tests' )
    $expectedFullPath = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\Tests') )
    Assert-Equal $expectedFullPath $fullPath "Didn't get full path for '..\Tests'."
}