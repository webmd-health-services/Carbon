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
$siteName = 'Carbon-Get-IisWebsite'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisAppPool -Name $appPoolName
    $bindings = @( 'http/*:8401:', 'https/*:8401:', 'http/1.2.3.4:80:', "http/5.6.7.8:80:$siteName" )
    Install-IisWebsite -Name $siteName -Bindings $bindings -Path $TestDir -AppPoolName $appPoolName
}

function Stop-Test
{
    Remove-IisWebsite -Name $siteName
}

function Test-ShouldReturnNullForNonExistentWebsite
{
    $website = Get-IisWebsite -SiteName 'ISureHopeIDoNotExist'
    Assert-Null $website
}

function Test-ShouldGetWebsiteDetails
{   
    $website = Get-IisWebsite -SiteName $siteName
    Assert-NotNull $website
    Assert-Equal $siteName $website.Name 'site name not set'
    Assert-True ($website.ID -gt 0) 'site ID not set'
    Assert-Equal 4 $website.Bindings.Count 'site bindings not set'
    Assert-Equal 'http' $website.Bindings[0].Protocol 
    Assert-Equal '0.0.0.0' $website.Bindings[0].Endpoint.Address
    Assert-Equal 8401 $website.Bindings[0].Endpoint.Port
    Assert-Empty $website.Bindings[0].Host
    
    Assert-Equal 'https' $website.Bindings[1].Protocol 
    Assert-Equal '0.0.0.0' $website.Bindings[1].Endpoint.Address
    Assert-Equal 8401 $website.Bindings[1].Endpoint.Port
    Assert-Empty $website.Bindings[1].Host
    
    Assert-Equal 'http' $website.Bindings[2].Protocol 
    Assert-Equal '1.2.3.4' $website.Bindings[2].Endpoint.Address
    Assert-Equal 80 $website.Bindings[2].Endpoint.Port
    Assert-Empty $website.Bindings[2].Host
    
    Assert-Equal 'http' $website.Bindings[3].Protocol 
    Assert-Equal '5.6.7.8' $website.Bindings[3].Endpoint.Address
    Assert-Equal 80 $website.Bindings[3].Endpoint.Port
    Assert-Equal $siteName $website.Bindings[3].Host "bindings[3] host name"

    $physicalPath = $website.Applications |
                        Where-Object { $_.Path -eq '/' } |
                        Select-Object -ExpandProperty VirtualDirectories |
                        Where-Object { $_.Path -eq '/' } |
                        Select-Object -ExpandProperty PhysicalPath
    Assert-Equal $physicalPath $website.PhysicalPath

    Assert-ServerManagerMember -Website $website
}

function Test-ShouldGetAllWebsites
{
    $foundAtLeastOne = $false
    $foundTestWebsite = $false
    Get-IisWebsite | ForEach-Object { 
        $foundAtLeastOne = $true

        Assert-ServerManagerMember -Website $_

        if( $_.Name -eq $siteName )
        {
            $foundTestWebsite = $true
        }
    }

    Assert-True $foundAtLeastOne
    Assert-True $foundTestWebsite
}

function Assert-ServerManagerMember
{
    param(
        $Website
    )
    Assert-NotNull ($Website.ServerManager) 'no server manager property'
    Assert-NotNull ($Website | Get-Member | Where-Object { $_.Name -eq 'CommitChanges' -and $_.MemberType -eq 'ScriptMethod' }) 'no CommitChanges method'
}

