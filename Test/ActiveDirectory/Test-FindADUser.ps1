
$domainUrl = "LDAP://dc01l-crp-04.webmdhealth.net:389"
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldFindUser
{
    $me = Find-ADUser -DomainUrl $domainUrl -sAMAccountName ajensen
    Assert-NotNull $me
    Assert-Equal 'Jensen, Aaron' $me.name
}

function Test-ShouldEscapeSpecialCharacters
{
    $me = Find-ADUser -DomainUrl $domainUrl -sAMAccountName "(user*with\special/characters)"
    Assert-Null $me
}