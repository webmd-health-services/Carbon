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

$SiteName = 'TestNewWebsite'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-TestSite
    Grant-Permission -Identity Everyone -Permission ReadAndExecute -Path $TestDir
}

function Stop-Test
{
    Remove-TestSite
}

function Remove-TestSite
{
    if( Test-IisWebsite -Name $SiteName )
    {
        Uninstall-IisWebsite -Name $SiteName
        Assert-LastProcessSucceeded 'Unable to delete test site.'
    }
}

function Invoke-NewWebsite($Bindings = $null, $SiteID)
{
    $optionalParams = @{ }
    if( $PSBoundParameters.ContainsKey( 'SiteID' ) )
    {
        $optionalParams['SiteID'] = $SiteID
    }

    if( $PSBoundParameters.ContainsKey( 'Bindings' ) )
    {
        $optionalParams['Bindings'] = $Bindings
    }

    $site = Install-IisWebsite -Name $SiteName -Path $TestDir @optionalParams
    Assert-Null $site
    Assert-NoError
}

function Test-ShouldCreateWebsite
{
    Invoke-NewWebsite -SiteID 5478
    
    $details = Get-IisWebsite -Name $SiteName
    Assert-NotNull $details "Site '$siteName' not created."
    Assert-Like $details $SiteName 'Didn''t create site with given site name.'
    Assert-Equal 'http' $details.Bindings[0].Protocol
    Assert-Equal '*:80:' $details.Bindings[0].BindingInformation
    
    Assert-Equal $PSScriptRoot $details.PhysicalPath "Site not created with expected physical path."
    
    $anonymousAuthInfo = Get-IisSecurityAuthentication -Anonymous -SiteName $SiteName
    Assert-Empty $anonymousAuthInfo['userName'] "Anonymous authentication username not set to application pool's identity."

    $website = Get-IisWebsite -Name $SiteName
    Assert-NotNull $website
    Assert-Equal 5478 $website.Id
}

function Test-ShouldResolveRelativePath
{
    Install-IisWebsite -Name $SiteName -Path "$TestDir\..\..\Test\IIS"
    $site = Get-IisWebsite -SiteName $SiteName
    Assert-NotNull $site
    Assert-Equal $TestDir $site.PhysicalPath
}

function Test-ShouldCreateWebsiteWithCustomBinding
{
    Invoke-NewWebsite -Bindings 'http/*:9876:'
    Wait-ForWebsiteToBeRunning
    Assert-WebsiteRunning 9876
}

function Test-ShouldCreateWebsiteWithMultipleBindings
{
    Invoke-NewWebsite -Bindings 'http/*:9876:','http/*:9877:'
    Wait-ForWebsiteToBeRunning
    Assert-WebsiteRunning 9876
    Assert-WebsiteRunning 9877
}

function Test-ShouldAddSiteToCustomAppPool
{
    Install-IisAppPool -Name $SiteName
    
    try
    {
        Install-IisWebsite -Name $SiteName -Path $TestDir -AppPoolName $SiteName
        $appPool = Get-IisWebsite -Name $SiteName
        $appPool = $appPool.Applications[0].ApplicationPoolName
    }
    finally
    {
        Uninstall-IisAppPool $SiteName
    }
    
    Assert-Equal $SiteName $appPool "Site not assigned to correct app pool."
}

function Test-ShouldUpdateExistingSite
{
    Invoke-NewWebsite -Bindings 'http/*:9876:'
    Assert-NoError
    Assert-True (Test-IisWebsite -Name $SiteName)
    Install-IisVirtualDirectory -SiteName $SiteName -VirtualPath '/ShouldStillHangAround' -PhysicalPath $PSScriptRoot
    
    Invoke-NewWebsite
    Assert-NoError
    Assert-True (Test-IisWebsite -Name $SiteName)

    $website = Get-IisWebsite -Name $SiteName
    Assert-NotNull ($website.Applications[0].VirtualDirectories | Where-Object { $_.Path -eq '/ShouldStillHangAround' } ) 'Site deleted.'
}

function Test-ShouldCreateSiteDirectory
{
    $websitePath = Join-Path $TestDir ShouldCreateSiteDirectory
    if( Test-Path $websitePath -PathType Container )
    {
        $null = Remove-Item $websitePath -Force
    }
    
    try
    {
        Install-IisWebsite -Name $SiteName -Path $websitePath -Bindings 'http/*:9876:'
        Assert-DirectoryExists $websitePath 
    }
    finally
    {
        if( Test-Path $websitePath -PathType Container )
        {
            $null = Remove-Item $websitePath -Force
        }
    }
}

function Test-ShouldValidateBindings
{
    $error.Clear()
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'http/*' -ErrorAction SilentlyContinue
    Assert-True ($error.Count -ge 1)
    Assert-False (Test-IisWebsite -Name $SiteName)
    Assert-Error -Last 'bindings are invalid'
}

function Test-ShouldAllowUrlBindings
{
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'http://*:9876'
    Assert-True (Test-IisWebsite -Name $SiteName)
    Wait-ForWebsiteToBeRunning
    Assert-WebsiteRunning 9876
}

