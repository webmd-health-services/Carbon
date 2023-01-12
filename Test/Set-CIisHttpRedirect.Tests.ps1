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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:port = 9877
    $script:webRoot = Join-Path -Path $PSScriptRoot 'IIS'
    $script:webConfig = Join-Path $script:webRoot web.config
    $script:siteName = 'CarbonSetIisHttpRedirect'

    function Read-Url($Path = '')
    {
        $browser = New-Object Net.WebClient
        return $browser.downloadString( "http://localhost:$script:port/$Path" )
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
}

Describe 'Set-CIisHttpRedirect' {
    BeforeEach {
        Install-CIisWebsite -Name $script:siteName -Path $script:webRoot -Bindings "http://*:$script:port"
        if( Test-Path $script:webConfig )
        {
            Remove-Item $script:webConfig
        }
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should redirect site' {
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com'
        Assert-Redirects
        Assert-FileDoesNotExist $webConfig # make sure committed to applicationHost.config
        $settings = Get-IisHttpRedirect -SiteName $script:siteName
        $settings.Enabled | Should -BeTrue
        $settings.Destination | Should -Be 'http://www.example.com'
        $settings.ExactDestination | Should -BeFalse
        $settings.ChildOnly | Should -BeFalse
        $settings.HttpResponseStatus | Should -Be Found
    }

    It 'should set redirect customizations' {
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com' -HttpResponseStatus 'Permanent' -ExactDestination -ChildOnly
        Assert-Redirects
        $settings = Get-IisHttpRedirect -SiteName $script:siteName
        $settings.Destination | Should -Be 'http://www.example.com'
        $settings.HttpResponseStatus | Should -Be 'Permanent'
        $settings.ExactDestination | Should -BeTrue
        $settings.ChildOnly | Should -BeTrue
    }

    It 'should set to default values' {
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com' -HttpResponseStatus 'Permanent' -ExactDestination -ChildOnly
        Assert-Redirects
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com'
        Assert-Redirects

        $settings = Get-IisHttpRedirect -SiteName $script:siteName
        $settings.Destination | Should -Be 'http://www.example.com'
        $settings.HttpResponseStatus | Should -Be 'Found'
        $settings.ExactDestination | Should -BeFalse
        $settings.ChildOnly | Should -BeFalse
    }

    It 'should set redirect on path' {
        Set-CIisHttpRedirect -SiteName $script:siteName -Path SubFolder -Destination 'http://www.example.com'
        Assert-Redirects -Path Subfolder
        $content = Read-Url -Path 'NewWebsite.html'
        $content | Should -Match 'NewWebsite'

        $settings = Get-IisHttpREdirect -SiteName $script:siteName -Path SubFolder
        $settings.Enabled | Should -BeTrue
        $settings.Destination | Should -Be 'http://www.example.com'
    }
}
