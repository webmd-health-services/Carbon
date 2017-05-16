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

$appPoolName = 'Carbon-Set-IisWebsiteID'
$siteName = 'Carbon-Set-IisWebsiteID'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisAppPool -Name $appPoolName
    Install-IisWebsite -Name $siteName -Binding 'http/*:80:carbon-test-set-iiswebsiteid.com' -Path $TestDir -AppPoolName $appPoolName

}

function Stop-Test
{
    Remove-IisWebsite $siteName
}

function Test-ShouldChangeID
{
    $currentSite = Get-IisWebsite -SiteName $siteName
    Assert-NotNull $currentSite

    $newID = [int32](Get-Random -Maximum ([int32]::MaxValue) -Minimum 1)
    Set-IisWebsiteID -SiteName $siteName -ID $newID -ErrorAction SilentlyContinue

    $updatedSite = Get-IisWebsite -SiteName $siteName
    Assert-Equal $newID $updatedSite.ID
    Assert-Equal 'Started' $updatedSite.State
}

function Test-ShouldDetectDuplicateIDs
{
    $alreadyTakenSiteName = 'AlreadyGotIt'
    $alreadyTakenSiteID = 4571
    $alreadyTakenSite = Install-IisWebsite -Name $alreadyTakenSiteName `
                                           -PhysicalPath $PSScriptRoot `
                                           -Binding 'http/*:9983:' `
                                           -SiteID $alreadyTakenSiteID `
                                           -PassThru
    try
    {
        $currentSite = Get-IisWebsite -SiteName $siteName
        Assert-NotNull $siteName

        Assert-NotEqual $currentSite.ID $alreadyTakenSite.ID

        $Error.Clear()
        Set-IisWebsiteID -SiteName $siteName -ID $alreadyTakenSiteID -ErrorAction SilentlyContinue
        Assert-Equal 1 $Error.Count
        Assert-Like $Error[0].Exception.Message '*ID * already in use*'
    }
    finally
    {
        Uninstall-IisWebsite -Name $alreadyTakenSiteName
    }
}

function Test-ShouldHandleNonExistentWebsite
{
    $Error.Clear()
    Set-IisWebsiteID -SiteName 'HopefullyIDoNotExist' -ID 453879 -ErrorAction SilentlyContinue
    Assert-Equal 1 $Error.Count
    Assert-Like $Error[0].Exception.Message '*Website * not found*'
}

function Test-ShouldSupportWhatIf
{
    $currentSite = Get-IisWebsite -SiteName $siteName
    $newID = [int32](Get-Random -Maximum ([int32]::MaxValue) -Minimum 1)
    Set-IisWebsiteID -SiteName $siteName -ID $newID -WhatIf -ErrorAction SilentlyContinue
    $updatedsite = Get-IisWebsite -SiteName $siteName
    Assert-Equal $currentSite.ID $updatedsite.ID
}

function Test-ShouldSetSameIDOnSameWebsite
{
    $Error.Clear()
    $currentSite = Get-IisWebsite -SiteName $siteName
    Set-IisWebsiteID -SiteName $siteName -ID $currentSite.ID -ErrorAction SilentlyContinue
    Assert-Equal 0 $Error.Count
    $updatedSite = Get-IisWebsite -SiteName $siteName
    Assert-Equal $currentSite.ID $updatedSite.ID
    Assert-Equal 'Started' $updatedSite.State
}

