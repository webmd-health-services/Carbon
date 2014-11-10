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
d
$taskName = 'CarbonInstallScheduledTask'
$credential = $null
$AllMonths = @( 'January','February','March','April','May','June','July','August','September','October','November','December' )
$today = Get-Date
$today = New-Object 'DateTime' $today.Year,$today.Month,$today.Day

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    Install-User -Username 'CarbonInstallSchedul' -Password 'a1b2c34d!' -Description 'Test user for running scheduled tasks.'
    $credential = New-Credential -User 'CarbonInstallSchedul' -Password 'a1b2c34d!'
}

function Start-Test
{
    Uninstall-ScheduledTask -Name $taskName
    Assert-NoError
}

function Stop-Test
{
    $Error.Clear()
    Uninstall-ScheduledTask -Name $taskName
    Assert-NoError
}

function Test-ShouldCreateScheduledTaskWithPath
{
    $result = Install-ScheduledTask -Name 'PARENT\CHILD' -TaskToRun 'notepad' -Monthly -Force
    Assert-NotNull $result
    Assert-Equal '\PARENT\' $result.TaskPath
    Assert-Equal 'CHILD' $result.TaskName
    Assert-Equal '\PARENT\CHILD' $result.FullName
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
    Assert-TaskScheduled -InstallArguments @{ Weekly = 39 } -AssertArguments @{ ScheduleType = 'Weekly'; Modifier = 39; DayOfWeek = $today.DayOfWeek; }
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
    Assert-TaskScheduled -InstallArguments @{ Monthly = $true; } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 1; DayOfMonth = 1; Month = $AllMonths }
}

function Test-ShouldScheduleMonthlyTasksOnSpecificDay
{
    Assert-TaskScheduled -InstallArguments @{ Monthly = $true; DayOfMonth = 13; } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 1; DayOfMonth = 13; Month = $AllMonths }
}

function Test-ShouldScheduleLastDayOfTheMonthTask
{
    Assert-TaskScheduled -InstallArguments @{ LastDayOfMonth = $true; } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 'LastDay'; Month = $AllMonths; }
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
    Assert-TaskScheduled -InstallArguments @{ Month = @( 'January' ); DayOfMonth = 1; } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January' ); DayOfMonth = 1; }
}

function Test-ShouldScheduleForSpecificMonthWithInteger
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 1 ); DayOfMonth = 19; } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January' ); DayOfMonth = 19; }
}

function Test-ShouldScheduleForSpecificMonths
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 'January','April','July','October' ); DayOfMonth = 23; } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January','April','July','October' ); DayOfMonth = 23; }
}

function Test-ShouldNotScheduleMonthlyTaskWithMonthParameter
{
    $result = Install-ScheduledTask -Name $taskName -Principal LocalService -TaskToRun 'notepad' -Month $AllMonths -DayOfMonth 17 -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'to schedule a monthly task'
    Assert-Null $result
    Assert-False (Test-ScheduledTask -Name $taskName)
}

function Test-ShouldScheduleForSpecificMonthsOnSpecificDay
{
    Assert-TaskScheduled -InstallArguments @{ Month = @( 'January','April','July','October' ); DayOfMonth = 5;  } -AssertArguments @{ ScheduleType = 'Monthly'; Month = @( 'January','April','July','October' ); DayOfMonth = 5; }
}

function Test-ShouldScheduleWeekOfMonthTasks
{
    Assert-TaskScheduled -InstallArguments @{ WeekOfMonth = 'First'; DayOfWeek = $today.DayOfWeek } -AssertArguments @{ ScheduleType = 'Monthly'; Modifier = 'First'; Month = $AllMonths; DayOfWeek = $today.DayOfWeek; }
}

function Test-ShouldNotScheduleWeekOfMonthOnMultipleWeekDays
{
    $result = Install-ScheduledTask -Name $taskName -Principal LocalService -TaskToRun 'notepad' -WeekOfMonth First -DayOfWeek Friday,Monday -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'single weekday'
    Assert-Null $result
    Assert-False (Test-ScheduledTask -Name $taskName)
}

