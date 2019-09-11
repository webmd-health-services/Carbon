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

Describe 'Get-ScheduledTask' {
    function Assert-ScheduledTaskEqual
    {
        param(
            $Expected,
            $Actual
        )
        
        Write-Debug ('{0} <=> {1}' -f $Expected.TaskName,$Actual.TaskName)
        $randomNextRunTimeTasks = @{
                                        '\Microsoft\Office\Office 15 Subscription Heartbeat' = $true;
                                        '\OneDrive Standalone Update Task-S-1-5-21-1225507754-3068891322-2807220505-500' = $true;
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
            elseif( $propertyName -in @( 'NextRunTime', 'LastRuntime' ) -and ($task.FullName -like '\Microsoft\Windows\*' -or $randomNextRunTimeTasks.ContainsKey($task.FullName)) )
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
                        $actualTask = Get-CScheduledTask -Name $Expected.TaskName -AsComObject
                        if( -not $actualTask.Xml )
                        {
                            Write-Error -Message ('COM object for task "{0}" doesn''t have an XML property or the property doesn''t have a value.' -f $Expected.TaskName)
                        }
                        else
                        {
                            Write-Debug -Message $actualTask.Xml
                            $taskxml = [xml]$actualTAsk.Xml
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
                }
                Write-Debug ('    {0} <=> {1}' -f $Actual.$propertyName,$expectedValue)
                ($Actual.$propertyName) | Should -Be $expectedValue -Because $because
            }
        }
    
    
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should get each scheduled task' {
        schtasks /query /v /fo csv | 
            ConvertFrom-Csv | 
            Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' } | 
            Where-Object { $_.TaskName -notlike '*Intel*' -and $_.TaskName -notlike '\Microsoft\*' } |  # Some Intel scheduled tasks have characters in their names that don't play well.
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
        $expectedTask = Get-CScheduledTask -AsComObject | Select-Object -First 1
        $expectedTask | Should -Not -BeNullOrEmpty
        $wildcard = ('*{0}*' -f $expectedTask.Path.Substring(1,$expectedTask.Path.Length - 2))
        $task = Get-ScheduledTask -Name $wildcard
        $task | Should -Not -BeNullOrEmpty
        $task | Should -BeOfType ([Carbon.TaskScheduler.TaskInfo])
        Join-Path -Path $task.TaskPath -ChildPath $task.TaskName | Should Be $expectedTask.Path
    }
}

Describe 'Get-ScheduledTask.when getting all tasks' {
    It 'should get all scheduled tasks' {
        $expectedTasks = Get-CScheduledTask -AsComObject | Measure-Object
        $actualTasks = Get-ScheduledTask
        $actualTasks.Count | Should -Be $expectedTasks.Count
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
    
