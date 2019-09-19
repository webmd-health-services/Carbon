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

$rootKey = 'hklm:\Software\Carbon\Test\Test-TestRegistryKeyValue'

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
    
    New-ItemProperty -Path $rootKey -Name 'Empty' -Value '' -PropertyType 'String'
    New-ItemProperty -Path $rootKey -Name 'Null' -Value $null -PropertyType 'String'
    New-ItemProperty -Path $rootKey -Name 'State' -Value 'Foobar''ed' -PropertyType 'String'
}

function Stop-Test
{
    Remove-Item $rootKey -Recurse
}

function Test-ShouldDetectValueWithEmptyValue
{
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name 'Empty')
}

function Test-ShouldDetectValueWithNullValue
{
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name 'Null')
}

function Test-ShouldDetectValueWithAValue
{
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name 'State')
}

function Test-ShouldDetectNoValueInMissingKey
{
    Assert-False (Test-RegistryKeyValue -Path (Join-Path $rootKey fjdsklfjsadf) -Name 'IDoNotExistEither')
}

function Test-ShouldNotDetectMissingValue
{
    Set-StrictMode -Version Latest
    $error.Clear()
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'BlahBlahBlah' -ErrorAction SilentlyContinue)
    Assert-Equal 0 $error.Count
}

function Test-ShouldHandleKeyWithNoValues
{
    Remove-ItemProperty -Path $rootKey -Name *
    $error.Clear()
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'Empty')
    Assert-Equal 0 $error.Count
}

