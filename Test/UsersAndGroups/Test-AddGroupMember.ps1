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

$GroupName = 'AddMemberToGroup'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force

    Install-Group -Name $GroupName -Description "Group for testing the Add-MemberToGroup Carbon function."
}

function TearDown
{
    Remove-Group
    Remove-Module Carbon
}

function Remove-Group
{
    $group = Get-Group
    if( $group -ne $null )
    {
        net localgroup `"$GroupName`" /delete
    }
}

function Get-Group
{
    return Get-WmiObject Win32_Group -Filter "Name='$GroupName' and LocalAccount=True"
}

function Get-LocalUsers
{
    return Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"
}

function Invoke-AddMembersToGroup($Members = @())
{
    Add-GroupMembers -Name $GroupName -Member $Members
    Assert-MembersInGroup -Member $Members
}

function Test-ShouldAddMemberFromDomain
{
    Invoke-AddMembersToGroup -Members 'WBMD\WHS - Lifecycle Services' 
}

function Test-ShouldAddLocalUser
{
    $users = Get-LocalUsers
    if( -not $users )
    {
        Fail "This computer has no local user accounts."
    }
    $addedAUser = $false
    foreach( $user in $users )
    {
        try
        {
            Invoke-AddMembersToGroup -Members $user.Name
            $addedAUser = $true
            break
        }
        catch
        {
        }
    }
    Assert-True $addedAuser
}

function Test-ShouldAddMultipleMembers
{
    $users = Get-LocalUsers
    $members = @( $users[0].Name, 'WBMD\WHS - Lifecycle Services' )
    Invoke-AddMembersToGroup -Members $members
}

function Test-ShouldSupportShouldProcess
{
    Add-GroupMembers -Name $GroupName -Members 'WBMD\WHS - Lifecycle Services' -WhatIf
    $details = net localgroup $GroupName
    foreach( $line in $details )
    {
        Assert-False ($details -like '*WBMD\WHS - Lifecycle Services*')
    }
}

function Test-ShouldAddNetworkService
{
    Add-GroupMembers -Name $GroupName -Members 'NetworkService'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'NT AUTHORITY\Network Service'
}

function Test-ShouldDetectIfNetworkServiceAlreadyMemberOfGroup
{
    Add-GroupMembers -Name $GroupName -Members 'NetworkService'
    Add-GroupMembers -Name $GroupName -Members 'NetworkService'
    Assert-LastProcessSucceeded
}

function Test-ShouldAddAdministrators
{
    Add-GroupMembers -Name $GroupName -Members 'Administrators'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'Administrators'
}

function Test-ShouldDetectIfAdministratorsAlreadyMemberOfGroup
{
    Add-GroupMembers -Name $GroupName -Members 'Administrators'
    Add-GroupMembers -Name $GroupName -Members 'Administrators'
    Assert-LastProcessSucceeded
}

function Test-ShouldAddAnonymousLogon
{
    Add-GroupMembers -Name $GroupName -Members 'ANONYMOUS LOGON'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'NT AUTHORITY\ANONYMOUS LOGON'
}

function Test-ShouldDetectIfAnonymousLogonAlreadyMemberOfGroup
{
    Add-GroupMembers -Name $GroupName -Members 'ANONYMOUS LOGON'
    Add-GroupMembers -Name $GroupName -Members 'ANONYMOUS LOGON'
    Assert-LastProcessSucceeded
}

function Test-ShouldNotAddNonExistentMember
{
    
}

function Assert-MembersInGroup($Members)
{
    $group = Get-Group
    Assert-NotNull $group 'Group not created.'
    $details = net localgroup $GroupName
    foreach( $member in $Members )
    {
        Assert-ContainsLike $details $member 
    }
}
