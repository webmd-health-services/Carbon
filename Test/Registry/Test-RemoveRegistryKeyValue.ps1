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

$rootKey = 'hklm:\Software\Carbon\Test\Test-RemoveRegistryKeyValue'
$valueName = 'RegValue'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    if( -not (Test-Path $rootKey -PathType Container) )
    {
        New-Item $rootKey -ItemType RegistryKey -Force
    }
    
}

function Stop-Test
{
    Remove-Item $rootKey -Recurse
}

function Test-ShouldRemoveExistingRegistryValue
{
    New-ItemProperty $rootKey -Name $valueName -Value 'it doesn''t matter' -PropertyType 'String'
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
    Remove-RegistryKeyValue -Path $rootKey -Name $valueName
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
}

function Test-ShouldRemoveNonExistentRegistryValue
{
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'I do not exist')
    Remove-RegistryKeyValue -Path $rootKey -Name 'I do not exist'
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'I do not exist')
}

function Test-ShouldSupportWhatIf
{
    New-ItemProperty $rootKey -Name $valueName -Value 'it doesn''t matter' -PropertyType 'String'
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
    Remove-RegistryKeyValue -Path $rootKey -Name $valueName -WhatIf
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
}

