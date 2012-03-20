
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldEscapeADSpecialCharacters
{
    $specialCharacters = "*()\`0/"
    $escapedCharacters = Format-ADSpecialCharacters -String $specialCharacters
    Assert-Equal '\2a\28\29\5c\00\2f' $escapedCharacters
}