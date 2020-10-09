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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve) -ForDsc

$credential = New-Credential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
$sid = Resolve-CIdentity -Name $credential.UserName | Select-Object -ExpandProperty 'Sid'
$tempDir = $null
$taskForUser = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'ScheduledTasks\task.xml' -Resolve) -Raw
$taskForUser = $taskForUser -replace '<UserId>[^<]+</UserId>',('<UserId>{0}</UserId>' -f $sid)
$taskForSystem = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'ScheduledTasks\task_with_principal.xml' -Resolve) -Raw
$taskName = 'CarbonDscScheduledTask'

Start-CarbonDscTestFixture 'ScheduledTask'
Install-CUser -Credential $credential

try
{    
    function Init
    {
        Uninstall-CScheduledTask -Name $taskName
        $Global:Error.Clear()
    }

    Describe 'Carbon_ScheduledTask' {

        BeforeEach {
            Init
        }
    
        AfterEach {
            Init
        }
    
        It 'should get existing tasks' {
            Get-ScheduledTask -AsComObject |
                Select-Object -First 5 |
                 ForEach-Object {
                    $comTask = $expectedXml = Get-CScheduledTask -Name $_.Path -AsComObject
                    $expectedXml = $comTask.Xml

                    [string]$expectedCredential = & { $_.Definition.Principal.UserId ; $_.Definition.Principal.GroupId } | Where-Object { $_ } | Select-Object -First 1
    
                    $resource = Get-TargetResource -Name $_.Path
                    $Global:Error.Count | Should -Be 0
                    $resource | Should -Not -BeNullOrEmpty
                    $resource.Name | Should -Be $_.Path
                    $resource.TaskCredential | Should -Be $expectedCredential
                    $resource.TaskXml | Should -Be $expectedXml
                    Assert-DscResourcePresent $resource
                }
        }
    
        It 'should get non existent task' {
            $name = [Guid]::NewGuid().ToString()
            $resource = Get-TargetResource -Name $name
            $Global:Error.Count | Should -Be 0
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $name
            $resource.TaskXml | Should -BeNullOrEmpty
            $resource.TaskCredential | Should -BeNullOrEmpty
            Assert-DscResourceAbsent $resource
        }
        
        It 'should install task for system principal' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            $Global:Error.Count | Should -Be 0
            $resource = Get-TargetResource -Name $taskName
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $taskName
            $resource.TaskXml | Should -Be $taskForSystem
            $resource.TaskCredential | Should -Match '\bSystem$'
            Assert-DscResourcePresent $resource
        }
    
        It 'should reinstall task' {
            Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            $resource = Get-TargetResource -Name $taskName
            Assert-DscResourcePresent $resource
            $resource.TaskCredential | Should -Match '\bSystem$'
        }
    
        It 'should uninstall task' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            $resource = Get-TargetResource -Name $taskName
            $resource | Should -Not -BeNullOrEmpty
            Assert-DscResourcePresent $resource
        
            Set-TargetResource -Name $taskName -Ensure Absent
            $resource = Get-TargetResource -Name $taskName
            Assert-DscResourceAbsent $resource
        }
    
        It 'should test present' {
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem) | Should -Be $false
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem) | Should -Be $true
            (Test-TargetResource -Name $taskName -TaskXml $taskForUser) | Should -Be $false
            (Test-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential) | Should -Be $false
        }
    
        It 'should write verbose message correctly' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            (Test-TargetResource -Name $taskName -TaskXml '<Task />') | Should -Be $false
        }
    
        It 'should test absent' {
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure Absent) | Should -Be $true
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            (Test-TargetResource -Name $taskName -Ensure Absent) | Should -Be $false
        }
    
        It 'should test task credential changes' {
            Set-TargetResource -Name $taskName -TaskXml $taskForSystem
            Test-TargetResource -Name $taskName -TaskXml $taskForSystem -TaskCredential $credential | Should -Be $false            
        }
    
        It 'should test task credential canonical versus short username' {
            Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
            $credWithFullUserName = New-Credential -UserName ('{0}\{1}' -f [Environment]::MachineName,$credential.UserName) -Password 'snafu'
            Test-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credWithFullUserName | Should -Be $true            
        }
    }

    Describe 'Carbon_ScheduledTask.when run through DSC' {

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
    
        Init
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force

        It 'should run through dsc' {
            $Global:Error.Count | Should -Be 0
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure 'Present') | Should -Be $true
            (Test-TargetResource -Name $taskName -Ensure 'Absent') | Should -Be $false
    
            & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
            Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
            $Global:Error.Count | Should -Be 0
            (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure 'Present') | Should -Be $false
            (Test-TargetResource -Name $taskName -Ensure 'Absent') | Should -Be $true
            
            $result = Get-DscConfiguration
            $Global:Error.Count | Should -Be 0
            $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
            $result.PsTypeNames | Where-Object { $_ -like '*Carbon_ScheduledTask' } | Should -Not -BeNullOrEmpty
        }
    }

    Describe 'Carbon_ScheduledTask.when installing task for user' {
        Init
        Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
        It 'should install task for user' {
            $Global:Error.Count | Should -Be 0
            $resource = Get-TargetResource -Name $taskName
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $taskName
            $resource.TaskXml | Should -Be $taskForUser
            $resource.TaskCredential | Should -Match "\b$([regex]::escape($credential.UserName))$"
            Assert-DscResourcePresent $resource
        }
    
    }
}
finally
{
    Stop-CarbonDscTestFixture
    Uninstall-CScheduledTask -Name $taskName
}
