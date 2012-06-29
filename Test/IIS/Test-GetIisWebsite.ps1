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

$appPoolName = 'Carbon-Get-IisWebsite'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    Install-IisAppPool -Name $appPoolName
}

function TearDown
{
    Remove-Module Carbon
    #Remove-IisAppPool -Name $appPoolName
}

function Test-ShouldReturnNullForNonExistentWebsite
{
    $website = Get-IisWebsite -SiteName 'ISureHopeIDoNotExist'
    Assert-Null $website
}

function Test-ShouldGetWebsiteDetails
{
    $siteName = 'Carbon-Get-IisWebsite'
    $bindings = @( 'http/*:8401:', 'https/*:8401:', 'http/1.2.3.4:80:', "http/5.6.7.8:80:$siteName" )
    Install-IisWebsite -Name $siteName -Bindings $bindings -Path $TestDir -AppPoolName $appPoolName
    
    $website = Get-IisWebsite -SiteName $siteName
    Assert-NotNull $website
    Assert-Equal $siteName $website.Name 'site name not set'
    Assert-True ($website.ID -gt 0) 'site ID not set'
    Assert-Equal 4 $website.Bindings.Length 'site bindings not set'
    Assert-Equal 'http' $website.Bindings[0].Protocol 
    Assert-Equal '*' $website.Bindings[0].IPAddress
    Assert-Equal 8401 $website.Bindings[0].Port
    Assert-Empty $website.Bindings[0].HostName
    
    Assert-Equal 'https' $website.Bindings[1].Protocol 
    Assert-Equal '*' $website.Bindings[1].IPAddress
    Assert-Equal 8401 $website.Bindings[1].Port
    Assert-Empty $website.Bindings[1].HostName
    
    Assert-Equal 'http' $website.Bindings[2].Protocol 
    Assert-Equal '1.2.3.4' $website.Bindings[2].IPAddress
    Assert-Equal 80 $website.Bindings[2].Port
    Assert-Empty $website.Bindings[2].HostName
    
    Assert-Equal 'http' $website.Bindings[3].Protocol 
    Assert-Equal '5.6.7.8' $website.Bindings[3].IPAddress
    Assert-Equal 80 $website.Bindings[3].Port
    Assert-Equal $siteName $website.Bindings[3].HostName "bindings[3] host name"
     
}
