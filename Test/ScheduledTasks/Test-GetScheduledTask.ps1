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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
}

function Test-ShouldGetScheduledTasks
{
    schtasks /query /v /fo csv | ConvertFrom-Csv | Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' } | ForEach-Object {
        $expectedTask = $_
        $task = Get-ScheduledTask -Name $expectedTask.TaskName
        Assert-NotNull $task $expectedTask.TaskName

        Assert-ScheduledTaskEqual $expectedTask $task
    }
}

function Test-ShouldGetSchedules
{
    $multiScheduleTasks = Get-ScheduledTask | Where-Object { $_.Schedules.Count -gt 1 }

    Assert-NotNull $multiScheduleTasks

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
            foreach( $property in (Get-Member -InputObject $expectedSchedule -MemberType NoteProperty) )
            {
                $columnName = $property.Name
                if( $taskProps -contains $columnName )
                {
                    continue
                }

                $propertyName = $columnName -replace '[^A-Za-z0-9_]',''

                $failMsg = '{0}.Schedules[{1}]; column {2}; property {3}' -f $multiScheduleTask.FullName,($scheduleIdx - 1),$columnName,$propertyName
                Assert-NotNull ($actualSchedule | Get-Member -Name $propertyName) $failMsg
                Assert-Equal $expectedSchedule.$columnName $actualSchedule.$propertyName $failMsg
            }        
        }
    }
}

function Test-ShouldSupportWildcards
{
    $expectedTask = schtasks /query /v /fo csv | Select-Object -First 2 | ConvertFrom-Csv
    $task = Get-ScheduledTask -Name ('*{0}*' -f $expectedTask.TaskName.Substring(1,$expectedTask.TaskName.Length - 2))
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTaskEqual $expectedTask $task
}

function Test-ShouldGetAllScheduledTasks
{
    $expectedTasks = schtasks /query /v /fo csv | ConvertFrom-Csv | Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' } | Select-Object -Unique -Property 'TaskName'
    $actualTasks = Get-ScheduledTask
    Assert-Equal $expectedTasks.Count $actualTasks.Count
}

function Test-ShouldGetNonExistentTask
{
    Get-ScheduledTask -Name 'fjdskfjsdflkjdskfjsdklfjskadljfksdljfklsdjf' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
}

function Assert-ScheduledTaskEqual
{
    param(
        $Expected,
        $Actual
    )

    $randomNextRunTimeTasks = @{
                                    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser' = $true;
                                    '\Microsoft\Windows\Application Experience\ProgramDataUpdater' = $true;
                                    '\Microsoft\Windows\Defrag\ScheduledDefrag' = $true;
                                    '\Microsoft\Windows\Desired State Configuration\Consistency' = $true;
                                    '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem' = $true;
                                    '\Microsoft\Windows\Registry\RegIdleBackup' = $true;
                                    '\Microsoft\Windows\RAC\RacTask' = $true;
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

        $failMsg = '{0}; column {1}; property {2}' -f $Actual.FullName,$columnName,$propertyName
        if( $propertyName -eq 'TaskName' )
        {
            $name = Split-Path -Leaf -Path $Expected.TaskName
            $path = Split-Path -Parent -Path $Expected.TaskName
            if( $path -ne '\' )
            {
                $path = '{0}\' -f $path
            }
            Assert-Equal $name $Actual.TaskName $failMsg
            Assert-Equal $path $Actual.TaskPath $failMsg
        }
        elseif( $propertyName -eq 'NextRunTime' -and $randomNextRunTimeTasks.ContainsKey($task.FullName) )
        {
            # This task's next run time changes every time you retrieve it.
            continue
        }
        else
        {
            Assert-NotNull ($Actual | Get-Member -Name $propertyName) $failMsg
            Assert-Equal $Expected.$columnName $Actual.$propertyName $failMsg
        }
    }


}
