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


function Test-ShouldDetectInstalledFeature
{
    Get-WindowsFeature | 
        Where-Object { $_.Installed } |
        ForEach-Object {
            Assert-True (Test-WindowsFeature -Name $_.Name -Installed)
        }
}

function Test-ShouldDetectUninstalledFeature
{
    Get-WindowsFeature | 
        Where-Object { -not $_.Installed } |
        ForEach-Object {
            Assert-False (Test-WindowsFeature -Name $_.Name -Installed)
        }
}

function Test-ShouldDetectFeatures
{
    Get-WindowsFeature |
        ForEach-Object { Assert-True (Test-WindowsFeature -Name $_.Name) }
}

function Test-ShouldNotDetectFeature
{
    Assert-False (Test-WindowsFeature -Name 'IDoNotExist')
}
