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

$Path = $null
$user = 'CarbonGrantPerms'
$containerPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $TestDir -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
    Install-User -Username $user -Password 'a1b2c3d4!' -Description 'User for Carbon Grant-Permission tests.'
}

function Start-Test
{
    
    $Path = @([IO.Path]::GetTempFileName())[0]
    Grant-Permission -Path $Path -Identity $user -Permission 'FullControl'
}

function Stop-Test
{
    if( Test-Path $Path )
    {
        Remove-Item $Path -Force
    }
}

function Test-ShouldRevokePermission
{
    Revoke-Permission -Path $Path -Identity $user
    Assert-NoError
    Assert-False (Test-Permission -Path $Path -Identity $user -Permission 'FullControl')
}

function Test-ShouldNotRevokeInheritedPermissions
{
    Get-Permission -Path $Path -Inherited | 
        Where-Object { $_.IdentityReference -notlike ('*{0}*' -f $user) } |
        ForEach-Object {
            $result = Revoke-Permission -Path $Path -Identity $_.IdentityReference
            Assert-NoError
            Assert-Null $result
            Assert-True (Test-Permission -Identity $_.IdentityReference -Path $Path -Inherited -Permission $_.FileSystemRights)
        }
}

function Test-ShouldHandleRevokingNonExistentPermission
{
    Revoke-Permission -Path $Path -Identity $user
    Assert-False (Test-Permission -Path $Path -Identity $user -Permission 'FullControl')
    Revoke-Permission -Path $Path -Identity $user
    Assert-NoError
    Assert-False (Test-Permission -Path $Path -Identity $user -Permission 'FullControl')
}

function Test-ShouldResolveRelativePath
{
    Push-Location -Path (Split-Path -Parent -Path $Path)
    try
    {
        Revoke-Permission -Path ('.\{0}' -f (Split-Path -Leaf -Path $Path)) -Identity $user
        Assert-False (Test-Permission -Path $Path -Identity $user -Permission 'FullControl')
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldSupportWhatIf
{
    Revoke-Permission -Path $Path -Identity $user -WhatIf
    Assert-True (Test-Permission -Path $Path -Identity $user -Permission 'FullControl')
}

function Test-ShouldRevokePermissionOnRegistry
{
    $regKey = 'hkcu:\TestRevokePermissions'
    New-Item $regKey
    
    try
    {
        Grant-Permission -Identity $user -Permission 'ReadKey' -Path $regKey
        $result = Revoke-Permission -Path $regKey -Identity $user
        Assert-Null $result
        Assert-False (Test-Permission -Path $regKey -Identity $user -Permission 'ReadKey')
    }
    finally
    {
        Remove-Item $regKey
    }
}