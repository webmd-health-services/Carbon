# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    Enable-IisSsl -SiteName $siteName
    Assert-SslFlags -ExpectedValue 'None'
}

function Test-ShouldRequireSsl
{
    Enable-IisSsl -SiteName $siteName -RequireSSL
    Assert-SSLFlags -ExpectedValue 'Ssl'
}

function Test-ShouldAcceptClientCertificates
{
    Enable-IisSsl -SiteName $siteName -AcceptClientCertificates
    Assert-SSLFlags -ExpectedValue 'SslNegotiateCert'
}

function Test-ShouldRequireClientCertificates
{
    Enable-IisSsl -SiteName $siteName -RequireSsl -RequireClientCertificates
    Assert-SSLFlags -ExpectedValue 'Ssl, SslRequireCert'
}

function Test-ShouldAllow128BitSsl
{
    Enable-IisSsl -SiteName $siteName -Require128BitSsl
    Assert-SSLFlags -ExpectedValue 'Ssl128'
}

function Test-ShouldSetAllFlags
{
    Enable-IisSsl -SiteName $siteName -RequireSsl -AcceptClientCertificates -Require128BitSsl
    Assert-SslFlags -ExpectedValue 'Ssl, SslNegotiatecert, Ssl128'
}

function Test-ShouldSupportWhatIf
{
    Enable-IisSsl -SiteName $siteName -RequireSsl
    Assert-SslFlags -ExpectedValue 'Ssl'
    Enable-IisSsl -SiteName $siteName -AcceptClientCertificates -WhatIf
    Assert-SslFlags -ExpectedValue 'Ssl'
}

function Test-ShouldSetFlagsOnSubFolder
{
    Enable-IisSsl -SiteName $siteName -Path SubFolder -RequireSsl
    Assert-SslFlags -ExpectedValue 'Ssl' -Path "$SiteName/SubFolder"
    Assert-SslFlags -ExpectedValue 'None'
}

function Assert-SslFlags($ExpectedValue, $Path = $siteName)
{
    $authSettings = [xml] (Invoke-AppCmd list config $Path '-section:system.webServer/security/access')
    $sslFlags = $authSettings['system.webServer'].security.access.sslFlags
    Assert-Equal $ExpectedValue $sslFlags
}
