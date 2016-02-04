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
& (Join-Path -Path $PSScriptRoot -ChildPath ..\..\Carbon\Import-Carbon.ps1 -Resolve)

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'Group'
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-GetTargetResource
{
    $groupName = 'Administrators'
    $resource = Get-TargetResource -GroupName $groupName
    Assert-NotNull $resource
    Assert-Equal $resource.GroupName $groupName
    Assert-DscResourcePresent $resource
}

function Test-TestTargetResource
{
    $groupName = 'Administrators'
    $member = 'Domain Admins'

    $result = Test-TargetResource -GroupName $groupName
    Assert-NotNull $result
    Assert-True $result

    $result = Test-TargetResource -GroupName $groupName -Ensure Absent
    Assert-NotNull $result
    Assert-False $result

    $result = Test-TargetResource -GroupName $groupName -Members $member
    Assert-NotNull $result
    Assert-True $result

    $result = Test-TargetResource -GroupName $groupName -Members $member -Ensure Absent
    Assert-NotNull $result
    Assert-False $result
}

function Test-SetTargetResource
{
    $groupName = 'TestCarbonGroup01'
    $member = 'CarbonUser01'

    $testMemberCred = New-Credential -UserName $member -Password 'P@ssw0rd!'
    Install-User -Credential $testMemberCred

    try
    {
        # Test for group creation
        Set-TargetResource -GroupName $groupName -Ensure 'Present'
    
        $resource = Get-TargetResource -GroupName $groupName
        Assert-NotNull $resource
        Assert-Equal $groupName $resource.GroupName
        Assert-DscResourcePresent $resource

        # Test for group deletion
        Set-TargetResource -GroupName $groupName -Ensure 'Absent'
    
        $resource = Get-TargetResource -GroupName $groupName
        Assert-NotNull $resource
        Assert-Equal $groupName $resource.GroupName
        Assert-DscResourceAbsent $resource

        # Test for group creation with members
        Set-TargetResource -GroupName $groupName -Members $member -Ensure 'Present'

        $resource = Get-TargetResource -GroupName $groupName
        Assert-NotNull $resource
        Assert-Equal $groupName $resource.GroupName
        Assert-DscResourcePresent $resource

        $result = Test-TargetResource -GroupName $groupName -Members $member -Ensure 'Present'
        Assert-NotNull $result
        Assert-True $result
    }
    finally
    {
        Uninstall-User -Username $member
    }

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
            GroupName = 'CarbonTestGroup01'
            Ensure = $Ensure
        }
    }
}

function Test-ShouldRunThroughDsc
{
    $groupName = 'CarbonTestGroup01'

    # Test for group creation through DSC execution
    & ShouldCreateGroup -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError

    $result = Test-TargetResource -GroupName $groupName
    Assert-NotNull $result
    Assert-True $result

    # Test for group deletion through DSC execution
    & ShouldCreateGroup -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError

    $result = Test-TargetResource -GroupName $groupName
    Assert-NotNull $result
    Assert-False $result
}