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

$user = 'CarbonTestUser1'
$group1 = 'CarbonTestGroup1'
$password = 'a1z2b3y4!'
$containerPath = $null
$childPath = $null

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    
    Install-User -Username $user -Password $password -Description 'Carbon test user 1'
    Install-Group -Name $group1 -Description 'Carbon test group 1'

    $containerPath = 'Carbon-Test-GetPermissions-{0}' -f ([IO.Path]::GetRandomFileName())
    $containerPath = Join-Path $env:Temp $containerPath
    
    $null = New-Item $containerPath -ItemType Directory
    Grant-Permissions -Path $containerPath -Identity $group1 -Permissions Read
    
    $childPath = Join-Path $containerPath 'Child1'
    $null = New-Item $childPath -ItemType File
    Grant-Permissions -Path $childPath -Identity $user -Permissions Read
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetPermissions
{
    $perms = Get-Permission -Path $childPath
    Assert-NotNull $perms
    $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$group1" }
    Assert-Null $group1Perms
    
    $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$user" }
    Assert-NotNull $userPerms
    Assert-True ($userPerms -is [Security.AccessControl.FileSystemAccessrule])
}

function Test-ShouldGetInheritedPermissions
{
    $perms = Get-Permission -Path $childPath -Inherited
    Assert-NotNull $perms
    $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$group1" }
    Assert-NotNull $group1Perms
    Assert-True ($group1Perms -is [Security.AccessControl.FileSystemAccessrule])
    
    $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$user" }
    Assert-NotNull $userPerms
    Assert-True ($userPerms -is [Security.AccessControl.FileSystemAccessrule])
}

function Test-ShouldGetSpecificUserPermissions
{
    $perms = Get-Permission -Path $childPath -Identity $group1
    Assert-Null $perms
    
    $perms = @( Get-Permission -Path $childPath -Identity $user )
    Assert-NotNull $perms
    Assert-Equal 1 $perms.Length
    Assert-NotNull $perms[0]
    Assert-True ($perms[0] -is [Security.AccessControl.FileSystemAccessrule])
}

function Test-ShouldGetSpecificUsersInheritedPermissions
{
    $perms = Get-Permission -Path $childPath -Identity $group1 -Inherited
    Assert-NotNull $perms
    Assert-True ($perms -is [Security.AccessControl.FileSystemAccessRule])
}

function Test-ShouldGetPermissionsOnRegistryKey
{
    $perms = Get-Permission -Path 'hklm:software'
    Assert-NotNull $perms
    $perms | ForEach-Object {
        Assert-True ($_ -is [Security.AccessControl.RegistryAccessRule])
    }
}