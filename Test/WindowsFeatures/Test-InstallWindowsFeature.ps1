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

if( (Get-WmiObject -Class Win32_OptionalFeature -ErrorAction SilentlyContinue) )
{
    $singleFeature = 'TelnetClient'
    $multipleFeatures = @( $singleFeature, 'TFTP' )

    function Setup
    {
        & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
        Uninstall-WindowsFeature -Name $multipleFeatures
    }

    function Teardown
    {
        Uninstall-WindowsFeature -Name $multipleFeatures
        Remove-Module Carbon
    }

    function Test-ShouldInstallWindowsFeature
    {
        Assert-False (Test-WindowsFeature -Name $singleFeature -Installed)
        Install-WindowsFeature -Name $singleFeature
        Assert-True (Test-WindowsFeature -Name $singleFeature -Installed)
    }

    function Test-ShouldInstallMultipleWindowsFeatures
    {
        Assert-False (Test-WindowsFeature -Name $multipleFeatures[0] -Installed)
        Assert-False (Test-WindowsFeature -Name $multipleFeatures[1] -Installed)
        Install-WindowsFeature -Name $multipleFeatures
        Assert-True (Test-WindowsFeature -Name $multipleFeatures[0] -Installed)
        Assert-True (Test-WindowsFeature -Name $multipleFeatures[1] -Installed)
    }

    function Test-ShouldSupportWhatIf
    {
        Install-WindowsFeature -Name $singleFeature -WhatIf
        Assert-False (Test-WindowsFeature -Name $singleFeature -Installed)
    }
}
else
{
    Write-Warning "Tests for Install-WindowsFeature not supported on this operating system."
}
