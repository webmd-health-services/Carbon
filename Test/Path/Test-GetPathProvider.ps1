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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldGetFileSystemProvider
{
    Assert-Equal 'FileSystem' ((Get-PathProvider -Path 'C:\Windows').Name)
}

function Test-ShouldGetRelativePathProvider
{
    Assert-Equal 'FileSystem' ((Get-PathProvider -Path '..\').Name)
}

function Test-ShouldGetRegistryProvider
{
    Assert-Equal 'Registry' ((Get-PathProvider -Path 'hklm:\software').Name)
}

function Test-ShouldGetRelativePathProvider
{
    Push-Location 'hklm:\SOFTWARE\Microsoft'
    try
    {
        Assert-Equal 'Registry' ((Get-PathProvider -Path '..\').Name)
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldGetNoProviderForBadPath
{
    Assert-Equal 'FileSystem' ((Get-PathProvider -Path 'C:\I\Do\Not\Exist').Name)
}
