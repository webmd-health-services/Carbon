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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-WebsiteBinding
{
    param(
        [string[]]
        $Binding
    )

    $website = Get-IisWebsite -Name $SiteName
    [string[]]$actualBindings = $website.Bindings | ForEach-Object { $_.ToString() }
    $actualBindings.Count | Should -Be $Binding.Count
    foreach( $item in $Binding )
    {
        ($actualBindings -contains $item) | Should -BeTrue
    }
}

function Assert-WebsiteRunning($port)
{
    $browser = New-Object Net.WebClient
    $html = $browser.downloadString( "http://localhost:$port/NewWebsite.html" )
    $html | Should -BeLike '*NewWebsite Test Page*' 
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

    'NewWebsite Test Page' | Set-Content -Path (Join-Path -Path $TestDir -ChildPath 'NewWebsite.html')
    $site = Install-IisWebsite -Name $SiteName -Path $TestDir @optionalParams
    $site | Should -BeNullOrEmpty
    $Global:Error.Count | Should -Be 0
}

function Remove-TestSite
{
    while( $true )
    {
        Uninstall-IisWebsite -Name $SiteName
        if( -not (Test-IisWebsite -Name $SiteName) )
        {
            break
        }

        Write-Warning -Message ('Waiting for website to get uninstalled.')
        Start-Sleep -Milliseconds 100
    }
}

function Wait-ForWebsiteToBeRunning
{
    $tryNum = 0
    do
    {
        $tryNum += 1
        $website = Get-IisWebsite -SiteName $SiteName
        if( $website.State -eq 'Started' )
        {
            break
        }
        
        try
        {
            $website.Start()
        }
        catch
        {
            Write-Warning -Message ('Exception trying to start website "{0}": {1}' -f $SiteName,$_)
            $Global:Error.RemoveAt(0)
        }
        Start-Sleep -Milliseconds 100
        
    } while( $tryNum -lt 100 )
    
    $website.State | Should -Be 'Started'
}

$SiteName = 'TestNewWebsite'
$testDir = $null

