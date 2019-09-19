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

$Port = 9877
$WebConfig = Join-Path $TestDir web.config
$SiteName = 'CarbonSetIisHttpRedirect'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port"
    if( Test-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function Stop-Test
{
    Uninstall-IisWebsite -Name $SiteName
}

function Test-ShouldRedirectSite
{
    Set-IisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com' 
    Assert-Redirects
    Assert-FileDoesNotExist $webConfig # make sure committed to applicationHost.config
    $settings = Get-IisHttpRedirect -SiteName $SiteName
    Assert-True $settings.Enabled
    Assert-Equal 'http://www.example.com' $settings.Destination
    Assert-False $settings.ExactDestination
    Assert-False $settings.ChildOnly
    Assert-Equal Found $settings.HttpResponseStatus
}

function Test-ShouldSetREdirectCustomizations
{
    Set-IisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com' -HttpResponseStatus 'Permanent' -ExactDestination -ChildOnly
    Assert-Redirects
    $settings = Get-IisHttpRedirect -SiteName $SiteName
    Assert-Equal 'http://www.example.com' $settings.Destination
    Assert-Equal 'Permanent' $settings.HttpResponseStatus
    Assert-True $settings.ExactDestination
    Assert-True $settings.ChildOnly
}

function Test-ShouldSetToDefaultValues
{
    Set-IisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com' -HttpResponseStatus 'Permanent' -ExactDestination -ChildOnly
    Assert-Redirects
    Set-IisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com'
    Assert-Redirects

    $settings = Get-IisHttpRedirect -SiteName $SiteName
    Assert-Equal 'http://www.example.com' $settings.Destination
    Assert-Equal 'Found' $settings.HttpResponseStatus
    Assert-False $settings.ExactDestination 'exact destination not reverted'
    Assert-False $settings.ChildOnly 'child only not reverted'
}

function Test-ShouldSetRedirectOnPath
{
    Set-IisHttpRedirect -SiteName $SiteName -Path SubFolder -Destination 'http://www.example.com'
    Assert-Redirects -Path Subfolder
    $content = Read-Url -Path 'NewWebsite.html'
    Assert-True ($content -match 'NewWebsite') 'Redirected root page'
    
    $settings = Get-IisHttpREdirect -SiteName $SiteName -Path SubFolder
    Assert-True $settings.Enabled
    Assert-Equal 'http://www.example.com' $settings.Destination
}

function Read-Url($Path = '')
{
    $browser = New-Object Net.WebClient
    return $browser.downloadString( "http://localhost:$Port/$Path" )
}

function Assert-Redirects($Path = '')
{
    $numTries = 0
    $maxTries = 5
    $content = ''
    do
    {
        try
        {
            $content = Read-Url $Path
            if( $content -match 'Example Domain' )
            {
                break
            }
        }
        catch
        {
            Write-Verbose "Error downloading '$Path': $_"
        }
        $numTries++
        Start-Sleep -Milliseconds 100
    }
    while( $numTries -lt $maxTries )
}

