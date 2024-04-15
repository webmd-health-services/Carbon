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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve) -ForDsc

    $script:psModulePath = $env:PSModulePath

    if (-not (Get-Module -Name 'Carbon' -ListAvailable))
    {
        $env:PSModulePath =
        "$(Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve)$([IO.Path]::PathSeparator)$($env:PSModulePath)"
    }

    $script:credential = New-CCredential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
    Install-CUser -Credential $script:credential
    $script:sid = Resolve-CIdentity -Name $script:credential.UserName -NoWarn | Select-Object -ExpandProperty 'Sid'
    $script:tempDir = $null
    $taskXmlPath = Join-Path -Path $PSScriptRoot -ChildPath 'ScheduledTasks\task.xml' -Resolve
    $script:taskForUser = Get-Content -Path $taskXmlPath -Raw
    $script:taskForUser = $script:taskForUser -replace '<UserId>[^<]+</UserId>',('<UserId>{0}</UserId>' -f $script:sid)
    $taskWithPrincipalXmlPath =
        Join-Path -Path $PSScriptRoot -ChildPath 'ScheduledTasks\task_with_principal.xml' -Resolve
    $script:taskForSystem = Get-Content -Path $taskWithPrincipalXmlPath -Raw
    $script:taskName = 'CarbonDscScheduledTask'

    Start-CarbonDscTestFixture 'ScheduledTask'
}

AfterAll {
    Stop-CarbonDscTestFixture
    Uninstall-CScheduledTask -Name $script:taskName -NoWarn
    $env:PSModulePath = $script:psModulePath
}

Describe 'Carbon_ScheduledTask' {
    # Windows 2012R2 returns different XML than what we put in so we need to make the resource smarter about its XML
    # difference detection.
    $os = Get-CimInstance Win32_OperatingSystem
    $skip = $os.Caption -like '*2012 R2*'

    BeforeEach {
        $Global:Error.Clear()
    }

    AfterEach {
        Uninstall-CScheduledTask -Name $script:taskName -NoWarn
    }

    It 'should get existing tasks' {
        Get-CScheduledTask -AsComObject -NoWarn |
            Select-Object -First 5 |
            ForEach-Object {
                $comTask = $expectedXml = Get-CScheduledTask -Name $_.Path -AsComObject -NoWarn
                $expectedXml = $comTask.Xml

                [string]$expectedCredential =
                    & {
                        $_.Definition.Principal.UserId
                        $_.Definition.Principal.GroupId
                    } |
                    Where-Object { $_ } |
                    Select-Object -First 1

                $resource = Get-TargetResource -Name $_.Path
                $Global:Error | Should -BeNullOrEmpty
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
        $Global:Error | Should -BeNullOrEmpty
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $name
        $resource.TaskXml | Should -BeNullOrEmpty
        $resource.TaskCredential | Should -BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }

    It 'should install task for system principal' {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        $Global:Error | Should -BeNullOrEmpty
        $resource = Get-TargetResource -Name $script:taskName
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $script:taskName

        if ($resource.TaskXml -ne $script:taskForSystem)
        {
            Write-Host "Expected:`n$($script:taskForSystem)"
            Write-Host "Actual:`n$($resource.TaskXml)"
        }
        $resource.TaskXml | Should -Match ([regex]::escape('<UserId>S-1-5-18</UserId>'))
        $resource.TaskCredential | Should -Match '\bSystem$'
        Assert-DscResourcePresent $resource
    }

    It 'should reinstall task' {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForUser -TaskCredential $script:credential
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        $resource = Get-TargetResource -Name $script:taskName
        Assert-DscResourcePresent $resource
        $resource.TaskCredential | Should -Match '\bSystem$'
    }

    It 'should uninstall task' {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        $resource = Get-TargetResource -Name $script:taskName
        $resource | Should -Not -BeNullOrEmpty
        Assert-DscResourcePresent $resource

        Set-TargetResource -Name $script:taskName -Ensure Absent
        $resource = Get-TargetResource -Name $script:taskName
        Assert-DscResourceAbsent $resource
    }

    It 'should test present' -Skip:$skip {
        Test-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem | Should -BeFalse
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        Test-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem | Should -BeTrue
        Test-TargetResource -Name $script:taskName -TaskXml $script:taskForUser | Should -BeFalse
        Test-TargetResource -Name $script:taskName -TaskXml $script:taskForUser -TaskCredential $script:credential |
            Should -BeFalse
    }

    It 'should write verbose message correctly' {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        (Test-TargetResource -Name $script:taskName -TaskXml '<Task />') | Should -BeFalse
    }

    It 'should test absent' {
        (Test-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem -Ensure Absent) | Should -BeTrue
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        (Test-TargetResource -Name $script:taskName -Ensure Absent) | Should -BeFalse
    }

    It 'should test task credential changes' {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem
        Test-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem -TaskCredential $script:credential |
            Should -BeFalse
    }

    It 'should test task credential canonical versus short username' -Skip:$skip {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForUser -TaskCredential $script:credential
        $username = "$([Environment]::MachineName)\$($script:credential.UserName)"
        $credWithFullUserName = New-Credential -UserName $username -Password 'snafu'
        Test-TargetResource -Name $script:taskName -TaskXml $script:taskForUser -TaskCredential $credWithFullUserName |
            Should -BeTrue
    }

    $skipDscTest =
        (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' -and $PSVersionTable['PSVersion'].Major -eq 7

    It 'should run through DSC' -Skip:($skipDscTest -or $skip) {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest\ScheduledTask.ps1' -Resolve)

        $configArgs = @{
            Name = $script:taskName;
            TaskXml = $script:taskForSystem;
            OutputPath = $CarbonDscOutputRoot;
        }

        & CScheduledTaskTestCfg -Ensure 'Present' @configArgs
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force

        $Global:Error | Should -BeNullOrEmpty
        (Test-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem -Ensure 'Present') | Should -BeTrue
        (Test-TargetResource -Name $script:taskName -Ensure 'Absent') | Should -BeFalse

        & CScheduledTaskTestCfg -Ensure 'Absent' @configArgs
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error | Should -BeNullOrEmpty
        (Test-TargetResource -Name $script:taskName -TaskXml $script:taskForSystem -Ensure 'Present') | Should -BeFalse
        (Test-TargetResource -Name $script:taskName -Ensure 'Absent') | Should -BeTrue

        $result = Get-DscConfiguration
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_ScheduledTask' } | Should -Not -BeNullOrEmpty
    }

    It 'should install task for user' {
        Set-TargetResource -Name $script:taskName -TaskXml $script:taskForUser -TaskCredential $script:credential
        $Global:Error | Should -BeNullOrEmpty
        $resource = Get-TargetResource -Name $script:taskName
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $script:taskName
        $resource.TaskXml | Should -Match "<UserId>$($script:credential.UserName)|$($script:sid)</UserId>"
        $resource.TaskCredential | Should -Match "\b$([regex]::escape($script:credential.UserName))$"
        Assert-DscResourcePresent $resource
    }
}
