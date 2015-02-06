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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force
$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'Privilege'
    Install-User -UserName $UserName -Password $Password
}

function Start-Test
{
    Revoke-TestUserPrivilege
}

function Stop-Test
{
    Revoke-TestUserPrivilege
}

function Revoke-TestUserPrivilege
{
    if( (Get-Privilege -Identity $UserName) )
    {
        Revoke-Privilege -Identity $UserName -Privilege (Get-Privilege -Identity $UserName)
    }
}

function Stop-TestFixture
{
    Uninstall-User -UserName $UserName
    Stop-CarbonDscTestFixture
}

function Test-ShouldGrantPrivilege
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
    Assert-True (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight')
    Assert-True (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight')
}

function Test-ShouldRevokePrivilege
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
    Assert-True (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight')
    Assert-True (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight')
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Absent'
    Assert-False (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight')
    Assert-False (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight')
}

function Test-ShouldRevokeAllOtherPrivileges
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight' -Ensure 'Present'
    Assert-False (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight')
    Assert-False (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight')
    Assert-True (Test-Privilege -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight')
}

function Test-GetsNoPrivileges
{
    $resource = Get-TargetResource -Identity $UserName -Privilege @()
    Assert-NotNull $resource
    Assert-Equal $UserName $resource.Identity
    Assert-Is $resource.Privilege ([string[]])
    Assert-Equal 0 $resource.Privilege.Count
    Assert-DscResourcePresent $resource
}

function Test-GetsCurrentPrivileges
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
    $resource = Get-TargetResource -Identity $UserName -Privilege @()
    Assert-NotNull $resource
    Assert-Contains $resource.Privilege 'SeDenyBatchLogonRight'
    Assert-Contains $resource.Privilege 'SeDenyNetworkLogonRight'
    Assert-DscResourceAbsent $resource
}

function Test-ShouldBeAbsentIfAnyPrivilegeMissing
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
    $resource = Get-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight'
    Assert-NotNull $resource
    Assert-Contains $resource.Privilege 'SeDenyBatchLogonRight'
    Assert-False ($resource.Privilege -contains 'SeDenyNetworkLogonRight')
    Assert-DscResourceAbsent $resource
}

function Test-ShouldTestNoPrivileges
{
    Assert-True (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present')
    Assert-True (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent')
}

function Test-ShouldTestExistingPrivileges
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
    Assert-True (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present')
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent')
}

function Test-ShouldTestAndNotAllowAnyPrivilegesWhenAbsent
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent')
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present')
    Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent'
    Assert-True (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent')
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present')
}

function Test-ShouldTestWhenUserHasExtraPrivilege
{
    Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyInteractiveLogonRight' -Ensure 'Present'
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent')
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present')
}

configuration DscConfiguration
{
    param(
        $Ensure
    )

    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        Carbon_Privilege set
        {
            Identity = $UserName;
            Privilege = 'SeDenyBatchLogonRight';
            Ensure = $Ensure;
        }
    }
}

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError
    Assert-True (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present')
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent')

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError
    Assert-False (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present')
    Assert-True (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent')
}
