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

$taskName = 'CarbonInstallScheduledTask'
$credential = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    Install-User -Username 'CarbonInstallSchedul' -Password 'a1b2c34d!' -Description 'Test user for running scheduled tasks.'
    $credential = New-Credential -User 'CarbonInstallSchedul' -Password 'a1b2c34d!'
}

function Start-Test
{
    Uninstall-ScheduledTask -Name $taskName
}

function Stop-Test
{
    Uninstall-ScheduledTask -Name $taskName
}

function Test-ShouldSchedulePerMinuteTask
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -Minute 1 -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'Minute' -Modifier 1

    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -Minute 13 -Duration '3:03' -StopAtEnd -Interactive -HighestAvailableRunLevel -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'Minute' -Modifier 13 -Duration '3:03' -StopAtEnd -Interactive -HighestAvailableRunLevel
}

function Test-ShouldScheduleDailyTasks
{
    foreach( $scheduleType in @('Minute','Hourly') )
    {
        Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType $scheduleType -Verbose
        Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType $scheduleType -Modifier 1
        Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType $scheduleType -Modifier 13 -Verbose
        Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType $scheduleType -Modifier 13
    }
}

function Test-ShouldScheduleDailyTask
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Daily -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Daily -Modifier 1
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Daily -Modifier 13 -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Daily -Modifier 13
}

function Test-ShouldScheduleWeeklyTask
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Weekly -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Weekly -Modifier 1 -Days (Get-Date).DayOfWeek

    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Weekly -Modifier 13 -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Weekly -Modifier 13 -Days (Get-Date).DayOfWeek
}

function Test-ShouldScheduleMonthlyTask
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Monthly -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Monthly -Days 1 -Months ([Carbon.TaskScheduler.Months]::All)
}

function Test-ShouldScheduleEveryNMonths
{
    $months = @{
                    1 = [Carbon.TaskScheduler.Months]::All;
                    2 = @( 'February', 'April', 'June', 'August', 'October', 'December' );
                    3 = @( 'March', 'June', 'September', 'December' );
                    4 = @( 'April', 'August', 'December' );
                    5 = @( 'May', 'October' );
                    6 = @( 'June', 'December' );
                    7 = @( 'July' );
                    8 = @( 'August' );
                    9 = @( 'September' );
                    10 = @( 'October' );
                    11 = @( 'November' );
                    12 = @( 'December' );
                }
    foreach( $modifier in @( 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ) )
    {
        Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Monthly -Modifier $modifier -Months All -Verbose
        Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Monthly -Modifier $modifier -Days 1 -Months $months[$modifier]
    }
}

function Test-ShouldRunTheLastDayOfTheMonth
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Monthly -Modifier 'LastDay' -Months ([Carbon.TaskScheduler.Months]::All) -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType Monthly -Modifier 'LastDay' -Months ([Carbon.TaskScheduler.Months]::All)
}

function Test-ShouldScheduleOnceTriggers
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'Once' -StartTime '23:00' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'Once' -StartTime '23:00'
}

function Test-ShouldScheduleBootTriggers
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnStart' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnStart'
}

function Test-ShouldScheduleLogonTriggers
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnStart' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnStart'
}

function Test-ShouldScheduleOnIdleTriggers
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnIdle' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnIdle'
}

function Test-ShouldScheduleOnEventTriggers
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnEvent' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad' -Credential $credential -ScheduleType 'OnEvent'
}

function Test-ShouldScheduleEveryFiveMinutes
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'calc.exe' -ScheduleType Minute -Modifier 5 -StartTime '12:00' -EndTime '14:00' -StartDate '6/6/2006' -EndDate '6/6/2006' -Credential $credential -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'calc.exe' -ScheduleType Minute  -Modifier 5 -StartTime '12:00' -EndTime '14:00' -StartDate '6/6/2006' -EndDate '6/6/2006' -Credential $credential
}

function Test-ShouldScheduleMonthlyTasks
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'C:\Windows\system32\freecell.exe' -ScheduleType Monthly -Modifier First -Days 'Sun' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'C:\Windows\system32\freecell.exe' -ScheduleType Monthly -Modifier First -Days 'First SUN'
}

function Test-ShouldScheduleWeeklyTaskForSpecificDays
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'notepad.exe' -Credential $credential -ScheduleType Weekly -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'notepad.exe' -Credential $credential -ScheduleType Weekly -Days 'THU'
}

function Test-ShouldScheduleMinuteTask
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'C:\Windows\system32\notepad.exe' -ScheduleType Minute -Modifier 5 -StartTime '18:30' -Credential $credential -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'C:\Windows\system32\notepad.exe' -ScheduleType 'One Time Only, Minute' -Modifier 5 -StartTime '18:30' -Credential $credential
}

