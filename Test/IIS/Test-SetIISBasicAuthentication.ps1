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
