
$siteName = 'SslFlags'
$sitePort = 4389
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

function Test-ShouldResetSslFlags
{
    Set-IisSslFlags -SiteName $siteName
    Assert-SslFlags -ExpectedValue 'None'
}

function Test-ShouldRequireSsl
{
    Set-IISSSLFlags -SiteName $siteName -RequireSSL
    Assert-SSLFlags -ExpectedValue 'Ssl'
}

function Test-ShouldAcceptClientCertificates
{
    Set-IISSSLFlags -SiteName $siteName -AcceptClientCertificates
    Assert-SSLFlags -ExpectedValue 'SslNegotiateCert'
}

function Test-ShouldRequireClientCertificates
{
    Set-IISSSLFlags -SiteName $siteName -RequireClientCertificates
    Assert-SSLFlags -ExpectedValue 'Ssl, SslRequireCert'
}

function Test-ShouldAllow128BitSsl
{
    Set-IISSSLFlags -SiteName $siteName -Enable128BitSsl
    Assert-SSLFlags -ExpectedValue 'Ssl128'
}

function Test-ShouldSetAllFlags
{
    Set-IisSslFlags -SiteName $siteName -RequireSsl -AcceptClientCertificates -RequireClientCertificates -Enable128BitSsl
    Assert-SslFlags -ExpectedValue 'Ssl, SslNegotiatecert, SslRequireCert, Ssl128'
}

function Test-ShouldSupportWhatIf
{
    Set-IisSslFlags -SiteName $siteName -RequireSsl
    Assert-SslFlags -ExpectedValue 'Ssl'
    Set-IisSslFlags -SiteName $siteName -AcceptClientCertificates -WhatIf
    Assert-SslFlags -ExpectedValue 'Ssl'
}

function Test-ShouldSetFlagsOnSubFolder
{
    Set-IisSslFlags -SiteName $siteName -Path SubFolder -RequireSsl
    Assert-SslFlags -ExpectedValue 'Ssl' -Path "$SiteName/SubFolder"
    Assert-SslFlags -ExpectedValue 'None'
}

function Assert-SslFlags($ExpectedValue, $Path = $siteName)
{
    $authSettings = [xml] (Invoke-AppCmd list config $Path '-section:system.webServer/security/access')
    $sslFlags = $authSettings['system.webServer'].security.access.sslFlags
    Assert-Equal $ExpectedValue $sslFlags
}