function Test-ShouldScheduleWeekOfMonthTasksOnEachWeek
{
    foreach( $week in @( 'First', 'Second', 'Third', 'Fourth', 'Last' ) )
    {
        $result = Install-ScheduledTask -Name $taskName -Principal LocalService -TaskToRun 'notepad' -WeekOfMonth $week -DayOfWeek $today.DayOfWeek -Force
        Assert-NoError
        Assert-NotNull $result
        Assert-ScheduledTask -Name $taskName -Principal 'Local Service' -TaskToRun 'notepad' -ScheduleType 'Monthly' -Modifier $week -DayOfWeek $today.DayOfWeek -Months $AllMonths
    }
}

function Test-ShouldScheduleTaskToRunOnce
{
    Assert-TaskScheduled -InstallArguments @{ Once = $true; StartTime = '3:03' } -AssertArguments @{ ScheduleType = 'Once'; StartTime = '3:03'; }
}

function Test-ShouldScheduleTaskToRunAtLogon
{
    Assert-TaskScheduled -InstallArguments @{ OnLogon = $true; } -AssertArguments @{ ScheduleType = 'OnLogon'; }
}

function Test-ShouldScheduleTaskToRunAtStart
{
    Assert-TaskScheduled -InstallArguments @{ OnStart = $true; } -AssertArguments @{ ScheduleType = 'OnStart'; }
}

function Test-ShouldScheduleTaskToRunOnIdle
{
    Assert-TaskScheduled -InstallArguments @{ OnIdle = 999; } -AssertArguments @{ ScheduleType = 'OnIdle'; IdleTime = 999; }
}

function Test-ShouldScheduleTaskToRunOnEvent
{
    Assert-TaskScheduled -InstallArguments @{ OnEvent = $true ; EventChannelName = 'System' ; EventXPathQuery = '*[System/EventID=101]'; } -AssertArguments @{ ScheduleType = 'OnEvent'; Modifier = '*[System/EventID=101]'; EventChannelName = 'System'; }
}

function Assert-TaskScheduledFromXml
{
    [CmdletBinding()]
    param(
        $Path,
        $Xml,
        $TaskCredential
    )

    Set-StrictMode -Version 'Latest'

    $installParams = @{ }
    if( $TaskCredential )
    {
        $installParams['TaskCredential'] = $TaskCredential
    }

    if( $Path )
    {
        $installParams['TaskXmlFilePath'] = $Path
    }

    if( $Xml )
    {
        $installParams['TaskXml'] = $Xml
    }

    $task = Install-ScheduledTask -Name $taskName @installParams -Verbose:$VerbosePreference
    Assert-NotNull $task
    Assert-NoError 
    # Now, make sure task doesn't get re-created if it already exists.
    Assert-Null (Install-ScheduledTask -Name $taskName @installParams -Verbose:$VerbosePreference)
    Assert-NoError
    $task = Get-ScheduledTask -Name $taskName
    Assert-NotNull $task
    Assert-Equal $taskName $task.TaskName
    if( $TaskCredential )
    {
        Assert-Equal $TaskCredential.Username $task.RunAsUser
    }
    else
    {
        Assert-Equal 'System' $task.RunAsUser
    }

    if( $Path )
    {
        $Xml = [xml]((Get-Content -Path $Path) -join ([Environment]::NewLine))
    }
    else
    {
        $Xml = [xml]$Xml
    }

    $actualXml = schtasks /query /tn $taskName /xml | Where-Object { $_ }
    $actualXml = $actualXml -join ([Environment]::NewLine)
    $actualXml = [xml]$actualXml
    Assert-Equal $Xml.OuterXml $actualXml.OuterXml

    if( $Path )
    {
        Assert-FileExists $Path
    }
    else
    {
        Assert-Null (Get-ChildItem -Path $env:TEMP 'Carbon+Install-ScheduledTask+*')
    }
}