function Test-ShouldScheduleDailyTaskWithSchedule
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'C:\freecell' -ScheduleType Daily -StartTime '12:00' -EndTime '14:00' -StopAtEnd -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'C:\freecell' -ScheduleType Daily -StartTime '12:00' -EndTime '14:00' -Days 'Every 1 day(s)' -StopAtEnd
}

function Test-ShouldScheduleEventLogTask
{
    Install-ScheduledTask -Name $taskName -TaskToRun 'wevtvwr.msc' -ScheduleType OnEvent -EventChannelName System -Modifier '*[Sytem/EventID=101]' -Verbose
    Assert-ScheduledTask -Name $taskName -TaskToRun 'wevtvwr.msc' -ScheduleType 'When an event occurs' -EventChannelName System -Modifier '*[Sytem/EventID=101]'
}

function Test-ShouldCreateV1Task
{
    # Write this.
    # V1 tasks can't be parsed correctly by Get-ScheduledTask, so it should always force a re-install of the task.
}

function Assert-ScheduledTask
{
    param(
        $Name,
        $TaskToRun,
        $Credential,
        $Principal,
        $TaskXmlPath,
        $ScheduleType,
        $Modifier,
        $Days,
        $Months,
        [TimeSpan]
        $IdleTime,
        [TimeSpan]
        $StartTime,
        $Interval,
        $EndTime,
        [TimeSpan]
        $Duration,
        [Switch]
        $StopAtEnd,
        [DateTime]
        $StartDate,
        [DateTime]
        $EndDate,
        $EventChannelName,
        [Switch]
        $Interactive,
        [Switch]
        $NoPassword,
        [Switch]
        $V1,
        [Switch]
        $HighestAvailableRunLevel,
        $Delay
    )

    Set-StrictMode -Version 'Latest'

    Assert-True (Test-ScheduledTask -Name $Name)

    $task = Get-ScheduledTask -Name $Name
    $schedule = $task.Schedules[0]

    Assert-NotNull $task
    schtasks /query /fo list /v /tn $task.FullName | Write-Host
    schtasks /query /xml /tn $task.FullName | Where-Object { $_ } | Write-Host
    Assert-Equal $TaskToRun $task.TaskToRun.Trim()

    if( $PSBoundParameters.ContainsKey('Credential') )
    {
        Assert-Equal $Credential.Username $task.RunAsUser 'RunAsUser'
    }
    elseif( $PSBoundParameters.ContainsKey('Principal') )
    {
        Assert-Equal $Principal $task.RunAsUser 'RunAsUser'
    }
    else
    {
        Assert-Equal 'SYSTEM' $task.RunAsUser 'RunAsUser'
    }

    if( $HighestAvailableRunLevel )
    {
        Assert-True $task.IsHighestAvailableRunLevel
    }
    else
    {
        Assert-False $task.IsHighestAvailableRunLevel
    }

    if( $Interactive )
    {
        Assert-True $task.IsInteractive
    }
    else
    {
        Assert-False $task.IsInteractive
    }

    if( $PSBoundParameters.ContainsKey('ScheduleType') )
    {
        Assert-Equal $ScheduleType $schedule.ScheduleType.Trim() 'ScheduleType'
    }
    else
    {
        Assert-Equal 'fubar' $schedule.ScheduleType 'ScheduleType'
    }

    if( $PSBoundParameters.ContainsKey( 'Modifier' ) )
    {
        Assert-Equal $Modifier $schedule.Modifier 'Modifier'
    }
    else
    {
        Assert-Equal '' $schedule.Modifier 'Modifier'
    }

    if( $PSBoundParameters.ContainsKey('Days') )
    {
        foreach( $day in $Days )
        {
            Assert-True ($schedule.Days -contains $day) ('Days missing {0}' -f $day)
        }
    }
    else
    {
        Assert-Null $schedule.Days 'Days'
    }

    if( $PSBoundParameters.ContainsKey('Months') )
    {
        Assert-Equal ($Months -join ', ') $schedule.Months 'Months'
    }
    else
    {
        Assert-Equal ([Carbon.TaskScheduler.Months]::None) $schedule.Months 'Months'
    }

    if( $PSBoundParameters.ContainsKey('StartDate') )
    {
        Assert-Equal $StartDate $schedule.StartDate 'StartDate'
    }
    else
    {
        $today = Get-Date
        Assert-Equal (Get-Date -Year $today.Year -Month $today.Month -Day $today.Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0) $Schedule.StartDate 'StartDate'
    }

    if( $PSBoundParameters.ContainsKey('Duration') )
    {
        Assert-Equal $Duration $schedule.RepeatUntilDuration 'Duration'
    }
    else
    {
        Assert-Equal '' $schedule.RepeatUntilDuration 'Duration'
    }

    if( $StopAtEnd )
    {
        Assert-True $schedule.StopAtEnd
    }
    else
    {
        Assert-False $schedule.StopAtEnd
    }

}