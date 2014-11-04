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

function Test-ShouldSchedulePerMinuteTasks
{
    Assert-TaskScheduled -InstallArguments @{ Minute = 5 } -AssertArguments @{ ScheduleType = 'Minute'; Modifier = 5 }
}

function Test-ShouldScheduleHourlyTasks
{
    Assert-TaskScheduled -InstallArguments @{ Hourly = 23 } -AssertArguments @{ ScheduleType = 'Hourly'; Modifier = 23 }
}

function Test-ShouldScheduleDailyTasks
{
    Assert-TaskScheduled -InstallArguments @{ Daily = 29 } -AssertArguments @{ ScheduleType = 'Daily'; Modifier = 29;  }
}

function Test-ShouldScheduleWeeklyTasks
{
    Assert-TaskScheduled -InstallArguments @{ Weekly = 39 } -AssertArguments @{ ScheduleType = 'Weekly'; Modifier = 39; DayOfWeek = (Get-Date).DayOfWeek; }
}

function Test-ShouldScheduleWeeklyTasksOnSpecificDay
{
    Assert-TaskScheduled -InstallArguments @{ Weekly = 39; DayOfWeek = 'Sunday'; } -AssertArguments @{ ScheduleType = 'Weekly'; Modifier = 39; DayOfWeek = 'Sunday'; }
}

function Test-ShouldScheduleWeeklyTasksOnMultipleDays
{
    Assert-TaskScheduled -InstallArguments @{ Weekly = 39; DayOfWeek = @('Monday','Tuesday','Wednesday'); } -AssertArguments @{ ScheduleType = 'Weekly'; Modifier = 39; DayOfWeek = @('Monday','Tuesday','Wednesday'); }
}

function Test-ShouldScheduleMonthlyTasks
{
    Assert-TaskScheduled -InstallArguments @{ Monthly = $true; } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 1; DayOfMonth = 1; Month = @( 'January','February','March','April','May','June','July','August','September','October','November','December' ) }
}

function Test-ShouldScheduleMonthlyTasksOnSpecificDay
{
    Assert-TaskScheduled -InstallArguments @{ Monthly = $true; DayOfMonth = 13; } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 1; DayOfMonth = 13; Month = @( 'January','February','March','April','May','June','July','August','September','October','November','December' ) }
}

function Test-ShouldScheduleLastDayOfTheMonthTask
{
    Assert-TaskScheduled -InstallArguments @{ LastDayOfMonth = $true; } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 'LastDay'; Month = @( 'January','February','March','April','May','June','July','August','September','October','November','December' ); }
}

function Test-ShouldScheduleLastDayOfTheMonthTaskInSpecificMonth
{
    Assert-TaskScheduled -InstallArguments @{ LastDayOfMonth = $true; Month = @( 'January' ); } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 'LastDay'; Month = @( 'January' ); }
}

function Test-ShouldScheduleLastDayOfTheMonthTaskInSpecificMonths
{
    Assert-TaskScheduled -InstallArguments @{ LastDayOfMonth = $true; Month = @( 'January','June' ); } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 'LastDay'; Month = @( 'January','June' ); }
}

function Test-ShouldScheduleForSpecificMonth
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 'January' ); } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January' ); DayOfMonth = 1; }
}

function Test-ShouldScheduleForSpecificMonthWithInteger
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 1 ); } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January' ); DayOfMonth = 1; }
}

function Test-ShouldScheduleForSpecificMonths
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 'January','April','July','October' ); } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January','April','July','October' ); DayOfMonth = 1; }
}

function Test-ShouldNotScheuleMonthlyTaskWithMonthParameter
{
    $result = Install-ScheduledTask -Name $taskName -Principal LocalService -TaskToRun 'notepad' -Month @( 'January','February','March','April','May','June','July','August','September','October','November','December' ) -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'to schedule a monthly task'
    Assert-Null $result
    Assert-False (Test-ScheduledTask -Name $taskName)
}

function Test-ShouldScheduleForSpecificMonthsOnSpecificDay
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 'January','April','July','October' ); DayOfMonth = 5;  } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January','April','July','October' ); DayOfMonth = 5; }
}


