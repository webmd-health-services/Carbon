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

$rootKey = 'hklm:\Software\Carbon\Test\Test-GetRegistryValue'

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
    
    New-ItemProperty -Path $rootKey -Name 'String' -Value 'Foobar''ed' -PropertyType 'String'
    New-ItemProperty -Path $rootKey -Name 'Binary' -Value ([byte[]]@(1, 2, 3)) -PropertyType 'Binary'
    New-ItemProperty -Path $rootKey -Name 'DWord' -Value 1 -PropertyType 'DWord'
    New-ItemProperty -Path $rootKey -Name 'QWord' -Value ([Int32]::MaxValue + 1) -PropertyType 'QWord'
    New-ItemProperty -Path $rootKey -Name 'ExpandString' -Value '%ComputerName%' -PropertyType 'ExpandString'
    New-ItemProperty -Path $rootKey -Name 'MultiString' -Value @('one', 'two', 'three') -PropertyType 'MultiString'
}

function Stop-Test
{
    Remove-Item $rootKey -Recurse
}

function Test-ShouldGetStringValue
{
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'String'
    Assert-NotNull $value
    Assert-equal 'string' $value.GetType()
}

function Test-ShouldGetExpandStringValue
{
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'ExpandString'
    Assert-NotNull $value
    Assert-equal 'string' $value.GetType()
    Assert-Equal $env:ComputerName $value
}


function Test-ShouldGetMultiValue
{
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'MultiString'
    Assert-NotNull $value
    Assert-Equal 'System.Object[]' $value.GetType()
    Assert-Equal 'one' $value[0]
    Assert-Equal 'two' $value[1]
    Assert-Equal 'three' $value[2]
}


function Test-ShouldGetDWordValue
{
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'DWord'
    Assert-NotNull $value
    Assert-Equal 'int' $value.GetType()
}

function Test-ShouldGetQWordValue
{
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'QWord'
    Assert-NotNull $value
    Assert-Equal 'long' $value.GetType()
}

function Test-ShouldGetBinaryValue
{
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'Binary'
    Assert-NotNull $value
    Assert-Equal 'System.Object[]' $value.GetType()
    Assert-Equal 1 $value[0]
    Assert-Equal 2 $value[1]
    Assert-Equal 3 $value[2]
}

function Test-ShouldGetMissingValue
{
    $value = Get-RegistryKeyValue $rootKey -Name 'fdjskfldsjfklsdjflks'
    Assert-Null
}

function TEst-ShouldGetValueInMissingKey
{
    $value = Get-RegistryKeyValue (Join-Path $rootKey 'fjsdkflsjd') -Name 'fdjskfldsjfklsdjflks'
    Assert-Null
}

