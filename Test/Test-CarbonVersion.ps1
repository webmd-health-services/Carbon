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

$expectedVersion = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $line = Get-Content -Path (Join-Path $TestDir '..\RELEASE NOTES.txt' -Resolve) -TotalCount 1
    if( $line -notmatch '(\d+)\.(\d+)\.(\d+)' )
    {
        Fail 'Unable to find version number in release notes.'
    }
    
    $expectedVersion = New-Object Version $matches[1],$matches[2],$matches[3],0
}

function Test-CarbonModuleVersionIsCorrect
{
    $moduleInfo = Get-Module -Name Carbon
    Assert-NotNull $moduleInfo
    Assert-Equal $expectedVersion.Major $moduleInfo.Version.Major 'Carbon module major version not correct.'
    Assert-Equal $expectedVersion.Minor $moduleInfo.Version.Minor 'Carbon module minor version not correct.'
    Assert-Equal $expectedVersion.Build $moduleInfo.Version.Build 'Carbon module build version not correct.'
}

function Test-CarbonAssemblyVersionIsCorrect
{
    Get-ChildItem (Join-Path $TestDir '..\Carbon\bin') Carbon*.dll | ForEach-Object {

        Assert-Equal $expectedVersion $_.VersionInfo.FileVersion ('{0} assembly file version not correct.' -f $_.Name)
        Assert-Equal $expectedVersion $_.VersionInfo.ProductVersion ('{0} assembly product version not correct.' -f $_.Name)

    }
}