<#
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
#>

function Assert-TaskScheduled
{
    param(
        [hashtable]
        $InstallArguments,

        [hashtable]
        $AssertArguments
    )

    Set-StrictMode -Version Latest

    $InstallArguments['Name'] = $taskName
    $InstallArguments['TaskToRun'] = 'notepad'
    #$InstallArguments['Verbose'] = $true

    $AssertArguments['Name'] = $taskName
    $AssertArguments['TaskToRun'] = 'notepad'
    #$AssertArguments['Verbose'] = $true

    # Install to run as SYSTEM
    $task = Install-ScheduledTask -Principal System @InstallArguments
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask -Principal 'System' @AssertArguments

    $InstallArguments['Credential'] = $credential
    $AssertArguments['Credential'] = $credential

    $task = Install-ScheduledTask @InstallArguments
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments 

    # Install to start tomorrow
    $now = Get-Date
    # Check interval parameter
    $intervalSchedules = @( 'Daily', 'Weekly', 'Monthly', 'Month', 'LastDayOfMonth', 'WeekOfMonth', 'Once', 'OnEvent' )
    foreach( $intervalSchedule in $intervalSchedules )
    {
        if( $InstallArguments.ContainsKey( $intervalSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -Interval 37
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -Interval 37
            break
        }
    }

    $startTimeSchedules = @( 'Daily', 'Weekly', 'Monthly', 'Month', 'LastDayOfMonth', 'WeekOfMonth', 'Once' )
    foreach( $startTimeSchedule in $startTimeSchedules )
    {
        if( $InstallArguments.ContainsKey( $startTimeSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -StartTime '23:06'
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -StartTime '23:06'
            break
        }
    }

    $task = Install-ScheduledTask @InstallArguments -StartDate $now.AddDays(1)
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -StartDate $now.AddDays(1)

    $durationSchedules = @( 'Minute', 'Daily', 'Weekly', 'Monthly', 'LastDayOfMonth', 'WeekOfMonth', 'Once' )
    foreach( $durationSchedule in $durationSchedules )
    {
        if( $InstallArguments.ContainsKey( $durationSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -Duration '5:00'
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -Duration '5:00'
            break
        }
    }

    $endDateSchedules = @( 'Daily', 'Weekly', 'Monthly', 'LastDayOfMonth', 'WeekOfMonth' )
    foreach( $endDateSchedule in $endDateSchedules )
    {
        if( $InstallArguments.ContainsKey( $endDateSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -EndDate (Get-Date).AddYears(1)
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -EndDate (Get-Date).AddYears(1)
            break
        }
    }

    $endTimeSchedules = @( 'Minute', 'Hourly', 'Daily', 'Weekly', 'Monthly', 'LastDayOfMonth', 'WeekOfMonth', 'Once' )
    foreach( $endTimeSchedule in $endTimeSchedules )
    {
        if( $InstallArguments.ContainsKey( $endTimeSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -EndTime '23:06'
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -EndTime '23:06'
            break
        }
    }

    # Install as interactive
    $task = Install-ScheduledTask @InstallArguments -Interactive
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -Interactive

    # Install as no password
    $task = Install-ScheduledTask @InstallArguments -NoPassword
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -NoPassword

    # Install as highest run level
    $task = Install-ScheduledTask @InstallArguments -HighestAvailableRunLevel
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -HighestAvailableRunLevel

    $delaySchedules = @( 'OnStart', 'OnLogon', 'OnEvent' )
    foreach( $delaySchedule in $delaySchedules )
    {
        if( $InstallArguments.ContainsKey( $delaySchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -Delay '00:01:30'
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -Delay '00:01:30'
            break
        }
    }


}

function Assert-ScheduledTask
{
    [CmdletBinding()]
    param(
        $Name,
        $TaskToRun,
        $Credential,
        $Principal,
        $TaskXmlPath,
        $ScheduleType,
        $Modifier,
        [int[]]
        $DayOfMonth,
        [DayOfWeek[]]
        $DayOfWeek,
        [Carbon.TaskScheduler.Month[]]
        $Months,
        [TimeSpan]
        $IdleTime,
        [TimeSpan]
        $StartTime,
        $Interval,
        [TimeSpan]
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
        $HighestAvailableRunLevel,
        $Delay
    )

    Set-StrictMode -Version 'Latest'

    Assert-True (Test-ScheduledTask -Name $Name)

    $task = Get-ScheduledTask -Name $Name
    $task | Format-List | Out-String | Write-Verbose
    $schedule = $task.Schedules[0]
    $schedule | Format-List | Out-String | Write-Verbose

    Assert-NotNull $task
    schtasks /query /fo list /v /tn $task.FullName | Write-Verbose
    schtasks /query /xml /tn $task.FullName | Where-Object { $_ } | Write-Verbose
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
        Assert-True $task.HighestAvailableRunLevel
    }
    else
    {
        Assert-False $task.HighestAvailableRunLevel
    }

    if( $Interactive )
    {
        Assert-True $task.Interactive
    }
    else
    {
        Assert-False $task.Interactive
    }

    if( $NoPassword )
    {
        Assert-True $task.NoPassword
    }
    else
    {
        Assert-False $task.NoPassword
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

    if( $PSBoundParameters.ContainsKey('DayOfMonth') )
    {
        Assert-Equal ($DayOfMonth -join ',') ($schedule.Days -join ',') 'Days'
    }
    else
    {
        Assert-Empty $schedule.Days ('Days: {0}' -f ($schedule.Days -join ','))
    }

    if( $PSBoundParameters.ContainsKey('DayOfWeek') )
    {
        Assert-Equal ($DayOfWeek -join ',') ($schedule.DaysOfWeek -join ',') 'DaysOfWeek'
    }
    else
    {
        Assert-Empty $schedule.DaysOfWeek ('DaysOfWeek: {0}' -f ($schedule.DaysOfWeek -join ','))
    }

    if( $PSBoundParameters.ContainsKey('Months') )
    {
        Assert-Equal ($Months -join ', ') ($schedule.Months -join ', ')'Months'
    }
    else
    {
        Assert-Empty $schedule.Months ('Months: {0}' -f ($schedule.Months -join ','))
    }

    if( $PSBoundParameters.ContainsKey('StartDate') )
    {
        Assert-Equal $StartDate.ToString('d') $schedule.StartDate 'StartDate'
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

    if( $StopAtEnd )
    {
        Assert-True $schedule.StopAtEnd
    }
    else
    {
        Assert-False $schedule.StopAtEnd
    }

    if( $PSBoundParameters.ContainsKey('Interval') )
    {
        Assert-Equal $Interval $schedule.Interval 'Interval'
    }
    else
    {
        if( (@('Daily','Weekly','Monthly') -contains $schedule.ScheduleType) -and ($PSBoundParameters.ContainsKey('EndTime') -or $PSBoundParameters.ContainsKey('Duration')) )
        {
            Assert-Equal 10 $schedule.Interval 'Interval'
        }
        else
        {
            Assert-Equal 0 $schedule.Interval 'Interval'
        }
    }

    $today = Get-Date
    $today = Get-Date -Year $today.Year -Month $today.Month -Day $today.Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0

    if( $PSBoundParameters.ContainsKey('StartTime') )
    {
        $expectedStartTime = $today + $StartTime
        Assert-Equal $expectedStartTime.ToString('h:mm:ss tt') $schedule.StartTime 'StartTime'
    }
    else
    {
        Assert-Equal $task.CreateDate.ToString('h:mm:00 tt') $schedule.StartTime 'StartTime'
    }

    if( $PSBoundParameters.ContainsKey('EndTime') )
    {
        Assert-Equal $EndTime $schedule.EndTime
    }
    else
    {
        Assert-Equal ([TimeSpan]::Zero) $schedule.EndTime
    }

    if( $PSBoundParameters.ContainsKey('EndDate') )
    {
        Assert-Equal $EndDate.ToString("d") $schedule.EndDate
    }

    if( $PSBoundParameters.ContainsKey('Delay') )
    {
        Fail 'I don''t know how to check delay.'
    }
}