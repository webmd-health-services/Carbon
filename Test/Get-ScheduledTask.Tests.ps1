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


& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

Describe 'Get-ScheduledTask' {
    function Assert-ScheduledTaskEqual
    {
        param(
            $Expected,
            $Actual
        )
        
        Write-Debug ('{0} <=> {1}' -f $Expected.TaskName,$Actual.TaskName)
        $randomNextRunTimeTasks = @{
                                        '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser' = $true;
                                        '\Microsoft\Windows\Application Experience\ProgramDataUpdater' = $true;
                                        '\Microsoft\Windows\Defrag\ScheduledDefrag' = $true;
                                        '\Microsoft\Windows\Desired State Configuration\Consistency' = $true;
                                        '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem' = $true;
                                        '\Microsoft\Windows\Registry\RegIdleBackup' = $true;
                                        '\Microsoft\Windows\RAC\RacTask' = $true;
                                        '\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerCeipAssistant' = $true;
                                        '\Microsoft\Windows\Data Integrity Scan\Data Integrity Scan' = $true;
                                        '\Microsoft\Windows\TaskScheduler\Regular Maintenance' = $true;
                                        '\Microsoft\Windows\WindowsUpdate\Scheduled Start' = $true;
                                        '\Microsoft\Windows\WindowsUpdate\Scheduled Start With Network' = $true;
                                        '\Microsoft\Office\Office 15 Subscription Heartbeat' = $true;
                                        '\Microsoft\Windows\Windows Activation Technologies\ValidationTaskDeadline' = $true;
                                        '\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerRoleCollector' = $true;
                                        '\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerRoleUsageCollector' = $true;
                                        '\Microsoft\Windows\WS\WSRefreshBannedAppsListTask' = $true;
                                        '\Microsoft\Windows\Device Information\Device' = $true;
                                        '\Microsoft\Windows\UpdateOrchestrator\Refresh Settings' = $true;
                                    }
        $scheduleProps = @(
                               'Last Result',
                               'Stop Task If Runs X Hours And X Mins',
                               'Schedule',
                               'Schedule Type',
                               'Start Time',
                               'Start Date',
                               'End Date',
                               'Days',
                               'Months',
                               'Repeat: Every',
                               'Repeat: Until: Time',
                               'Repeat: Until: Duration',
                               'Repeat: Stop If Still Running'
                         )
    
        foreach( $property in (Get-Member -InputObject $Expected -MemberType NoteProperty) )
        {
            $columnName = $property.Name
            if( $scheduleProps -contains $columnName )
            {
                continue
            }
            
            $propertyName = $columnName -replace '[^A-Za-z0-9_]',''
    
            Write-Debug ('  {0} <=> {1}' -f $propertyName,$columnName)
            $failMsg = '{0}; column {1}; property {2}' -f $Actual.FullName,$columnName,$propertyName
            if( $propertyName -eq 'TaskName' )
            {
                $name = Split-Path -Leaf -Path $Expected.TaskName
                $path = Split-Path -Parent -Path $Expected.TaskName
                if( $path -ne '\' )
                {
                    $path = '{0}\' -f $path
                }
                $Actual.TaskName | Should -Be $name -Because ('{0}  TaskName' -f $task.FullName) 
                $Actual.TaskPath | Should -Be $path -Because ('{0}  TaskPath' -f $task.FullName)
            }
            elseif( $propertyName -eq 'NextRunTime' -and $randomNextRunTimeTasks.ContainsKey($task.FullName) )
            {
                # This task's next run time changes every time you retrieve it.
                continue
            }
            else
            {
                $because = '{0}  {1}' -f $task.FullName,$propertyName
                ($Actual | Get-Member -Name $propertyName) | Should -Not -BeNullOrEmpty -Because $because
                $expectedValue = $Expected.$columnName
                if( $propertyName -eq 'TaskToRun' )
                {
                    $expectedValue = $expectedValue.TrimEnd()

                    if( $expectedValue -like '*"*' )
                    {
                        $rawXml = schtasks /query /xml /tn $Expected.TaskName | Where-Object { $_ }
                        $rawXml = $rawXml -join [Environment]::NewLine
                        Write-Debug -Message $rawXml
                        $taskxml = [xml]$rawXml
                        $task = $taskxml.Task
                        if( ($task | Get-Member -Name 'Actions') -and ($task.Actions | Get-Member -Name 'Exec') )
                        {
                            $expectedValue = $taskXml.Task.Actions.Exec.Command
                            if( ($taskxml.Task.Actions.Exec | Get-Member 'Arguments') -and  $taskXml.Task.Actions.Exec.Arguments )
                            {
                                $expectedValue = '{0} {1}' -f $expectedValue,$taskxml.Task.Actions.Exec.Arguments
                            }
                        }
                    }
                }
                Write-Debug ('    {0} <=> {1}' -f $Actual.$propertyName,$expectedValue)
                ($Actual.$propertyName) | Should -Be $expectedValue -Because $because
            }
        }
    
    
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should get scheduled tasks' {
        schtasks /query /v /fo csv | 
            ConvertFrom-Csv | 
            Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' } | 
            ForEach-Object {
                $expectedTask = $_
                $task = Get-ScheduledTask -Name $expectedTask.TaskName
                $task | Should Not BeNullOrEmpty
    
                Assert-ScheduledTaskEqual $expectedTask $task
            }
    }
    
    It 'should get schedules' {
        $multiScheduleTasks = Get-ScheduledTask | Where-Object { $_.Schedules.Count -gt 1 }
    
        $multiScheduleTasks | Should Not BeNullOrEmpty
    
        $taskProps = @(
                            'HostName',
                            'TaskName',
                            'Next Run Time',
                            'Status',
                            'Logon Mode',
                            'Last Run Time',
                            'Author',
                            'Task To Run',
                            'Start In',
                            'Comment',
                            'Scheduled Task State',
                            'Idle Time',
                            'Power Management',
                            'Run As User',
                            'Delete Task If Not Rescheduled'
                     )
        foreach( $multiScheduleTask in $multiScheduleTasks )
        {
            $expectedSchedules = schtasks /query /v /fo csv /tn $multiScheduleTask.FullName | ConvertFrom-Csv
            $scheduleIdx = 0
            foreach( $expectedSchedule in $expectedSchedules )
            {
                $actualSchedule = $multiScheduleTask.Schedules[$scheduleIdx++]
                $actualSchedule | Should BeOfType ([Carbon.TaskScheduler.ScheduleInfo])
            }
        }
    }

    It 'should support wildcards' {
        $expectedTask = schtasks /query /fo list | 
                            Where-Object { $_ -match '^TaskName: +(.*)$' } | 
                            ForEach-Object { $Matches[1] } |
                            Select-Object -First 1
        $expectedTask | Should Not BeNullOrEmpty
        $wildcard = ('*{0}*' -f $expectedTask.Substring(1,$expectedTask.Length - 2))
        $task = Get-ScheduledTask -Name $wildcard
        $task | Should Not BeNullOrEmpty
        $task | Should BeOfType ([Carbon.TaskScheduler.TaskInfo])
        Join-Path -Path $task.TaskPath -ChildPath $task.TaskName | Should Be $expectedTask
    }
    
    It 'should get all scheduled tasks' {
        $expectedTasks = schtasks /query /v /fo csv | ConvertFrom-Csv | Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' } | Select-Object -Unique -Property 'TaskName'
        $actualTasks = Get-ScheduledTask
        $actualTasks.Count | Should Be $expectedTasks.Count
    }
    
}

Describe 'Get-ScheduledTask.when task does not exist' {
    $Global:Error.Clear()
    $result = Get-ScheduledTask -Name 'fjdskfjsdflkjdskfjsdklfjskadljfksdljfklsdjf' -ErrorAction SilentlyContinue
    It 'write no errors' {
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
    }

    It 'should return nothing' {
        $result | Should BeNullOrEmpty
    }
}
    
