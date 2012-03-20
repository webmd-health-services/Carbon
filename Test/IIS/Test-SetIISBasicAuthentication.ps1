
$siteName = 'Basic Authentication'
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

function Test-ShouldEnableBasicAuthentication
{
    Set-IISBasicAuthentication -SiteName $siteName
    Assert-BasicAuthentication -Enabled 'true'
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableBasicAuthenticationOnSubFolders
{
    Set-IISBasicAuthentication -SiteName $siteName -Path SubFolder
    Assert-BasicAuthentication -Path "$siteName/SubFolder" -Enabled 'true'
}

function Test-ShouldDisableBasicAuthentication
{
    Set-IISBasicAuthentication -SiteName $siteName -Disabled
    Assert-BasicAuthentication -Enabled 'false'
}

function Test-ShouldSupportWhatIf
{
    Set-IISBasicAuthentication -SiteName $siteName 
    Assert-BasicAuthentication -Enabled 'true'
    Set-IISBasicAuthentication -SiteName $siteName -Disabled -WhatIf
    Assert-BasicAuthentication -Enabled 'true'
}

function Assert-BasicAuthentication($Path = $siteName, $Enabled)
{
    $authSettings = [xml] (Invoke-AppCmd list config $Path '-section:basicAuthentication')
    $authNode = $authSettings['system.webServer'].security.authentication.basicAuthentication
    Assert-Equal $Enabled $authNode.enabled
}