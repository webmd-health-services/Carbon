

$SiteName = 'TestSite'

function SetUp()
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
    Remove-TestWebsite
}

function TearDown()
{
    Remove-TestWebsite
    Remove-Module Carbon
}

function Remove-TestWebsite
{
    if( Test-IisWebsiteExists -Name $SiteName )
    {
        Remove-IisWebsite -Name $SiteName
        Assert-LastProcessSucceeded 'Unable to delete test site.'
    }
}

function Invoke-RemoveWebsite($Name = $SiteName)
{
    Remove-IisWebsite $Name
    Assert-SiteDoesNotExist $Name
}

function Test-ShouldRemoveNonExistentSite
{
    Invoke-RemoveWebsite 'fjsdklfsdjlf'
}

function Test-ShouldRemoveSite
{
    Install-IisWebsite -Name $SiteName -Path $TestDir
    Assert-LastProcessSucceeded 'Unable to create site.'
    
    Invoke-RemoveWebsite

    Assert-SiteDoesNotExist $SiteName    
}

function Assert-SiteDoesNotExist($Name)
{
    Assert-False (Test-IisWebsiteExists -Name $Name) "Website $Name exists!"
}
