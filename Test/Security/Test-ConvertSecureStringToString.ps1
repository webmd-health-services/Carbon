
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldConvertSecureStringToString
{
    $secret = "Hello World!"
    $secureString = ConvertTo-SecureString -String $secret -AsPlainText -Force
    $notSoSecret = Convert-SecureStringToString $secureString
    Assert-Equal $secret $notSoSecret "Didn't convert a secure string to a string."
}