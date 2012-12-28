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

$serviceBaseName = 'CarbonGrantControlServiceTest'
$serviceName = $serviceBaseName
$servicePath = Join-Path $TestDir NoOpService.exe

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    $serviceName = $serviceBaseName + ([Guid]::NewGuid().ToString())
    Install-Service -Name $serviceName -Path $servicePath
}

function TearDown
{
    if( (Get-Service $serviceName -ErrorAction SilentlyContinue) )
    {
        Stop-Service $serviceName
        & C:\Windows\system32\sc.exe delete $serviceName
    }
    Remove-Module Carbon
}

function Test-ShouldRemoveService
{
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
    Uninstall-Service -Name $serviceName
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    Assert-Null $service
}

function Test-ShouldNotRemoveNonExistentService
{
    $error.Clear()
    Uninstall-Service -Name "IDoNotExist"
    Assert-Null $error
}

function Test-ShouldSupportWhatIf
{
    Uninstall-Service -Name $serviceName -WhatIf
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
}
