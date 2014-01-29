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

function Get-LocalUsers
{
    return Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"
}

function Invoke-AddMembersToGroup($Members = @())
{
    Add-GroupMember -Name $GroupName -Member $Members
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
        Invoke-AddMembersToGroup -Members $user.Name
        $addedAUser = $true
        break
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
    Add-GroupMember -Name $GroupName -Member 'WBMD\WHS - Lifecycle Services' -WhatIf
    $details = net localgroup $GroupName
    foreach( $line in $details )
    {
        Assert-False ($details -like '*WBMD\WHS - Lifecycle Services*')
    }
}

function Test-ShouldAddNetworkService
{
    Add-GroupMember -Name $GroupName -Member 'NetworkService'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'NT AUTHORITY\Network Service'
}

function Test-ShouldDetectIfNetworkServiceAlreadyMemberOfGroup
{
    Add-GroupMember -Name $GroupName -Member 'NetworkService'
    Add-GroupMember -Name $GroupName -Member 'NetworkService'
    Assert-Equal 0 $Error.Count
}

function Test-ShouldAddAdministrators
{
    Add-GroupMember -Name $GroupName -Member 'Administrators'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'Administrators'
}

function Test-ShouldDetectIfAdministratorsAlreadyMemberOfGroup
{
    Add-GroupMember -Name $GroupName -Member 'Administrators'
    Add-GroupMember -Name $GroupName -Member 'Administrators'
    Assert-Equal 0 $Error.Count
}

function Test-ShouldAddAnonymousLogon
{
    Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'NT AUTHORITY\ANONYMOUS LOGON'
}

function Test-ShouldDetectIfAnonymousLogonAlreadyMemberOfGroup
{
    Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
    Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
    Assert-Equal 0 $Error.Count
}

function Test-ShouldNotAddNonExistentMember
{
    $Error.Clear()
    $groupBefore = Get-Group -Name $GroupName
    Add-GroupMember -Name $GroupName -Member 'FJFDAFJ' -ErrorAction SilentlyContinue
    Assert-Equal 1 $Error.Count
    $groupAfter = Get-Group -Name $GroupName
    Assert-Equal $groupBefore.Members.Count $groupAfter.Members.Count
}

function Assert-MembersInGroup($Members)
{
    $group = Get-Group -Name $GroupName
    if( -not $group )
    {
        return
    }
    Assert-NotNull $group 'Group not created.'
    $Members | 
        ForEach-Object { Resolve-Identity -Name $_ } |
        ForEach-Object { 
            $identity = $_
            $member = $group.Members | Where-Object { $_.Sid -eq $identity.Sid }
            Assert-NotNull $member ('Member ''{0}'' not a member of group ''{1}''' -f $memberName,$group.Name)
        }
}
