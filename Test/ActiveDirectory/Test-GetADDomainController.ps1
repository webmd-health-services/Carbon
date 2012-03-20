
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldFindDomainController
{
    $domainController = Get-ADDomainController
    
    Assert-NotNull $domainController
    
    Assert-CanFindCurrentUser $domainController
    
}

function Test-ShouldFindDomainControllerForSpecificDomain
{
    $domainController = Get-ADDomainController -Domain $env:USERDOMAIN
    
    Assert-NotNull $domainController
    
    Assert-CanFindCurrentUser $domainController
}

function Test-ShouldNotFindNonExistentDomain
{
    $error.Clear()
    $domainController = Get-ADDomainController -Domain 'FJDSKLJDSKLFJSDA' -ErrorAction SilentlyContinue
    Assert-Null $domainController
    Assert-equal 2 $error.Count
}

function Assert-CanFindCurrentUser($domainController)
{
    $domain = [adsi] "LDAP://$domainController"
    $searcher = [adsisearcher] $domain
    
    $filterPropertyName = 'sAMAccountName'
    $filterPropertyValue = $sAMAccountName
    
    $searcher.Filter = "(&(objectClass=User) (sAMAccountName=$($env:Username)))"
    $result = $searcher.FindOne() 
    Assert-NotNull $result
}

