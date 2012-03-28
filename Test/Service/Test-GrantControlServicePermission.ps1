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

$user = 'CrbnGrantCntrlSvcUsr'
$password = [Guid]::NewGuid().ToString().Substring(0,14)
$userPermStartPattern = "/pace =$($env:ComputerName)\$user*"
    
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Install-User -username $user -Password $password
    
    $serviceName = $serviceBaseName + ([Guid]::NewGuid().ToString())
    Install-Service -Name $serviceName -Path $servicePath -Username $user -Password $password
}

function TearDown
{
    Remove-Service -Name $serviceName
    Remove-User -Username $user
    Remove-Module Carbon
}

function Test-ShouldGrantControlServicePermission
{

    $currentPerms = Invoke-SubInAcl /service $serviceName /display
    foreach( $line in $currentPerms )
    {
        if( $line -like $userPermStartPattern )
        {
            Fail "User '$user' already has permissions on '$serviceName'."
        }
    }
    
    Grant-ControlServicePermission -ServiceName $serviceName -Identity $user
    Assert-LastProcessSucceeded
    
    $currentPerms = Invoke-SubInAcl /service $serviceName /display
    $userGrantedPerms = $false
    for( $idx = 0; $idx -lt $currentPerms.Length; ++$idx )
    {
        $line = $currentPerms[$idx]
        if( $line -like $userPermStartPattern )
        {
            $line = $currentPerms[$idx + 1]
            Assert-Like $line '*SERVICE_QUERY_STATUS-0x4           SERVICE_ENUMERATE_DEPEND-0x8       SERVICE_START-0x10'
            $line = $currentPerms[$idx + 2]
            Assert-LIke $line '*SERVICE_STOP-0x20'
            $userGrantedPerms = $true
        }
    }
    
    Assert-True $userGrantedPerms
}

function Test-ShouldSupportWhatIf
{
    Grant-ControlServicePermission -ServiceName $serviceName -Identity $user -WhatIf
    
    $currentPerms = Invoke-SubInAcl /service $serviceName /display
    foreach( $line in $currentPerms )
    {
        if( $line -like $userPermStartPattern )
        {
            Fail "User '$user' has permissions on '$serviceName'."
        }
    }
}
