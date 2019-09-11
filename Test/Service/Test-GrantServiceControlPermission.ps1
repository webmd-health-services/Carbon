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

$user = 'CrbnGrantCntrlSvcUsr'
$password = [Guid]::NewGuid().ToString().Substring(0,9) + "Aa1"
$userPermStartPattern = "/pace =$($env:ComputerName)\$user*"
    
function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -username $user -Password $password
    
    $serviceName = $serviceBaseName + ([Guid]::NewGuid().ToString())
    Install-Service -Name $serviceName -Path $servicePath -Username $user -Password $password
}

function Stop-Test
{
    Uninstall-Service -Name $serviceName
    Uninstall-User -Username $user
}

function Test-ShouldGrantControlServicePermission
{
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-Null $currentPerms "User '$user' already has permissions on '$serviceName'."
    
    Grant-ServiceControlPermission -ServiceName $serviceName -Identity $user
    Assert-LastProcessSucceeded
    
    $expectedAccessRights = [Carbon.Security.ServiceAccessRights]::QueryStatus -bor `
                            [Carbon.Security.ServiceAccessRights]::EnumerateDependents -bor `
                            [Carbon.Security.ServiceAccessRights]::Start -bor `
                            [Carbon.Security.ServiceAccessRights]::Stop
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-NotNull $currentPerms
    Assert-Equal $expectedAccessRights $currentPerms.ServiceAccessRights
}

function Test-ShouldSupportWhatIf
{
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-Null $currentPerms
    
    Grant-ServiceControlPermission -ServiceName $serviceName -Identity $user -WhatIf
    
    $currentPerms = Get-ServicePermission -Name $serviceName -Identity $user
    Assert-Null $currentPerms
}

