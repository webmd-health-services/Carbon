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

$Port = 9879
$SiteName = 'TestEnableIisDirectoryBrowsing'
$VDirName = 'VDir'
$WebConfig = Join-Path $TestDir web.config

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)

    Install-IisAppPool -Name $SiteName
}

function Stop-TestFixture
{
    Uninstall-IisAppPool -Name $SiteName
}

function Start-Test
{
    Stop-Test
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port" -AppPoolName $SiteName
    if( Test-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function Stop-Test
{
    Uninstall-IisWebsite -Name $SiteName
}

function Test-ShouldEnableDirectoryBrowsing
{
    Enable-IisDirectoryBrowsing -SiteName $SiteName
    Assert-DirectoryBrowsingEnabled
}

function Test-ShouldTurnOnDirectoryBrowsingUnderVirtualDirectory
{
    Install-IisVirtualDirectory -SiteName $SiteName -Name $VDirName -Path $PSScriptRoot
    Enable-IisDirectoryBrowsing -SiteName $SiteName -Path $VDirName

    Assert-FileDoesNotExist $WebConfig 'Changes not committed to apphost config level.'
    Assert-DirectoryBrowsingEnabled -VirtualPath $VDirName
}

function Assert-DirectoryBrowsingEnabled
{
    param(
        $VirtualPath
    )

    Set-StrictMode -Version 'Latest'


    $url = "http://localhost:$Port/"
    if( $VirtualPath )
    {
        $url = '{0}{1}' -f $url,$VirtualPath
    }

    $section = Get-IisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/directoryBrowse' @PSBoundParameters
    Assert-Equal 'true' $section['enabled']

    $numTries = 0
    $maxTries = 10
    $foundDirectoryListing = $false
    do
    {
        $output = Read-Url $Url 
        if( $output -like '*NewWebsite.html*' )
        {
            $foundDirectoryListing = $true
            break
        }
        $numTries += 1
        Start-Sleep -Milliseconds 100
    }
    while( $numTries -lt $maxTries )
    Assert-True $foundDirectoryListing "Didn't get directory list."
}

function Read-Url($Url)
{
    $browser = New-Object Net.WebClient
    $numTries = 0
    $maxTries = 10
    do
    {
        try
        {
            return $browser.downloadString( $Url )
        }
        catch
        {
            Write-Verbose "Error downloading '$Url': $_"
            $numTries++
            Start-Sleep -Milliseconds 100
        }
    }
    while( $numTries -lt $maxTries )
}

