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

$siteName = 'UnlockIisConfigSection'
$windowsAuthWasLocked = $false
$windowsAuthConfigPath = 'system.webServer/security/authentication/windowsAuthentication'
$cgiConfigPath = 'system.webServer/cgi'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $windowsAuthWasLocked = Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked
    Lock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    Assert-True (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)

    $cgiWasLocked = Test-IisConfigurationSection -SectionPath $cgiConfigPath -Locked
    Lock-IisConfigurationSection -SectionPath $cgiConfigPath
    Assert-True (Test-IisConfigurationSection -SectionPath $cgiConfigPath -Locked)
}

function Stop-Test
{
    # Put things back the way we found them.
    if( $windowsAuthWasLocked )
    {
        Lock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    }
    else
    {
        Unlock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    }
    
    if( $cgiWasLocked )
    {
        Lock-IisConfigurationSection -SectionPath $cgiConfigPath
    }
    else
    {
        Unlock-IisConfigurationSection -SectionPath $cgiConfigPath
    }
    
    $webConfigPath = Join-Path $TestDir web.config
    if( Test-Path -Path $webConfigPath )
    {
        Remove-Item $webConfigPath
    }
}

function Test-ShouldUnlockOneConfigurationSection
{
    Unlock-IisConfigurationSection -SectionPath $windowsAuthConfigPath
    Assert-False (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
}

function Test-ShouldUnlockMultipleConfigurationSection
{
    Unlock-IisConfigurationSection -SectionPath $windowsAuthConfigPath,$cgiConfigPath
    Assert-False (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
    Assert-False (Test-IisConfigurationSection -SectionPath $cgiConfigPath -Locked)
}

function Test-ShouldSupportWhatIf
{
    Assert-True (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
    Unlock-IisConfigurationSection -SectionPath $windowsAuthConfigPath -WhatIf
    Assert-True (Test-IisConfigurationSection -SectionPath $windowsAuthConfigPath -Locked)
}

