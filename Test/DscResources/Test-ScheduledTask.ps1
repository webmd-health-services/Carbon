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
$credential = New-Credential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
$tempDir = $null
$taskForUser = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\ScheduledTasks\task.xml' -Resolve) -Raw
$taskForUser = $taskForUser -replace '<UserId>[^<]+</UserId>',('<UserId>{0}</UserId>' -f $credential.UserName)
$taskForSystem = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\ScheduledTasks\task_with_principal.xml' -Resolve) -Raw
$taskName = 'CarbonDscScheduledTask'

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'ScheduledTask'
    Install-User -UserName $credential.UserName -Password $credential.GetNetworkCredential().Password
}

function Start-Test
{
}

function Stop-Test
{
    Uninstall-ScheduledTask -Name $taskName
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldGetExistingTasks
{
    Get-ScheduledTask | ForEach-Object {
        $expectedXml = schtasks /query /xml /tn $_.FullName | Where-Object { $_ }
        $expectedXml = $expectedXml -join ([Environment]::NewLine) 

        $resource = Get-TargetResource -Name $_.FullName
        Assert-NoError
        Assert-NotNull $resource
        Assert-Equal $_.FullName $resource.TaskName
        Assert-Equal $_.RunAsUser $resource.RunAsUser ('task {0}' -f $_.FullName)
        Assert-Equal $expectedXml $resource.TaskXml
        Assert-DscResourcePresent $resource
    }
}

function Test-ShouldGetNonExistentTask
{
    $name = [Guid]::NewGuid().ToString()
    $resource = Get-TargetResource -Name $name
    Assert-NoError
    Assert-NotNull $resource
    Assert-Equal $name $resource.TaskName
    Assert-Empty $resource.TaskXml
    Assert-Empty $resource.RunAsUser
    Assert-DscResourceAbsent $resource
}
    
function Test-ShouldInstallTaskForUser
{
    Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
    Assert-NoError
    $resource = Get-TargetResource -Name $taskName
    Assert-NotNull $resource
    Assert-Equal $taskName $resource.TaskName
    Assert-Equal $taskForUser $resource.TaskXml
    Assert-Equal $credential.UserName $resource.RunAsUser
    Assert-DscResourcePresent $resource
}

function Test-ShouldInstallTaskForSystemPrincipal
{
    Set-TargetResource -Name $taskName -TaskXml $taskForSystem
    Assert-NoError
    $resource = Get-TargetResource -Name $taskName
    Assert-NotNull $resource
    Assert-Equal $taskName $resource.TaskName
    Assert-Equal $taskForSystem $resource.TaskXml
    Assert-Equal 'System' $resource.RunAsUser
    Assert-DscResourcePresent $resource
}

function Test-ShouldReinstallTask
{
    Set-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential
    Set-TargetResource -Name $taskName -TaskXml $taskForSystem
    $resource = Get-TargetResource -Name $taskName
    Assert-DscResourcePresent $resource
    Assert-Equal 'System' $resource.RunAsUser
}

function Test-ShouldUninstallTask
{
    Set-TargetResource -Name $taskName -TaskXml $taskForSystem
    $resource = Get-TargetResource -Name $taskName
    Assert-NotNull $resource
    Assert-DscResourcePresent $resource
    
    Set-TargetResource -Name $taskName -Ensure Absent
    $resource = Get-TargetResource -Name $taskName
    Assert-DscResourceAbsent $resource
}

function Test-ShouldTestPresent
{
    Assert-False (Test-TargetResource -Name $taskName -TaskXml $taskForSystem)
    Set-TargetResource -Name $taskName -TaskXml $taskForSystem
    Assert-True (Test-TargetResource -Name $taskName -TaskXml $taskForSystem)
    Assert-False (Test-TargetResource -Name $taskName -TaskXml $taskForUser)
    Assert-False (Test-TargetResource -Name $taskName -TaskXml $taskForUser -TaskCredential $credential)
}

function Test-ShouldWriteVerboseMessageCorrectly
{
    Set-TargetResource -Name $taskName -TaskXml $taskForSystem
    Assert-False (Test-TargetResource -Name $taskName -TaskXml '<Task />')
}

function Test-ShouldTestAbsent
{
    Assert-True (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure Absent)
    Set-TargetResource -Name $taskName -TaskXml $taskForSystem
    Assert-False (Test-TargetResource -Name $taskName -Ensure Absent)
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

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-True (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure 'Present')
    Assert-False (Test-TargetResource -Name $taskName -Ensure 'Absent')

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-False (Test-TargetResource -Name $taskName -TaskXml $taskForSystem -Ensure 'Present')
    Assert-True (Test-TargetResource -Name $taskName -Ensure 'Absent')
}
