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

$appPoolName = 'CarbonTestUninstallAppPool'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-IisAppPool -Name $appPoolName
    Assert-False (Test-IisAppPool -Name $appPoolName)
}

function Stop-Test
{
    Uninstall-IisAppPool -Name $appPoolName
}

function Test-ShouldRemoveAppPool
{
    Install-IisAppPool -Name $appPoolName
    Assert-True (Test-IisAppPool -Name $appPoolName)
    Uninstall-IisAppPool -Name $appPoolName 
    Assert-False (Test-IisAppPool -Name $appPoolName)    
}

function Test-ShouldRemvoeMissingAppPool
{
    $missingAppPool = 'IDoNotExist'
    Assert-False (Test-IisAppPool -Name $missingAppPool)
    Uninstall-IisAppPool -Name $missingAppPool 
    Assert-False (Test-IisAppPool -Name $missingAppPool)    
}

function Test-ShouldSupportWhatIf
{
    Install-IisAppPool -Name $appPoolName
    Assert-True (Test-IisAppPool -Name $appPoolName)
    
    Uninstall-IisAppPool -Name $appPoolName -WhatIf
    Assert-True (Test-IisAppPool -Name $appPoolName)
}

