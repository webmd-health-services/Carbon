
$siteName = 'Anonymous Authentication'
$sitePort = 4387
$webConfigPath = Join-Path $TestDir web.config

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Remove-IisWebsite $siteName
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort"
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function TearDown
{
    Remove-IisWebsite $siteName
    Remove-Module Carbon
}

function Test-ShouldEnableAnonymousAuthentication
{
    Set-IISAnonymousAuthentication -SiteName $siteName
    Assert-AnonymousAuthentication -Enabled 'true'
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableAnonymousAuthenticationOnSubFolders
{
    Set-IISAnonymousAuthentication -SiteName $siteName -Path SubFolder
    Assert-AnonymousAuthentication -Path "$siteName/SubFolder" -Enabled 'true'
}

function Test-ShouldDisableAnonymousAuthentication
{
    Set-IISAnonymousAuthentication -SiteName $siteName -Disabled
    Assert-AnonymousAuthentication -Enabled 'false'
}

function Test-ShouldSupportWhatIf
{
    Set-IISAnonymousAuthentication -SiteName $siteName 
    Assert-AnonymousAuthentication -Enabled 'true'
    Set-IISAnonymousAuthentication -SiteName $siteName -Disabled -WhatIf
    Assert-AnonymousAuthentication -Enabled 'true'
}

function Assert-AnonymousAuthentication($Path = $siteName, $Enabled)
{
    $authSettings = [xml] (Invoke-AppCmd list config $Path '-section:anonymousAuthentication')
    $authNode = $authSettings['system.webServer'].security.authentication.anonymousAuthentication
    Assert-Equal $Enabled $authNode.enabled
    Assert-Equal '' $authNode.username
}