
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldDetect64BitProcess
{
    $expectedResult = ( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
    Assert-Equal $expectedResult (Test-ProcessIs64Bit)
}
