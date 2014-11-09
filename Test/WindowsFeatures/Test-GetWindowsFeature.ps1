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

if( $PSVersionTable.PSVersion -gt [Version]'2.0' -and -not (Get-Module 'ServerManager') -and (Get-WmiObject -Class Win32_OptionalFeature -ErrorAction SilentlyContinue) )
{
    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    }

    function Test-ShouldReturnAllWindowsFeatures
    {
        $features = Get-WindowsFeature
        Assert-NotNull $features
        Assert-True ($features.Length -gt 1)
        $features | ForEach-Object {
            Assert-NotNull $_.Installed
            Assert-NotNull $_.Name
            Assert-NotNull $_.DisplayName
        }
    }

    function Test-ShouldReturnSpecificFeature
    {
        Get-WindowsFeature | ForEach-Object {
            $expectedFeature = $_
            $feature = Get-WindowsFeature -Name $expectedFeature.Name
            Assert-NotNull $feature
            Assert-Equal $expectedFeature.Name $feature.Name
            Assert-Equal $expectedFeature.DisplayName $feature.DisplayName
            Assert-Equal $expectedFeature.Installed $feature.Installed
        }
    }

    function Test-ShouldReturnWildcardMatches
    {
        $features = Get-WindowsFeature -Name *msmq*
        Assert-NotNull $features
        $features | ForEach-Object {
            Assert-NotNull $_.Installed
            Assert-NotNull $_.Name
            Assert-True ($_.Name -like '*msmq*')
            Assert-NotNull $_.DisplayName
        }
    }
}
else
{
    Write-Warning "Tests for Get-WindowsFeature not supported on this operating system."
}
