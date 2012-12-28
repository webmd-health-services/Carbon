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

Import-Module (Join-Path $TestDir ..\..\Carbon) -Force

$Port = 9878
$SiteName = 'TestApplication'
$AppName = 'App'
$WebConfig = Join-Path $TestDir web.config
$AppPoolName = 'TestApplication'

function SetUp
{
    Uninstall-IisWebsite -Name $SiteName
    Install-IisAppPool -Name $AppPoolName
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port"
    if( TEst-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function TearDown
{
    Uninstall-IisWebsite -Name $SiteName
}

function Invoke-InstallApplication($Path = $TestDir)
{
    Install-IISApplication -SiteName $SiteName -Name $AppName -Path $Path -AppPoolName $AppPoolName
    Assert-LastProcessSucceeded 'Failed to create virtual directory.'
    Assert-FileDoesNotExist $WebConfig
}

function Test-ShouldCreateApplication
{
    Invoke-InstallApplication
    Assert-ApplicationRunning
    $output = Invoke-AppCmd list app "$SiteName/$AppName"
    Assert-Like $output "APP ""$SiteName/$AppName"" (applicationPool:$AppPoolName)"
}

function Test-ShouldDeleteExistingApplication
{
    Invoke-InstallApplication -Path $env:SystemRoot
    Invoke-InstallApplication
    Assert-ApplicationRunning
}

function Test-ShouldAllowOptionalAppPoolName
{
    Install-IISApplication -SiteName $SiteName -Name $AppName -Path $TestDir
    Assert-ApplicationRunning
    $output = Invoke-AppCmd list app "$SiteName/$AppName"
    Assert-Equal "APP ""$SiteName/$AppName"" (applicationPool:DefaultAppPool)" $output
}

function Test-ShouldCreateApplicationDirectory
{
    $appDir = Join-Path $TestDir ApplicationDirectory
    if( Test-Path $appDir -PathType Container )
    {
        Remove-Item $appDir -Force
    }

    try
    {
        Invoke-InstallApplication -Path $appDir
        Assert-DirectoryExists $appDir
    }
    finally
    {
        if( Test-Path $appDir -PathType Container )
        {
            Remove-Item $appDir -Force
        }
    }
}

function Assert-ApplicationRunning($appName)
{
    $html = Read-Url "http://localhost:$Port/$vdir/NewWebsite.html"
    Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new application.'   
}

function Read-Url($Url)
{
    $browser = New-Object Net.WebClient
    $numTries = 0
    $maxTries = 5
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
