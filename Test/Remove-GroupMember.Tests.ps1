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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Init
{
}

function GivenGroup
{
    param(
        $Name,
        $WithMember
    )

    GivenUser -UserName $WithMember

    $WithMember = $WithMember | ForEach-Object { Resolve-IdentityName -Name $_ }

    Install-Group -Name $Name -Description ('Carbon.{0} test group.' -f ($PSCommandPath | Split-Path -Leaf))
    $group = Get-Group -Name $Name
    $membersToRemove = $group.Members |
                        Where-Object {
                                        $currentMemberName = Resolve-Identity -SID $_.Sid
                                        return ($currentMemberName -notin $WithMember )
                                    }

    foreach( $memberToRemove in $membersToRemove )
    {
        $group.Members.Remove($memberToRemove)
    }

    $group.Save()
    $group.Dispose()

    Add-GroupMember -Name $Name -Member $WithMember
}

function GivenUser
{
    param(
        $UserName
    )

    foreach( $member in $UserName )
    {
        Install-User -Credential (New-Credential -UserName $member -Password 'UVjh9DXN8YqD') -Description ('Carbon.{0} test user.' -f ($PSCommandPath | Split-Path -Leaf))
    }
}

function ThenError
{
    param(
        $Matches
    )

    It ('should write no errors') {
        $Global:Error | Should Match $Matches
    }
}

function ThenNoError
{
    param(
    )

    It ('should write no errors') {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenGroup
{
    param(
        $Name,
        [string[]]
        $HasMember
    )

    $HasMember = $HasMember | ForEach-Object { Resolve-IdentityName -Name $_ }

    $group = Get-Group -Name $Name
    It ('should remove members') {
      
        $group.Members.Count | Should Be $HasMember.Count
        foreach( $currentMember in $group.Members )
        {
            $currentMemberName = Resolve-IdentityName -SID $currentMember.Sid
            $currentMemberName -in $HasMember | Should Be $true
        }
        $group.Save()
        $group.Dispose()
    }
}

function WhenRemoving
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        $Member,
        $FromGroup
    )

    $Global:Error.Clear()
    Remove-GroupMember -Name $FromGroup -Member $Member
}

Describe 'Remove-GroupMember.when removing single member' {
    Init
    GivenGroup 'FubarSnafu' -WithMember 'one','two'
    WhenRemoving 'one' -FromGroup 'FubarSnafu'
    ThenGroup 'FubarSnafu' -HasMember 'two'
}

Describe 'Remove-GroupMember.when removing multiple members' {
    Init
    GivenGroup 'FubarSnafu' -WithMember 'one','two','three'
    WhenRemoving 'one','two' -FromGroup 'FubarSnafu'
    ThenGroup 'FubarSnafu' -HasMember 'three'
}

Describe 'Remove-GroupMember.when removing all members' {
    Init
    GivenGroup 'FubarSnafu' -WithMember 'one','two','three'
    WhenRemoving 'one','two','three' -FromGroup 'FubarSnafu'
    ThenGroup 'FubarSnafu' -HasMember @()
}

Describe 'Remove-GroupMember.when removing user not in group' {
    Init
    GivenGroup 'FubarSnafu' -WithMember 'one'
    GivenUser 'two'
    WhenRemoving 'two' -FromGroup 'FubarSnafu'
    ThenGroup 'FubarSnafu' -HasMember 'one'
    ThenNoError
}

Describe 'Remove-GroupMember.when removing user that does not exist' {
    Init
    GivenGroup 'FubarSnafu' -WithMember 'one'
    WhenRemoving 'fdfsadfdsf' -FromGroup 'FubarSnafu' -ErrorAction SilentlyContinue
    ThenGroup 'FubarSnafu' -HasMember 'one'
    ThenError -Matches 'Identity\ ''fdfsadfdsf'' not found\.'
}

Describe 'Remove-GroupMember.when group does not exist' {
    Init
    WhenRemoving 'fdfsadfdsf' -FromGroup 'jkfdsjfldsf' -ErrorAction SilentlyContinue
    ThenError -Matches 'Local\ group\ "jkfdsjfldsf" not found\.'
}

Describe 'Remove-GroupMember.when using -WhatIf switch' {
    Init
    GivenGroup 'FubarSnafu' -WithMember 'one','two'
    WhenRemoving 'one' -FromGroup 'FubarSnafu' -WhatIf
    ThenNoError
    ThenGroup 'FubarSnafu' -HasMember 'one','two'
}