function Test-ShouldInstallFromXmlFileWithRelativePath
{
    Push-Location -Path $PSScriptRoot
    try
    {
        Assert-TaskScheduledFromXml -Path '.\task.xml' -TaskCredential $credential
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldInstallFromXmlFileWithAbsolutePath
{
    Assert-TaskScheduledFromXml -Path (Join-Path -Path $PSScriptRoot -ChildPath 'task.xml') -TaskCredential $credential
}

function Test-ShouldInstallFromXmlFileForSystemUser
{
    Assert-TaskScheduledFromXml -Path (Join-Path -Path $PSScriptRoot -ChildPath 'task_with_principal.xml')
}

function Test-ShouldInstallFromXml
{
    Assert-TaskScheduledFromXml -Xml ((Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'task_with_principal.xml')) -join ([Environment]::NewLine))
}


function Assert-TaskScheduled
{
    [CmdletBinding()]
    param(
        [hashtable]
        $InstallArguments,

        [hashtable]
        $AssertArguments
    )

    Set-StrictMode -Version Latest

    $InstallArguments['Name'] = $taskName
    $InstallArguments['TaskToRun'] = 'notepad'
    $InstallArguments['Verbose'] = ($VerbosePreference -eq 'Continue')

    $AssertArguments['Name'] = $taskName
    $AssertArguments['TaskToRun'] = 'notepad'
    $AssertArguments['Verbose'] = ($VerbosePreference -eq 'Continue')

    # Install to run as SYSTEM
    $task = Install-ScheduledTask -Principal System @InstallArguments
    Assert-NoError
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask -Principal 'System' @AssertArguments

    $preTask = Get-ScheduledTask -Name $taskName
    Assert-Null (Install-ScheduledTask -Principal System @InstallArguments)
    Assert-NoError
    $postTask = Get-ScheduledTask -Name $taskName
    Assert-Equal $preTask.CreateDate $postTask.CreateDate

    $InstallArguments['TaskCredential'] = $credential
    $InstallArguments['Force'] = $true
    $AssertArguments['TaskCredential'] = $credential

    $task = Install-ScheduledTask @InstallArguments
    Assert-NoError
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments 

    # Install to start tomorrow
    # Check interval parameter
    $intervalSchedules = @( 'Daily', 'Weekly', 'Monthly', 'Month', 'LastDayOfMonth', 'WeekOfMonth' )
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

    if( -not $InstallArguments.ContainsKey('StartTime') )
    {
        $startTimeSchedules = @( 'Daily', 'Weekly', 'Monthly', 'Month', 'LastDayOfMonth', 'WeekOfMonth', 'Once' )
        foreach( $startTimeSchedule in $startTimeSchedules )
        {
            if( $InstallArguments.ContainsKey( $startTimeSchedule ) )
            {
                $task = Install-ScheduledTask @InstallArguments -StartTime '23:06'
                Assert-NoError
                Assert-NotNull $task
                Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
                Assert-ScheduledTask @AssertArguments -StartTime '23:06'
                break
            }
        }
    }

    $startDateSchedules =  @( 'Minute','Daily', 'Weekly', 'Monthly', 'Month', 'LastDayOfMonth', 'WeekOfMonth', 'Once' )
    foreach( $startDateSchedule in $startDateSchedules )
    {
        if( $InstallArguments.ContainsKey( $startDateSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -StartDate $today.AddDays(1)
            Assert-NoError
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -StartDate $today.AddDays(1)
        }
    }

    $durationSchedules = @( 'Minute', 'Daily', 'Weekly', 'Monthly', 'LastDayOfMonth', 'WeekOfMonth' )
    foreach( $durationSchedule in $durationSchedules )
    {
        if( $InstallArguments.ContainsKey( $durationSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -Duration '5:30'  # Using fractional hours to ensure it gets converted properly.
            Assert-NoError
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -Duration '5:30' 
            break
        }
    }

    $endDateSchedules = @( 'Daily', 'Weekly', 'Monthly', 'LastDayOfMonth', 'WeekOfMonth' )
    foreach( $endDateSchedule in $endDateSchedules )
    {
        if( $InstallArguments.ContainsKey( $endDateSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -EndDate $today.AddYears(1)
            Assert-NoError
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -EndDate $today.AddYears(1)
            break
        }
    }

    $endTimeSchedules = @( 'Minute', 'Hourly', 'Daily', 'Weekly', 'Monthly', 'LastDayOfMonth', 'WeekOfMonth' )
    foreach( $endTimeSchedule in $endTimeSchedules )
    {
        if( $InstallArguments.ContainsKey( $endTimeSchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -EndTime '23:06'
            Assert-NoError
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -EndTime '23:06' -EndDate $today
            break
        }
    }

    # Install as interactive
    $task = Install-ScheduledTask @InstallArguments -Interactive
    Assert-NoError
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -Interactive

    # Install as no password
    $task = Install-ScheduledTask @InstallArguments -NoPassword
    Assert-NoError
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -NoPassword

    # Install as highest run level
    $task = Install-ScheduledTask @InstallArguments -HighestAvailableRunLevel
    Assert-NoError
    Assert-NotNull $task
    Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
    Assert-ScheduledTask @AssertArguments -HighestAvailableRunLevel

    $delaySchedules = @( 'OnStart', 'OnLogon', 'OnEvent' )
    foreach( $delaySchedule in $delaySchedules )
    {
        if( $InstallArguments.ContainsKey( $delaySchedule ) )
        {
            $task = Install-ScheduledTask @InstallArguments -Delay '6.22:39:59'
            Assert-NoError
            Assert-NotNull $task
            Assert-Is $task ([Carbon.TaskScheduler.TaskInfo])
            Assert-ScheduledTask @AssertArguments -Delay '6.22:39:59'
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
        $TaskCredential,
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
        [int]
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
        [timespan]
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

    if( $PSBoundParameters.ContainsKey('TaskCredential') )
    {
        Assert-Equal $TaskCredential.Username $task.RunAsUser 'RunAsUser'
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
        Assert-Equal $ScheduleType $schedule.ScheduleType 'ScheduleType'
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
        Assert-Equal $StartDate $schedule.StartDate 'StartDate'
    }
    else
    {
        if( @('OnLogon', 'OnStart', 'OnIdle', 'OnEvent') -contains $ScheduleType )
        {
            Assert-Equal ([DateTime]::MinValue) $schedule.StartDate
        }
        else
        {
            Assert-Equal (New-Object 'DateTime' $today.Year,$today.Month,$today.Day) $Schedule.StartDate 'StartDate'
        }
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
        if( (@('Daily','Weekly','Monthly','Once') -contains $schedule.ScheduleType) -and ($PSBoundParameters.ContainsKey('EndTime') -or $PSBoundParameters.ContainsKey('Duration')) )
        {
            Assert-Equal 10 $schedule.Interval 'Interval'
        }
        else
        {
            Assert-Equal 0 $schedule.Interval 'Interval'
        }
    }

    if( $PSBoundParameters.ContainsKey('StartTime') )
    {
        Assert-Equal $StartTime $schedule.StartTime 'StartTime'
    }
    else
    {
        if( @('OnLogon', 'OnStart', 'OnIdle', 'OnEvent') -contains $ScheduleType )
        {
            Assert-Equal ([TimeSpan]::Zero) $schedule.StartTime
        }
        else
        {
            Assert-Equal (New-Object 'TimeSpan' $task.CreateDate.Hour,$task.CreateDate.Minute,0) $schedule.StartTime 'StartTime'
        }
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
        Assert-Equal $EndDate $schedule.EndDate
    }
    else
    {
        Assert-Equal ([datetime]::MaxValue) $schedule.EndDate
    }

    if( $PSBoundParameters.ContainsKey('Delay') )
    {
        Assert-Equal $Delay $schedule.Delay 'Delay'
    }
    else
    {
        Assert-Equal ([TimeSpan]::Zero) $schedule.Delay 'Delay'
    }

    if( $PSBoundParameters.ContainsKey('IdleTime') )
    {
        Assert-Equal $IdleTime $schedule.IdleTime 'IdleTime'
    }
    else
    {
        Assert-Equal 0 $schedule.IdleTime 'IdleTime'
    }

    if( $PSBoundParameters.ContainsKey('EventChannelName') )
    {
        Assert-Equal $EventChannelName $schedule.EventChannelName
    }
    else
    {
        Assert-Empty $schedule.EventChannelName
    }
}