function Test-ShouldAllowHttpsBindings
{
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'https/*:9876:','https://*:9443'
    Assert-True (Test-IisWebsite -Name $SiteName)
    $bindings = Get-IisWebsite -SiteName $SiteName | Select-Object -ExpandProperty Bindings
    Assert-Equal 'https' $bindings[0].Protocol
    Assert-Equal 'https' $bindings[1].Protocol
}

function Test-ShouldNotRecreateExistingWebsite
{
    Install-IisWebsite -Name $SiteName -PhysicalPath $TestDir -Bindings 'http/*:9876:'
    $website = Get-IisWebsite -Name $SiteName
    Assert-NotNull $website

    Install-IisWebsite -Name $SiteName -PhysicalPath $TestDir -Bindings 'http/*:9876:'
    Assert-NoError
    $newWebsite = Get-IisWebsite -Name $SiteName
    Assert-NotNull $newWebsite
    Assert-Equal $website.Id $newWebsite.Id
}

function Test-ShouldChangeWebsiteSettings
{
    $appPool = Install-IisAppPool -Name 'CarbonShouldChangeWebsiteSettings' -PassThru
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    
    try
    {
        Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot
        Assert-NoError
        $website = Get-IisWebsite -Name $SiteName
        Assert-NotNull $website
        Assert-Equal $SiteName $website.Name
        Assert-Equal $PSScriptRoot $website.PhysicalPath

        Install-IisWebsite -Name $SiteName -PhysicalPath $tempDir -Bindings 'http/*:9986:' -SiteID 9986 -AppPoolName $appPool.Name
        Assert-NoError
        $website = Get-IisWebsite -Name $SiteName
        Assert-NotNull $website
        Assert-Equal $SiteName $website.Name
        Assert-Equal $tempDir.FullName $website.PhysicalPath
        Assert-Equal 9986 $website.Id
        Assert-Equal $appPool.Name $website.Applications[0].ApplicationPoolName
        Assert-WebsiteBinding '[http] *:9986:' 
    }
    finally
    {
        Uninstall-IisAppPool -Name $appPool.Name
        Remove-Item -Path $tempDir -Recurse
    }
}

function Test-ShouldUpdateBindings
{
    $output = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot
    Assert-Null $output

    Install-IisWebsite -Name $SiteName -Bindings 'http/*:8001:' -PhysicalPath $PSScriptRoot
    Assert-WebsiteBinding '[http] *:8001:'
    Install-IisWebsite -Name $SiteName -Bindings 'http/*:8001:','http/*:8002:' -PhysicalPath $PSScriptRoot
    Assert-WebsiteBinding '[http] *:8001:', '[http] *:8002:'
    Install-IisWebsite -Name $SiteName -Bindings 'http/*:8002:' -PhysicalPath $PSScriptRoot
    Assert-WebsiteBinding '[http] *:8002:'
    Install-IisWebsite -Name $SiteName -Bindings 'http/*:8003:' -PhysicalPath $PSScriptRoot
    Assert-WebsiteBinding '[http] *:8003:'
}

function Test-ShouldReturnSiteObject
{
    $site = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot -PassThru
    Assert-NotNull $site
    Assert-Is $site ([Microsoft.Web.Administration.Site])
    Assert-Equal $SiteName $site.Name
    Assert-Equal $PSScriptRoot $site.PhysicalPath

    $site = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot 
    Assert-Null $site
}

function Test-ShouldForceDeleteAndRecreate
{
    $output = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot -Binding 'http/*:9891:'
    Assert-Null $output

    Set-IisHttpHeader -SiteName $SiteName -Name 'X-Carbon-Test' -Value 'Test-ShouldFoceDeleteAndRecreate'

    $output = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot -Binding 'http/*:9891:' -Force
    Assert-Null $output
    Assert-Null (Get-IisHttpHeader -SiteName $SiteName -Name 'X-Carbon-Test')
}

function Assert-WebsiteBinding
{
    param(
        [string[]]
        $Binding
    )

    $website = Get-IisWebsite -Name $SiteName
    [string[]]$actualBindings = $website.Bindings | ForEach-Object { $_.ToString() }
    Assert-Equal $Binding.Count $actualBindings.Count
    foreach( $item in $Binding )
    {
        Assert-True ($actualBindings -contains $item) ('{0} not in @( "{1}" )' -f $item,($actualBindings -join '", "'))
    }
}

function Assert-WebsiteRunning($port)
{
    $browser = New-Object Net.WebClient
    $html = $browser.downloadString( "http://localhost:$port/NewWebsite.html" )
    Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new website.'   
}

function Wait-ForWebsiteToBeRunning
{
    $website = Get-IisWebsite -Name $SiteName
    $website.Start()
    $state = ''
    $tryNum = 0
    do
    {
        $tryNum += 1
        $website = Get-IisWebsite -SiteName $SiteName
        if( $website.State -eq 'Started' )
        {
            break
        }
        
        Start-Sleep -Milliseconds 100
        
    } while( $tryNum -lt 100 )
    
    Assert-Equal 'Started' $website.State "Website $SiteName never started running."
}

