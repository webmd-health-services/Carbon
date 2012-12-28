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

$Port = 9878
$SiteName = 'TestVirtualDirectory'
$VDirName = 'VDir'
$WebConfig = Join-Path $TestDir web.config

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)

    Uninstall-IisWebsite -Name $SiteName
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port"
    if( Test-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function TearDown
{
    Uninstall-IisWebsite -Name $SiteName
    Remove-Module Carbon
}

function Invoke-NewVirtualDirectory($Path = $TestDir)
{
    Install-IisVirtualDirectory -SiteName $SiteName -Name $VDirName -Path $Path
    Assert-LastProcessSucceeded 'Failed to create virtual directory.'
}

function Test-ShouldCreateVirtualDirectory
{
    Invoke-NewVirtualDirectory
    Assert-VirtualDirectoryRunning
}

function Test-ShouldDeleteExistingVirtualDirectory
{
    Invoke-NewVirtualDirectory -Path $env:SystemRoot
    Invoke-NewVirtualDirectory
    Assert-VirtualDirectoryRunning
}

function Test-ShouldTurnOnDirectoryBrowsing
{
    Invoke-NewVirtualDirectory
    Enable-IisDirectoryBrowsing -SiteName $SiteName -Path $VDirName
    Assert-LastProcessSucceeded 'Failed to enable directory browsing.'
    Assert-FileDoesNotExist $WebConfig 'Changes not committed to apphost config level.'
    $numTries = 0
    $maxTries = 10
    $foundDirectoryListing = $false
    do
    {
        $output = Read-Url "http://localhost:$Port/$VDirName"
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

function Assert-VirtualDirectoryRunning($vdir)
{
    $html = Read-Url "http://localhost:$Port/$vdir/NewWebsite.html"
    Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new virtual directory.'   
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
