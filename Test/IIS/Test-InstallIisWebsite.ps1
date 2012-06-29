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


$SiteName = 'TestNewWebsite'

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    Remove-TestSite
    Grant-Permissions -Identity Everyone -Permissions ReadAndExecute -Path $TestDir
}

function TearDown
{
    Remove-TestSite
    Remove-Module Carbon
}

function Remove-TestSite
{
    if( Test-IisWebsiteExists -Name $SiteName )
    {
        Remove-IisWebsite -Name $SiteName
        Assert-LastProcessSucceeded 'Unable to delete test site.'
    }
}

function Invoke-NewWebsite($Bindings = $null)
{
    if( $Bindings -eq $null )
    {
        Install-IisWebsite -Name $SiteName -Path $TestDir
    }
    else
    {
        Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings $Bindings
    }
    Assert-LastProcessSucceeded 'Test site not created'
    
}

function Test-ShouldCreateWebsite
{
    Invoke-NewWebsite
    
    $details = Invoke-AppCmd list site $SiteName
    Assert-NotEmpty $details "Site '$siteName' not created."
    Assert-Like $details $SiteName 'Didn''t create site with given site name.'
    Assert-Like $details 'bindings:http/*:80' 'Didn''t default to binding on port 80.'
    
    $details = Invoke-AppCmd list vdirs /app.name:"$SiteName/"
    Assert-Equal $details "VDIR ""$SiteName/"" (physicalPath:$TestDir)" "Site not created with expected physical path."
    
    $authXml = [xml] (Invoke-AppCmd list config $SiteName /section:anonymousAuthentication)
    $username = $authXml['system.webServer'].security.authentication.anonymousAuthentication.userName
    Assert-Empty $username "Anonymous authentication username not set to application pool's identity."
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
        $appPool = Invoke-AppCmd list site $SiteName /text:[path=`'/`'].applicationPool
    }
    finally
    {
        Invoke-AppCmd delete apppool `"$SiteName`"
    }
    
    Assert-Equal $SiteName $appPool "Site not assigned to correct app pool."
}

function Test-ShouldRemoveExistingSite
{
    Invoke-NewWebsite -Bindings 'http/*:9876:'
    $output = Invoke-AppCmd list site `"$SiteName`"
    Assert-Match $output 'http/\*:9876' "Custom binding not set."
    
    Invoke-NewWebsite
    $output = Invoke-AppCmd list site `"$SiteName`"
    Assert-Match $output 'http/\*:80' 'Site not replaced.'
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
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'http/*:80' -ErrorAction SilentlyContinue
    Assert-True ($error.Count -ge 1)
    Assert-False (Test-IisWebsiteExists -Name $SiteName)
    Assert-True $error[0].Exception.Message -like '*bindings are invalid*'
}

function Test-ShouldAllowUrlBindings
{
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'http://*:9876'
    Assert-True (Test-IisWebsiteExists -Name $SiteName)
    Assert-WebsiteRunning 9876
}

function Test-ShouldAllowHttpsBindings
{
    Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'https/*:9876:','https://*:9443'
    Assert-True (Test-IisWebsiteExists -Name $SiteName)
    $bindings = Get-IisWebsite -SiteName $SiteName | Select-Object -ExpandProperty Bindings
    Assert-Equal 'https' $bindings[0].Protocol
    Assert-Equal 'https' $bindings[1].Protocol
}

function Assert-WebsiteRunning($port)
{
    $browser = New-Object Net.WebClient
    $html = $browser.downloadString( "http://localhost:$port/NewWebsite.html" )
    Assert-Like $html 'NewWebsite Test Page' 'Unable to download from new website.'   
}

function Wait-ForWebsiteToBeRunning
{
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
