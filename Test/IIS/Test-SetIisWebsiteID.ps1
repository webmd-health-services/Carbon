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

$appPoolName = 'Carbon-Set-IisWebsiteID'
$siteName = 'Carbon-Set-IisWebsiteID'

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    Install-IisAppPool -Name $appPoolName
    Install-IisWebsite -Name $siteName -Binding 'http/*:80:carbon-test-set-iiswebsiteid.com' -Path $TestDir -AppPoolName $appPoolName

}

function TearDown
{
    Remove-IisWebsite $siteName
}

function Test-ShouldChangeID
{
    $currentSite = Get-IisWebsite -SiteName $siteName
    Assert-NotNull $currentSite

    $newID = $currentSite.ID * 3571
    Set-IisWebsiteID -SiteName $siteName -ID $newID

    $updatedSite = Get-IisWebsite -SiteName $siteName
    Assert-Equal $newID $updatedSite.ID
    Assert-Equal 'Started' $updatedSite.State
}

function Test-ShouldDetectDuplicateIDs
{
    $originalSite = Get-IisWebsite | Select-Object -First 1
    Assert-NotNull $originalSite
    Assert-NotEqual $siteName $originalSite.Name

    $currentSite = Get-IisWebsite -SiteName $siteName
    Assert-NotNull $siteName

    Assert-NotEqual $currentSite.ID $originalSite.ID

    $Error.Clear()
    Set-IisWebsiteID -SiteName $siteName -ID $originalSite.ID -ErrorAction SilentlyContinue
    Assert-Equal 1 $Error.Count
    Assert-Like $Error[0].Exception.Message '*ID * already in use*'
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
    Set-IisWebsiteID -SiteName $siteName -ID ($currentSite.ID * 3571) -WhatIf
    $updatedsite = Get-IisWebsite -SiteName $siteName
    Assert-Equal $currentSite.ID $updatedsite.ID
}

function Test-ShouldSetSameIDOnSameWebsite
{
    $Error.Clear()
    $currentSite = Get-IisWebsite -SiteName $siteName
    Set-IisWebsiteID -SiteName $siteName -ID $currentSite.ID
    Assert-Equal 0 $Error.Count
    $updatedSite = Get-IisWebsite -SiteName $siteName
    Assert-Equal $currentSite.ID $updatedSite.ID
    Assert-Equal 'Started' $updatedSite.State
}
