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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force
& (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)

$groupName = 'CarbonGroupTest'
$username1 = 'CarbonTestUser'
$username2 = 'CarbonTestUser2'
$username3 = 'CarbonTestUser3'
$user1 = $null
$user2 = $null
$user3 = $null
$description = 'Group for testing Carbon''s Group DSC resource.'

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'Group'
    $user1 = Install-User -Credential (New-Credential -UserName $username1 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    $user2 = Install-User -Credential (New-Credential -UserName $username2 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    $user3 = Install-User -Credential (New-Credential -UserName $username3 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    Install-Group -Name $groupName -Description $description -Member $username1,$username2
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-GetTargetResource
{
    $admins = Get-Group 'Administrators'

    $groupName = 'Administrators'
    $resource = Get-TargetResource -Name $groupName
    Assert-NotNull $resource
    Assert-Equal $resource.Name $groupName
    Assert-Equal $admins.Description $resource.Description
    Assert-DscResourcePresent $resource

    Assert-Equal $admins.Members.Count $resource.Members.Count

    foreach( $admin in $admins.Members )
    {
        $found = $false
        foreach( $potentialAdmin in $resource.Members )
        {
            if( $potentialAdmin.Sid -eq $admin.Sid )
            {
                $found = $true
                break
            }
        }
        Assert-True $found
    }
}

function Test-GetTargetResourceDoesNotExist
{
    $resource = Get-TargetResource -Name 'fubarsnafu'
    Assert-NotNull $resource
    Assert-Equal 'fubarsnafu' $resource.Name
    Assert-Null $resource.Description
    Assert-Empty $resource.Members
    Assert-DscResourceAbsent $resource
}

function Test-TestTargetResource
{
    $result = Test-TargetResource -Name $groupName -Description $description -Members ($username1,$username2)
    Assert-NotNull $result
    Assert-True $result

    $result = Test-TargetResource -Name $groupName -Ensure Absent
    Assert-NotNull $result
    Assert-False $result

    # should be out of date with no properties passed
    $result = Test-TargetResource -Name $groupName
    Assert-NotNull $result
    Assert-False $result

    $result = Test-TargetResource -Name $groupName -Members ($username1,$username2) -Description $description
    Assert-NotNull $result
    Assert-True $result

    # Now, make sure if group has extra member we get false
    $result = Test-TargetResource -Name $groupName -Members ($username1) -Description $description
    Assert-NotNull $result
    Assert-False $result

    # Now, make sure if group is missing a member we get false
    $result = Test-TargetResource -Name $groupName -Members ($username1,$username2,$username3) -Description $description
    Assert-NotNull $result
    Assert-False $result

    # Now, make sure if group description is different we get false
    $result = Test-TargetResource -Name $groupName -Members ($username1,$username2) -Description 'a new description'
    Assert-NotNull $result
    Assert-False $result

    # We get false even if members are same when should be absent
    $result = Test-TargetResource -Name $groupName -Members $username1,$username2 -Ensure Absent
    Assert-NotNull $result
    Assert-False $result

    # We get false even if description is the same when should be absent
    $result = Test-TargetResource -Name $groupName -Description $description -Ensure Absent
    Assert-NotNull $result
    Assert-False $result
}

function Test-SetTargetResource
{
    $groupName = 'TestCarbonGroup01'

    # Test for group creation
    Set-TargetResource -Name $groupName -Ensure 'Present'
    
    $group = Get-Group -Name $groupName
    Assert-NotNull $group
    Assert-Equal $groupName $group.Name
    Assert-Null $group.Description
    Assert-Equal 0 $group.Members.Count

    # Change members
    Set-TargetResource -Name $groupName -Members $username1 -Ensure 'Present'
    $group = Get-Group -Name $groupName
    Assert-NotNull $group
    Assert-Equal $groupName $group.Name
    Assert-Null $group.Description
    Assert-Equal 1 $group.Members.Count
    Assert-Equal $user1.Sid $group.Members[0].Sid

    # Change description
    Set-TargetResource -Name $groupName -Members $username1 -Description 'group description' -Ensure 'Present'
    
    $group = Get-Group -Name $groupName
    Assert-NotNull $group
    Assert-Equal $groupName $group.Name
    Assert-Equal 'group description' $group.Description
    Assert-Equal 1 $group.Members.Count
    Assert-Equal $user1.Sid $group.Members[0].Sid
    
    # Should add member
    Set-TargetResource -Name $groupName -Members $username1,$username2 -Description 'group description' -Ensure 'Present'
    $group = Get-Group -Name $groupName
    Assert-NotNull $group
    Assert-Equal $groupName $group.Name
    Assert-Equal 'group description' $group.Description
    Assert-Equal 2 $group.Members.Count
    Assert-True ($group.Members.Sid -contains $user1.Sid)
    Assert-True ($group.Members.Sid -contains $user2.Sid)

    # should support whatif for updating group
    Set-TargetResource -Name $groupName -Description 'new description' -WhatIf
    $group = Get-Group -Name $groupName
    Assert-Equal 'group description' $group.Description

    # Should support whatif for removing members
    Set-TargetResource -Name $groupName -Description 'group description' -WhatIf
    $group = Get-Group -Name $groupName
    Assert-Equal 2 $group.Members.Count

    # Should remove members and set description
    Set-TargetResource -Name $groupName -Ensure 'Present'
    $group = Get-Group -Name $groupName
    Assert-NotNull $group
    Assert-Equal $groupName $group.Name
    Assert-Null $group.Description
    Assert-Equal 0 $group.Members.Count

    # Should support WhatIf
    Set-TargetResource -Name $groupName -Ensure Absent -WhatIf
    Assert-True (Test-Group -Name $groupName)

    # Test for group deletion
    Set-TargetResource -Name $groupName -Ensure 'Absent'
    Assert-False (Test-Group -Name $groupName)
}

Configuration ShouldCreateGroup
{
    param(
        $Ensure
    )

    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        Carbon_Group CarbonTestGroup
        {
            Name = 'CDscGroup1'
            Description = 'Carbon_Group DSC resource test group'
            Members = @( $username1 )
            Ensure = $Ensure
        }
    }
}

function Test-ShouldRunThroughDsc
{
    $groupName = 'CDscGroup1'

    # Test for group creation through DSC execution
    & ShouldCreateGroup -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError

    $result = Test-TargetResource -Name $groupName -Description 'Carbon_Group DSC resource test group' -Members $username1
    Assert-NotNull $result
    Assert-True $result

    # Test for group deletion through DSC execution
    & ShouldCreateGroup -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force -Verbose
    Assert-NoError

    $result = Test-TargetResource -Name $groupName
    Assert-NotNull $result
    Assert-False $result
}