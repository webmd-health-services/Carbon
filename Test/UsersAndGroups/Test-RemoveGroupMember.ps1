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
    try
    {
        Remove-Group
        Install-Group -Name $GroupName -Description "Group for testing the Remvoe-GroupMember Carbon function." -Member $users
        $group = Get-Group -Name $GroupName
        try
        {
            Assert-Equal $users.Count $group.Members.Count
        }
        finally
        {
            $group.Dispose()
        }
    }
    finally
    {
        $users | ForEach-Object { $_.Dispose() }
    }
}

function Stop-Test
{
    Remove-Group
}

function Remove-Group
{
    $group = Get-Group -Name $GroupName -ErrorAction Ignore
    try
    {
        if( $group -ne $null )
        {
            net localgroup `"$GroupName`" /delete
        }
    }
    finally
    {
        if( $group )
        {
            $group.Dispose()
        }
    }
}

function Test-ShouldRemoveIndividualMembers
{
    Get-User | ForEach-Object { Remove-GroupMember -Name $GroupName -Member $_.SamAccountName ; $_.Dispose() }
    Assert-NoError
    $group = Get-Group -Name $GroupName
    try
    {
        Assert-Equal 0 $group.Members.Count
    }
    finally
    {
        $group.Dispose()
    }
}

function Test-ShouldRemoveBulkMembers
{
    $users = Get-User
    try
    {
        Remove-GroupMember -Name $GroupName -Member $users
        Assert-NoError
    }
    finally
    {
        $users | ForEach-Object { $_.Dispose() }
    }

    $group = Get-Group -Name $GroupName
    try
    {
        Assert-Equal 0 $group.Members.Count
    }
    finally
    {
        $group.Dispose()
    }
}

function Test-ShouldSupportWhatIf
{
    $users = Get-User
    $users | ForEach-Object { Remove-GroupMember -Name $GroupName -Member $_.SamAccountName -WhatIf; $_.Dispose() }
    $group = Get-Group -Name $GroupName
    try
    {
        Assert-Equal $users.Count $group.Members.Count
    }
    finally
    {
        $group.Dispose()
    }
}