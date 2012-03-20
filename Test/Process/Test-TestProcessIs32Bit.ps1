
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldDetect32BitProcess
{
    $expectedResult = ( $env:PROCESSOR_ARCHITECTURE -eq 'x86' )
    Assert-Equal $expectedResult (Test-ProcessIs32Bit)
}
