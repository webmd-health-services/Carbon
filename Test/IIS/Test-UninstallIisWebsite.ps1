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


$SiteName = 'TestSite'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-TestWebsite
}

function Stop-Test
{
    Remove-TestWebsite
}

function Remove-TestWebsite
{
    if( Test-IisWebsite -Name $SiteName )
    {
        Uninstall-IisWebsite -Name $SiteName
        Assert-LastProcessSucceeded 'Unable to delete test site.'
    }
}

function Invoke-RemoveWebsite($Name = $SiteName)
{
    Uninstall-IisWebsite $Name
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
    Assert-False (Test-IisWebsite -Name $Name) "Website $Name exists!"
}

