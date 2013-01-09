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
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    
    $username = 'CarbonGrantSrvcPerms' 
    $password = 'a1b2c3d4#'
    Install-User -Username $username -Password $password -Description 'Account for testing Carbon Grant-ServicePermission functions.'
    
    $serviceName = 'CarbonGrantServicePermission' 
    $servicePath = Join-Path $TestDir ..\Service\NoOpService.exe -Resolve
    Install-Service -Name $serviceName -Path $servicePath -StartupType Disabled

    Revoke-ServicePermission -Name $serviceName -Identity $username
    $perms = Get-ServicePermission -Name $serviceName -Identity $username
    Assert-Null $perms
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGrantFullControl
{
    
    Grant-ServicePermission -Name $serviceName -Identity $username -FullControl
    $perm = Get-ServicePermission -Name $serviceName -Identity $username
    Assert-NotNull $perm
    Assert-Equal ([Carbon.Security.ServiceAccessRights]::FullControl) $perm.ServiceAccessRights
}

function Test-ShouldGrantIndividualPermissions
{
    [Enum]::GetValues( [Carbon.Security.ServiceAccessRights] ) |
        ForEach-Object {
            $grantArgs = @{
                $_ = $true;
            }
            Grant-ServicePermission -Name $serviceName -Identity $username @grantArgs
            $perm = Get-ServicePermission -Name $serviceName -Identity $username
            Assert-NotNull $perm
            Assert-Equal ([Carbon.Security.ServiceAccessRights]::$_) $perm.ServiceAccessRights
        }
}

function Test-ShouldGrantAllPermissions
{
    $grantArgs = @{ }
    [Enum]::GetValues( [Carbon.Security.ServiceAccessRights] ) |
        Where-Object { $_ -ne 'FullControl' } |
        ForEach-Object { $grantArgs.$_ = $true }
        
    Grant-ServicePermission -Name $serviceName -Identity $username @grantArgs
    $perm = Get-ServicePermission -Name $serviceName -Identity $username
    Assert-NotNull $perm
    Assert-Equal ([Carbon.Security.ServiceAccessRights]::FullControl) $perm.ServiceAccessRights
}
