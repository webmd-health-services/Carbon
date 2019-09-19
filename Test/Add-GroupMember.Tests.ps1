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

#Requires -Version 4.0
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$GroupName = 'AddMemberToGroup'
$user2 = $null

$user1 = $CarbonTestUser
$user2 = Install-User -Credential (New-Credential -UserName 'CarbonTestUser2' -Password 'P@ssw0rd!') -PassThru

function Assert-ContainsLike
{
    param(
        [string]$Haystack,
        [string]$Needle
    )

    $pattern = '*{0}*' -f $Needle
    $Haystack |
        Where-Object { $_ -like $pattern } |
        Should -Not -BeNullOrEmpty
}

function Assert-MembersInGroup
{
    param(
        [string[]]$Member
    )

    $group = Get-Group -Name $GroupName
    if( -not $group )
    {
        return
    }

    try
    {
        $group | Should -Not -BeNullOrEmpty
        $Member | 
            ForEach-Object { Resolve-Identity -Name $_ } |
            ForEach-Object { 
                $identity = $_
                $members = $group.Members | Where-Object { $_.Sid -eq $identity.Sid }
                $members | Should -Not -BeNullOrEmpty
            }
    }
    finally
    {
        $group.Dispose()
    }
}

Describe 'Add-GroupMember' {
    
    BeforeEach {
        $Global:Error.Clear()
        Install-Group -Name $GroupName -Description "Group for testing the Add-MemberToGroup Carbon function."
    }
    
    AfterEach {
        Remove-Group
    }
    
    function Remove-Group
    {
        $group = Get-Group -Name $GroupName
        try
        {
            if( $group )
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
    
    function Get-LocalUsers
    {
        return Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True" |
                    Where-Object { $_.Name -ne $env:COMPUTERNAME }
    }
    
    function Invoke-AddMembersToGroup($Members = @())
    {
        Add-GroupMember -Name $GroupName -Member $Members
        Assert-MembersInGroup -Member $Members
    }
    
    if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -eq 'WBMD' )
    {
        It 'should add member from domain' {
            Invoke-AddMembersToGroup -Members 'WBMD\WHS - Lifecycle Services' 
        }
    }
    
    It 'should add local user' {
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
        $addedAuser | Should -BeTrue
    }
    
    It 'should add multiple members' {
        $members = @( $user1.UserName, $user2.SamAccountName )
        Invoke-AddMembersToGroup -Members $members
    }
    
    It 'should support should process' {
        Add-GroupMember -Name $GroupName -Member $user1.UserName -WhatIf
        $details = net localgroup $GroupName
        foreach( $line in $details )
        {
            ($details -like ('*{0}*' -f $user1.UserName)) | Should -BeFalse
        }
    }
    
    It 'should add network service' {
        Add-GroupMember -Name $GroupName -Member 'NetworkService'
        $details = net localgroup $GroupName
        Assert-ContainsLike $details 'NT AUTHORITY\Network Service'
    }
    
    It 'should detect if network service already member of group' {
        Add-GroupMember -Name $GroupName -Member 'NetworkService'
        Add-GroupMember -Name $GroupName -Member 'NetworkService'
        $Error.Count | Should -Be 0
    }
    
    It 'should add administrators' {
        Add-GroupMember -Name $GroupName -Member 'Administrators'
        $details = net localgroup $GroupName
        Assert-ContainsLike $details 'Administrators'
    }
    
    It 'should detect if administrators already member of group' {
        Add-GroupMember -Name $GroupName -Member 'Administrators'
        Add-GroupMember -Name $GroupName -Member 'Administrators'
        $Error.Count | Should -Be 0
    }
    
    It 'should add anonymous logon' {
        Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
        $details = net localgroup $GroupName
        Assert-ContainsLike $details 'NT AUTHORITY\ANONYMOUS LOGON'
    }
    
    It 'should detect if anonymous logon already member of group' {
        Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
        Add-GroupMember -Name $GroupName -Member 'ANONYMOUS LOGON'
        $Error.Count | Should -Be 0
    }
    
    It 'should add everyone' {
        Add-GroupMember -Name $GroupName -Member 'Everyone'
        $Error.Count | Should -Be 0
        Assert-MembersInGroup 'Everyone'
    }
    
    It 'should add NT service accounts' {
        if( (Test-Identity -Name 'NT Service\Fax') )
        {
            Add-GroupMember -Name $GroupName -Member 'NT SERVICE\Fax'
            $Error.Count | Should -Be 0
            Assert-MembersInGroup 'NT SERVICE\Fax'
        }
    }
    
    It 'should refuse to add local group to local group' {
        Add-GroupMember -Name $GroupName -Member $GroupName -ErrorAction SilentlyContinue
        $Error.Count | Should -Be 2
        $Error[0].Exception.Message | Should -BeLike '*Failed to add*'
    }
    
    It 'should not add non existent member' {
        $Error.Clear()
        $groupBefore = Get-Group -Name $GroupName
        try
        {
            Add-GroupMember -Name $GroupName -Member 'FJFDAFJ' -ErrorAction SilentlyContinue
            $Error.Count | Should -Be 1
            $groupAfter = Get-Group -Name $GroupName
            $groupAfter.Members.Count | Should -Be $groupBefore.Members.Count
        }
        finally
        {
            $groupBefore.Dispose()
        }
    }
    
}