Describe 'Install-IisWebsite' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $testDir -ItemType 'Directory'
        Remove-TestSite
        Grant-Permission -Identity Everyone -Permission ReadAndExecute -Path $TestDir
    }
    
    AfterEach {
        Remove-TestSite
    }
    
    It 'should create website' {
        Invoke-NewWebsite -SiteID 5478
        
        $details = Get-IisWebsite -Name $SiteName
        $details | Should -Not -BeNullOrEmpty
        $details | Should -BeLike $SiteName
        $details.Bindings[0].Protocol | Should -Be 'http'
        $details.Bindings[0].BindingInformation | Should -Be '*:80:'
        
        $details.PhysicalPath | Should -Be $testDir
        
        $anonymousAuthInfo = Get-IisSecurityAuthentication -Anonymous -SiteName $SiteName
        $anonymousAuthInfo['userName'] | Should -BeNullOrEmpty
    
        $website = Get-IisWebsite -Name $SiteName
        $website | Should -Not -BeNullOrEmpty
        $website.Id | Should -Be 5478
    }
    
    It 'should resolve relative path' {
        $newDirName = [IO.Path]::GetRandomFileName()
        $newDir = Join-Path -Path $testDir -ChildPath ('..\{0}' -f $newDirName)
        New-Item -Path $newDir -ItemType 'Directory'
        Install-IisWebsite -Name $SiteName -Path ('{0}\..\{1}' -f $testDir,$newDirName)
        $site = Get-IisWebsite -SiteName $SiteName
        $site | Should -Not -BeNullOrEmpty
        $site.PhysicalPath | Should -Be ([IO.Path]::GetFullPath($newDir))
    }
    
    It 'should create website with custom binding' {
        Invoke-NewWebsite -Bindings 'http/*:9876:'
        Wait-ForWebsiteToBeRunning
        Assert-WebsiteRunning 9876
    }
    
    It 'should create website with multiple bindings' {
        Invoke-NewWebsite -Bindings 'http/*:9876:','http/*:9877:'
        Wait-ForWebsiteToBeRunning
        Assert-WebsiteRunning 9876
        Assert-WebsiteRunning 9877
    }
    
    It 'should add site to custom app pool' {
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
        
        $appPool | Should -Be $SiteName
    }
    
    It 'should update existing site' {
        Invoke-NewWebsite -Bindings 'http/*:9876:'
        $Global:Error.Count | Should -Be 0
        (Test-IisWebsite -Name $SiteName) | Should -BeTrue
        Install-IisVirtualDirectory -SiteName $SiteName -VirtualPath '/ShouldStillHangAround' -PhysicalPath $PSScriptRoot
        
        Invoke-NewWebsite
        $Global:Error.Count | Should -Be 0
        (Test-IisWebsite -Name $SiteName) | Should -BeTrue
    
        $website = Get-IisWebsite -Name $SiteName
        ($website.Applications[0].VirtualDirectories | Where-Object { $_.Path -eq '/ShouldStillHangAround' } ) | Should -Not -BeNullOrEmpty
    }
    
    It 'should create site directory' {
        $websitePath = Join-Path $TestDir ShouldCreateSiteDirectory
        if( Test-Path $websitePath -PathType Container )
        {
            $null = Remove-Item $websitePath -Force
        }
        
        try
        {
            Install-IisWebsite -Name $SiteName -Path $websitePath -Bindings 'http/*:9876:'
            Test-Path -Path $websitePath -PathType Container | Should -BeTrue
        }
        finally
        {
            if( Test-Path $websitePath -PathType Container )
            {
                $null = Remove-Item $websitePath -Force
            }
        }
    }
    
    It 'should validate bindings' {
        $error.Clear()
        Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'http/*' -ErrorAction SilentlyContinue
        ($error.Count -ge 1) | Should -BeTrue
        (Test-IisWebsite -Name $SiteName) | Should -Be $false
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should Match 'bindings are invalid'
    }
    
    It 'should allow url bindings' {
        Invoke-NewWebsite -Bindings 'http://*:9876'
        (Test-IisWebsite -Name $SiteName) | Should -BeTrue
        Wait-ForWebsiteToBeRunning
        Assert-WebsiteRunning 9876
    }
    
    It 'should allow https bindings' {
        Install-IisWebsite -Name $SiteName -Path $TestDir -Bindings 'https/*:9876:','https://*:9443'
        (Test-IisWebsite -Name $SiteName) | Should -BeTrue
        $bindings = Get-IisWebsite -SiteName $SiteName | Select-Object -ExpandProperty Bindings
        $bindings[0].Protocol | Should -Be 'https'
        $bindings[1].Protocol | Should -Be 'https'
    }
    
    It 'should not recreate existing website' {
        Install-IisWebsite -Name $SiteName -PhysicalPath $TestDir -Bindings 'http/*:9876:'
        $website = Get-IisWebsite -Name $SiteName
        $website | Should -Not -BeNullOrEmpty
    
        Install-IisWebsite -Name $SiteName -PhysicalPath $TestDir -Bindings 'http/*:9876:'
        $Global:Error.Count | Should -Be 0
        $newWebsite = Get-IisWebsite -Name $SiteName
        $newWebsite | Should -Not -BeNullOrEmpty
        $newWebsite.Id | Should -Be $website.Id
    }
    
    It 'should change website settings' {
        $appPool = Install-IisAppPool -Name 'CarbonShouldChangeWebsiteSettings' -PassThru
        $tempDir = New-TempDirectory -Prefix $PSCommandPath
        
        try
        {
            Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot
            $Global:Error.Count | Should -Be 0
            $website = Get-IisWebsite -Name $SiteName
            $website | Should -Not -BeNullOrEmpty
            $website.Name | Should -Be $SiteName
            $website.PhysicalPath | Should -Be $PSScriptRoot
    
            Install-IisWebsite -Name $SiteName -PhysicalPath $tempDir -Bindings 'http/*:9986:' -SiteID 9986 -AppPoolName $appPool.Name
            $Global:Error.Count | Should -Be 0
            $website = Get-IisWebsite -Name $SiteName
            $website | Should -Not -BeNullOrEmpty
            $website.Name | Should -Be $SiteName
            $website.PhysicalPath | Should -Be $tempDir.FullName
            $website.Id | Should -Be 9986
            $website.Applications[0].ApplicationPoolName | Should -Be $appPool.Name
            Assert-WebsiteBinding '[http] *:9986:' 
        }
        finally
        {
            Uninstall-IisAppPool -Name $appPool.Name
            Remove-Item -Path $tempDir -Recurse
        }
    }
    
    It 'should update bindings' {
        $output = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot
        $output | Should -BeNullOrEmpty
    
        Install-IisWebsite -Name $SiteName -Bindings 'http/*:8001:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8001:'
        Install-IisWebsite -Name $SiteName -Bindings 'http/*:8001:','http/*:8002:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8001:', '[http] *:8002:'
        Install-IisWebsite -Name $SiteName -Bindings 'http/*:8002:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8002:'
        Install-IisWebsite -Name $SiteName -Bindings 'http/*:8003:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8003:'
    }
    
    It 'should return site object' {
        $site = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot -PassThru
        $site | Should -Not -BeNullOrEmpty
        $site | Should -BeOfType ([Microsoft.Web.Administration.Site])
        $site.Name | Should -Be $SiteName
        $site.PhysicalPath | Should -Be $PSScriptRoot
    
        $site = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot 
        $site | Should -BeNullOrEmpty
    }
    
    It 'should force delete and recreate' {
        $output = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot -Binding 'http/*:9891:'
        $output | Should -BeNullOrEmpty
    
        Set-IisHttpHeader -SiteName $SiteName -Name 'X-Carbon-Test' -Value 'Test-ShouldFoceDeleteAndRecreate'
    
        $output = Install-IisWebsite -Name $SiteName -PhysicalPath $PSScriptRoot -Binding 'http/*:9891:' -Force
        $output | Should -BeNullOrEmpty
        (Get-IisHttpHeader -SiteName $SiteName -Name 'X-Carbon-Test') | Should -BeNullOrEmpty
    }
}
