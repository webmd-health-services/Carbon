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

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}


if( (Get-Command servermanagercmd.exe -ErrorAction SilentlyContinue) )
{
    function Test-ShouldDetectInstalledFeature
    {
        $installedFeatures = servermanagercmd.exe -q
        foreach( $line in $installedFeatures )
        {
            if( $line -match 'X\].*\[(.+?)\]$' )
            {
                $featureName = $matches[1]
                Assert-NotEmpty $featureName
                Assert-True (Test-WindowsFeature -Name $featureName)
                break
            }
        }
    }
    
    function Test-ShouldDetectUninstalledFeature
    {
        $installedFeatures = servermanagercmd.exe -q
        foreach( $line in $installedFeatures )
        {
            if( $line -match ' \].*\[(.+?)\]$' )
            {
                $featureName = $matches[1]
                Assert-NotEmpty $featureName
                Assert-False (Test-WindowsFeature -Name $featureName)
                break
            }
        }
    }
}
elseif( (Get-WmiObject -Class Win32_OptionalFeatures -ErrorAction SilentlyContinue) )
{
    function Test-ShouldDetectInstalledFeature
    {
        $components = Get-WmiObject -Query "select Name,InstallState from Win32_OptionalFeature where InstallState=1"
        foreach( $component in $components )
        {
            $installed = Test-WindowsFeatures -Name $component.Name
            Assert-True $installed "for component '$($component.Name)'"
        }
    }
    
    function Test-ShouldDetectUninstalledFeature
    {
        $components = Get-WmiObject -Query "select Name,InstallState from Win32_OptionalFeature where InstallState=2"
        foreach( $component in $components )
        {
            $installed = Test-WindowsFeatures -Name $component.Name
            Assert-False $installed
        }
    }

}
else
{
    Write-Error 'Unable to test Test-WindowsFeature on this machine.'
}
