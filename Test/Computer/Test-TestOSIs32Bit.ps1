
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldDetectIfOSIs32Bit
{
    $is32Bit = -not (Test-Path env:"ProgramFiles(x86)")
    Assert-Equal $is32Bit (Test-OSIs32Bit)
}