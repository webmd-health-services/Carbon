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
$user1 = $null
$user2 = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    $user1 = Install-User -Credential (New-Credential -UserName 'CarbonTestUser1' -Password 'P@ssw0rd!') -PassThru
    $user2 = Install-User -Credential (New-Credential -UserName 'CarbonTestUser2' -Password 'P@ssw0rd!') -PassThru
}

function Start-Test
{
    Install-Group -Name $GroupName -Description "Group for testing the Add-MemberToGroup Carbon function."
}

function Stop-Test
{
    Remove-Group
}

function Remove-Group
{
    $group = Get-Group
    try
    {
        if( $group -ne $null )
        {
            net localgroup `"$GroupName`" /delete
        }
    }
    finally
    {
        $group.Dispose()
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

if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -eq 'WBMD' )
{
    function Test-ShouldAddMemberFromDomain
    {
        Invoke-AddMembersToGroup -Members 'WBMD\WHS - Lifecycle Services' 
    }
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
    $members = @( $user1.SamAccountName, $user2.SamAccountName )
    Invoke-AddMembersToGroup -Members $members
}

function Test-ShouldSupportShouldProcess
{
    Add-GroupMember -Name $GroupName -Member $user1.SamAccountName -WhatIf
    $details = net localgroup $GroupName
    foreach( $line in $details )
    {
        Assert-False ($details -like ('*{0}*' -f $user1.SamAccountName))
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

function Test-ShouldAddEveryone
{
    Add-GroupMember -Name $GroupName -Member 'Everyone'
    Assert-Equal 0 $Error.Count
    Assert-MembersInGroup 'Everyone'
}

function Test-ShouldAddNTServiceAccounts
{
    if( (Test-Identity -Name 'NT Service\Fax') )
    {
        Add-GroupMember -Name $GroupName -Member 'NT SERVICE\Fax'
        Assert-Equal 0 $Error.Count
        Assert-MembersInGroup 'NT SERVICE\Fax'
    }
}

function Test-ShouldRefuseToAddLocalGroupToLocalGroup
{
    Add-GroupMember -Name $GroupName -Member $GroupName -ErrorAction SilentlyContinue
    Assert-Equal 2 $Error.Count
    Assert-Like $Error[0].Exception.Message '*Failed to add*'
}

function Test-ShouldNotAddNonExistentMember
{
    $Error.Clear()
    $groupBefore = Get-Group -Name $GroupName
    try
    {
        Add-GroupMember -Name $GroupName -Member 'FJFDAFJ' -ErrorAction SilentlyContinue
        Assert-Equal 1 $Error.Count
        $groupAfter = Get-Group -Name $GroupName
        Assert-Equal $groupBefore.Members.Count $groupAfter.Members.Count
    }
    finally
    {
        $groupBefore.Dispose()
    }
}

function Assert-MembersInGroup($Members)
{
    $group = Get-Group -Name $GroupName
    if( -not $group )
    {
        return
    }

    try
    {
        Assert-NotNull $group 'Group not created.'
        $Members | 
            ForEach-Object { Resolve-Identity -Name $_ } |
            ForEach-Object { 
                $identity = $_
                $member = $group.Members | Where-Object { $_.Sid -eq $identity.Sid }
                Assert-NotNull $member ('Member ''{0}'' not a member of group ''{1}''' -f $identity.FullName,$group.Name)
            }
    }
    finally
    {
        $group.Dispose()
    }
}

