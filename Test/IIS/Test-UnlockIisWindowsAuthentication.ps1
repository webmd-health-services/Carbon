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

$siteName = 'UnlockWindowsAuthentication'
$windowsAuthWasLocked = $false

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    Install-IisWebsite -Name $siteName -Path $TestDir
    $windowsAuthWasLocked = -not (Get-WindowsAuthenticationUnlocked)
    Invoke-AppCmd lock config /section:windowsAuthentication
    
}

function TearDown
{
    # Put things back the way we found them.
    if( $windowsAuthWasLocked )
    {
        Invoke-AppCmd lock config /section:windowsAuthentication
    }
    
    $webConfigPath = Join-Path $TestDir web.config
    if( Test-Path -Path $webConfigPath )
    {
        Remove-Item $webConfigPath
    }
    
    Remove-IisWebsite $siteName
    Remove-Module Carbon
}

function Test-ShouldUnlockConfigSection
{
    Unlock-IisWindowsAuthentication
    Assert-True (Get-WindowsAuthenticationUnlocked)
}

function Test-ShouldSupportWhatIf
{
    Unlock-IisWindowsAuthentication -WhatIf
    Assert-False (Get-WindowsAuthenticationUnlocked)
}

function Get-WindowsAuthenticationUnlocked
{
    $result = Invoke-AppCmd set config $SiteName /section:windowsAuthentication /enabled:true -ErrorAction SilentlyContinue
    return ( $LastExitCode -eq 0 )
}
