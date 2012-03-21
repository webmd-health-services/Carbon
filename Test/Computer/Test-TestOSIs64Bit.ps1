
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldDetectIfOSIs64Bit
{
    $is64Bit = (Test-Path env:"ProgramFiles(x86)")
    Assert-Equal $is64Bit (Test-OSIs64Bit)
}