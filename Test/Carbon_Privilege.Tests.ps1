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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

Describe 'Carbon_Privilege' {
    $UserName = 'CarbonDscTestUser'
    $Password = [Guid]::NewGuid().ToString()
    Install-User -UserName $UserName -Password $Password

    BeforeAll {
        Start-CarbonDscTestFixture 'Privilege'
    }
    
    BeforeEach {
        $Global:Error.Clear()
        Revoke-TestUserPrivilege
    }
    
    AfterEach {
        Revoke-TestUserPrivilege
    }
    
    function Revoke-TestUserPrivilege
    {
        if( (Get-Privilege -Identity $UserName) )
        {
            Revoke-Privilege -Identity $UserName -Privilege (Get-Privilege -Identity $UserName)
        }
    }
    
    AfterAll {
        Stop-CarbonDscTestFixture
    }
    
    It 'should grant privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $true
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $true
    }
    
    It 'should revoke privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $true
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $true
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Absent'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'should revoke all other privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight' -Ensure 'Present'
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight') | Should Be $true
    }
    
    It 'should revoke all privileges if ensure absent' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Ensure 'Absent'    
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'should revoke all privileges if privilege null' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege $null -Ensure 'Present'    
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'should revoke all privileges if privilege empty' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present'    
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight') | Should Be $false
        (Test-Privilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight') | Should Be $false
    }
    
    It 'gets no privileges' {
        $resource = Get-TargetResource -Identity $UserName -Privilege @()
        $resource | Should Not BeNullOrEmpty
        $resource.Identity | Should Be $UserName
        ,$resource.Privilege | Should BeOfType ([string[]])
        $resource.Privilege.Count | Should Be 0
        Assert-DscResourcePresent $resource
    }
    
    It 'gets current privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        $resource = Get-TargetResource -Identity $UserName -Privilege @()
        $resource | Should Not BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyBatchLogonRight' } | Should Not BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyNetworkLogonRight' } | Should Not BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }
    
    It 'should be absent if any privilege missing' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        $resource = Get-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight'
        $resource | Should Not BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyBatchLogonRight' } | Should Not BeNullOrEmpty
        ($resource.Privilege -contains 'SeDenyNetworkLogonRight') | Should Be $false
        Assert-DscResourceAbsent $resource
    }
    
    It 'should test no privileges' {
        (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent') | Should Be $true
    }
    
    It 'should test existing privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $false
    }
    
    It 'should test and not allow any privileges when absent' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent') | Should Be $false
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present') | Should Be $false
        Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present') | Should Be $false
    }
    
    It 'should test when user has extra privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyInteractiveLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $false
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $false
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
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $false
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $false
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $true
    }
    
    configuration DscConfiguration2
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = 'SeDenyBatchLogonRight';
                Ensure = 'Present';
            }
        }
    }
    
    configuration DscConfiguration3
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Ensure = 'Absent';
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration2 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
    
        & DscConfiguration3 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should Be $true
    }
    
    configuration DscConfiguration4
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = 'SeDenyBatchLogonRight';
                Ensure = 'Present';
            }
        }
    }
    
    configuration DscConfiguration5
    {
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Privilege set
            {
                Identity = $UserName;
                Privilege = $null;
                Ensure = 'Present';
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration2 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $true
    
        & DscConfiguration3 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should Be $false

        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Privilege' } | Should Not BeNullOrEmpty
    }
    
}
