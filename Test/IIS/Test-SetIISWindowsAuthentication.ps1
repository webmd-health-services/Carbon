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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-IisWebsite $siteName
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort"
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function Stop-Test
{
    Uninstall-IisWebsite $siteName
}

function Test-ShouldEnableWindowsAuthentication
{
    Set-IisWindowsAuthentication -SiteName $siteName
    Assert-WindowsAuthentication -KernelMode $true
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableKernelMode
{
    Set-IisWindowsAuthentication -SiteName $siteName
    Assert-WindowsAuthentication -KernelMode $true
}

function Test-SetWindowsAuthenticationOnSubFolders
{
    Set-IisWindowsAuthentication -SiteName $siteName -Path SubFolder
    Assert-WindowsAuthentication -Path SubFolder -KernelMode $true
}

function Test-ShouldDisableKernelMode
{
    Set-IisWindowsAuthentication -SiteName $siteName -DisableKernelMode
    Assert-WindowsAuthentication -KernelMode $false
}

function Test-ShouldSupportWhatIf
{
    Set-IisWindowsAuthentication -SiteName $siteName 
    Assert-WindowsAuthentication -KernelMode $true
    Set-IisWindowsAuthentication -SiteName $siteName -WhatIf -DisableKernelMode
    Assert-WindowsAuthentication -KernelMode $true
}

function Assert-WindowsAuthentication($Path = '', [Boolean]$KernelMode)
{
    $authSettings = Get-IisSecurityAuthentication -SiteName $SiteName -Path $Path -Windows
    Assert-Equal ($authSettings.GetAttributeValue( 'useKernelMode' )) $KernelMode
}

