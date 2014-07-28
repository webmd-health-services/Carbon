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

$GroupName = 'CarbonRemoveGroupMember'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    $users = Get-User
    Remove-Group
    Install-Group -Name $GroupName -Description "Group for testing the Remvoe-GroupMember Carbon function." -Member $users
    $group = Get-Group -Name $GroupName
    Assert-Equal $users.Count $group.Members.Count
}

function Stop-Test
{
    Remove-Group
}

function Remove-Group
{
    $group = Get-Group -Name $GroupName -ErrorAction Ignore
    if( $group -ne $null )
    {
        net localgroup `"$GroupName`" /delete
    }
}

function Test-ShouldRemoveIndividualMembers
{
    Get-User | ForEach-Object { Remove-GroupMember -Name $GroupName -Member $_.SamAccountName }
    Assert-NoError
    $group = Get-Group -Name $GroupName
    Assert-Equal 0 $group.Members.Count
}

function Test-ShouldRemoveBulkMembers
{
    $users = Get-User
    Remove-GroupMember -Name $GroupName -Member $users
    Assert-NoError
    $group = Get-Group -Name $GroupName
    Assert-Equal 0 $group.Members.Count
}

function Test-ShouldSupportWhatIf
{
    $users = Get-User
    $users | ForEach-Object { Remove-GroupMember -Name $GroupName -Member $_.SamAccountName -WhatIf }
    $group = Get-Group -Name $GroupName
    Assert-Equal $users.Count $group.Members.Count
}