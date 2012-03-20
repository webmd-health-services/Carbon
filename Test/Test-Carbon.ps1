
function Setup
{
    Import-Module (Join-Path $TestDir ..\Carbon -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldSetsOSArchitectureVariables
{
    $wmiOS = Get-WmiObject Win32_OperatingSystem
    Assert-Equal $Is32BitOS ($wmiOS.OSArchitecture -ne '64-bit')
    Assert-Equal $Is64BitOS ($wmiOS.OSArchitecture -eq '64-bit')
}