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

Describe 'Carbon_ScheduledTask' {

    $credential = New-Credential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
    $tempDir = $null
    $taskForUser = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'ScheduledTasks\task.xml' -Resolve) -Raw
    $taskForUser = $taskForUser -replace '<UserId>[^<]+</UserId>',('<UserId>{0}</UserId>' -f $credential.UserName)
    $taskForSystem = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'ScheduledTasks\task_with_principal.xml' -Resolve) -Raw
    $taskName = 'CarbonDscScheduledTask'

    Start-CarbonDscTestFixture 'ScheduledTask'
    Install-User -UserName $credential.UserName -Password $credential.GetNetworkCredential().Password

    try
    {    
        BeforeEach {
            $Global:Error.Clear()
        }
    
        AfterEach {
            Uninstall-ScheduledTask -Name $taskName
        }
    
        It 'should get existing tasks' {
            Get-ScheduledTask | ForEach-Object {
                $expectedXml = schtasks /query /xml /tn $_.FullName | Where-Object { $_ }
                $expectedXml = $expectedXml -join ([Environment]::NewLine) 
    
                $resource = Get-TargetResource -Name $_.FullName
                $Global:Error.Count | Should Be 0
                $resource | Should Not BeNullOrEmpty
                $resource.Name | Should Be $_.FullName
                $resource.TaskCredential | Should Be $_.RunAsUser
                $resource.TaskXml | Should Be $expectedXml
                Assert-DscResourcePresent $resource
            }
        }
    
        It 'should get non existent task' {
            $name = [Guid]::NewGuid().ToString()
            $resource = Get-TargetResource -Name $name
            $Global:Error.Count | Should Be 0
            $resource | Should Not BeNullOrEmpty
            $resource.Name | Should Be $name
            $resource.TaskXml | Should BeNullOrEmpty
            $resource.TaskCredential | Should BeNullOrEmpty
            Assert-DscResourceAbsent $resource
        }
        
        It 'should install task for user' {
            Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
            $Global:Error.Count | Should Be 0
            $resource = Get-TargetResource -Name $taskName
            $resource | Should Not BeNullOrEmpty
            $resource.Name | Should Be $taskName
            $resource.TaskXml | Should Be $taskForUser
            $resource.TaskCredential | Should Be $credential.UserName
            Assert-DscResourcePresent $resource
        }
    
        It 'should install task for system principal' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            $Global:Error.Count | Should Be 0
            $resource = Get-TargetResource -Name $taskName
            $resource | Should Not BeNullOrEmpty
            $resource.Name | Should Be $taskName
            $resource.TaskXml | Should Be $taskForSystem
            $resource.TaskCredential | Should Be 'System'
            Assert-DscResourcePresent $resource
        }
    
        It 'should reinstall task' {
            Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            $resource = Get-TargetResource -Name $taskName
            Assert-DscResourcePresent $resource
            $resource.TaskCredential | Should Be 'System'
        }
    
        It 'should uninstall task' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            $resource = Get-TargetResource -Name $taskName
            $resource | Should Not BeNullOrEmpty
            Assert-DscResourcePresent $resource
        
            Set-TargetResource -Name $taskName -Ensure Absent
            $resource = Get-TargetResource -Name $taskName
            Assert-DscResourceAbsent $resource
        }
    
        It 'should test present' {
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem) | Should Be $false
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem) | Should Be $true
            (Test-TargetResource -Name $taskName -TaskXml $taskForUser) | Should Be $false
            (Test-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential) | Should Be $false
        }
    
        It 'should write verbose message correctly' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            (Test-TargetResource -Name $taskName -TaskXml '<Task />') | Should Be $false
        }
    
        It 'should test absent' {
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure Absent) | Should Be $true
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            (Test-TargetResource -Name $taskName -Ensure Absent) | Should Be $false
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
                Carbon_ScheduledTask set
                {
                    Name = $taskName;
                    TaskXml = $taskForSystem;
                    Ensure = $Ensure;
                }
            }
        }
    
        It 'should run through dsc' {
            & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
            Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
            $Global:Error.Count | Should Be 0
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure 'Present') | Should Be $true
            (Test-TargetResource -Name $taskName -Ensure 'Absent') | Should Be $false
    
            & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
            Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
            $Global:Error.Count | Should Be 0
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure 'Present') | Should Be $false
            (Test-TargetResource -Name $taskName -Ensure 'Absent') | Should Be $true

            $result = Get-DscConfiguration
            $Global:Error.Count | Should Be 0
            $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
            $result.PsTypeNames | Where-Object { $_ -like '*Carbon_ScheduledTask' } | Should Not BeNullOrEmpty
        }
    
    }
    finally
    {
        Stop-CarbonDscTestFixture
    }
}