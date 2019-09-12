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

$rootKey = 'hklm:\Software\Carbon\Test'

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

function Test-ShouldCreateKey
{
    $keyPath = Join-Path $rootKey 'Test-InstallRegistryKey\ShouldCreateKey'
    if( Test-Path $keyPath -PathType Container )
    {
        Remove-Item $keyPath -Recurse
    }
    
    Install-RegistryKey -Path $keyPath
    
    Assert-True (Test-Path $keyPath -PathType Container)
}

function Test-ShouldDoNothingIfKeyExists
{
    $keyPath = Join-Path $rootKey 'Test-InstallRegistryKey\ShouldDoNothingIfKeyExists'
    Install-RegistryKey -Path $keyPath
    $subKeyPath = Join-Path $keyPath 'SubKey'
    Install-RegistryKey $subKeyPath
    Install-RegistryKey -Path $keyPath
    Assert-True (Test-Path $subKeyPath -PathType Container)
}

function Test-ShouldSupportShouldProcess
{
    $keyPath = Join-Path $rootKey 'Test-InstallRegistryKey\WhatIf'
    Install-RegistryKey -Path $keyPath -WhatIf
    Assert-False (Test-Path -Path $keyPath -PathType Container)
}

