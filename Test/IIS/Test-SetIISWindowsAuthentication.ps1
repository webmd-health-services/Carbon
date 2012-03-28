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

$siteName = 'Windows Authentication'
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

function Test-ShouldEnableWindowsAuthentication
{
    Set-IISWindowsAuthentication -SiteName $siteName
    Assert-WindowsAuthentication -Enabled 'true'
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableKernelMode
{
    Set-IISWindowsAuthentication -SiteName $siteName -UseKernelMode
    Assert-WindowsAuthentication -Enabled 'true' -UseKernelMode 'true'
}

function Test-ShouldEnableWindowsAuthenticationOnSubFolders
{
    Set-IISWindowsAuthentication -SiteName $siteName -Path SubFolder
    Assert-WindowsAuthentication -Path "$siteName/SubFolder" -Enabled 'true'
}

function Test-ShouldDisableWindowsAuthentication
{
    Set-IISWindowsAuthentication -SiteName $siteName -Disabled
    Assert-WindowsAuthentication -Enabled 'false'
}

function Test-ShouldSupportWhatIf
{
    Set-IISWindowsAuthentication -SiteName $siteName 
    Assert-WindowsAuthentication -Enabled 'true'
    Set-IISWindowsAuthentication -SiteName $siteName -Disabled -WhatIf
    Assert-WindowsAuthentication -Enabled 'true'
}

function Assert-WindowsAuthentication($Path = $siteName, $Enabled, $UseKernelMode = 'false')
{
    $authSettings = [xml] (Invoke-AppCmd list config $Path '-section:windowsAuthentication')
    $authNode = $authSettings['system.webServer'].security.authentication.windowsAuthentication
    Assert-Equal $Enabled $authNode.enabled
    Assert-Equal $UseKernelMode $authNode.useKernelMode
}
