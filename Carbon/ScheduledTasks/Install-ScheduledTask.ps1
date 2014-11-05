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

function Install-ScheduledTask
{
    <#
    .SYNOPSIS
    Installs a scheduled task on the current computer.

    .DESCRIPTION
    The `Install-ScheduledTask` function uses `schtasks.exe` to install a scheduled task on the current computer. If the task exists, and its configuration is different, it is deleted and re-created. If it exists and is unchanged, it is left untouched.
    
    If a new task is created, or a task is updated/change, a `Carbon.TaskScheduler.TaskInfo` is returned.

    Run `schtasks.exe /create /?` for further help.

    If you get a `The task XML contains a value which is incorrectly formatted or out of range.`, try creating the scheduled task directly  using the `/V1` switch. 

    .LINK
    Get-ScheduledTask

    .LINK
    Test-ScheduledTask

    .LINK
    Uninstall-ScheduledTask

    .LINK
    http://technet.microsoft.com/en-us/library/cc725744.aspx#BKMK_create

    .EXAMPLE
    Install-ScheduledTask -Name 'doc' -TaskToRun 'notepad' -Credential (Get-Credential 'runasuser') -ScheduleType Hourly

    Creates a scheduled task `doc` which runs `notepad.exe` eery hour under user `runasuser`.

    .EXAMPLE
    Install-ScheduledTask -Name 'accountant' -TaskToRun 'calc.exe' -ScheduleType Minute -Modifier 5 -StartTime '12:00' -EndTime '14:00' -StartDate '6/6/2006' -EndDate '6/6/2006' -Credential (Get-Credential 'runasuser')

    Creates a scheduled task "accountant" to run calc.exe every five minutes from the specified start time to end time between the start date and end date.

    .EXAMPLE
    Install-ScheduledTask -Name 'gametime' -TaskToRun 'C:\Windows\system32\freecell.exe' -ScheduleType Monthly -Modifier First -Days 'Sun'

    Creates a scheduled task "gametime" to run freecell on the first Sunday of every month.

    .EXAMPLE
    Install-ScheduledTask -Name 'report' -TaskToRun 'notepad.exe' -Credential (Get-Credential 'runasuser') -ScheduleType Weekly

    Creates a scheduled task "report" to run notepad.exe every week.

    .EXAMPLE
    Install-ScheduledTask -Name 'logtracker' -TaskToRun 'C:\Windows\system32\notepad.exe' -ScheduleType Minute -Modifier 5 -StartTime '18:30' -Credential (Get-Credential 'runasuser')

    Creates a scheduled task "logtracker" to run notepad.exe every five minutes starting from the specified start time with no end time. 

    .EXAMPLE
    Install-ScheduledTask -Name 'gaming' -TaskToRun 'C:\freecell' -ScheduleType Daily -StartTime '12:00' -EndTime '14:00' -Terminate

    Creates a scheduled task "gaming" to run freecell.exe starting at 12:00 and automatically terminating at 14:00 hours every day.

    .EXAMPLE
    Install-ScheduledTask -Name 'EventLog' -TaskToRun 'wevtvwr.msc' -ScheduleType OnEvent -EventChannelName System -Modifier '*[Sytem/EventID=101]'

    Creates a scheduled task "EventLog" to run wevtvwr.msc starting whenever event 101 is published in the System channel.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.TaskScheduler.TaskInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,238)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateLength(1,262)]
        [string]
        # The task/program to execute, including arguments/parameters.
        $TaskToRun,

        [Parameter(ParameterSetName='Minute',Mandatory=$true)]
        [ValidateRange(1,1439)]
        [int]
        # Create a scheduled task that runs every N minutes.
        $Minute,

        [Parameter(ParameterSetName='Hourly',Mandatory=$true)]
        [ValidateRange(1,23)]
        [int]
        # Create a scheduled task that runs every N hours.
        $Hourly,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Switch]
        # Stops the task at the `EndTime` or `Duration` if it is still running.
        $StopAtEnd,

        [Parameter(ParameterSetName='Daily',Mandatory=$true)]
        [ValidateRange(1,365)]
        [int]
        # Creates a scheduled task that runs every N days.
        $Daily,

        [Parameter(ParameterSetName='Weekly',Mandatory=$true)]
        [ValidateRange(1,52)]
        [int]
        # Creates a scheduled task that runs every N weeks.
        $Weekly,

        [Parameter(ParameterSetName='Monthly',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs every month.
        $Monthly,

        [Parameter(ParameterSetName='LastDayOfMonth',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs on the last day of every month. To run on specific months, specify the `Month` parameter.
        $LastDayOfMonth,

        [Parameter(ParameterSetName='Month',Mandatory=$true)]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Carbon.TaskScheduler.Month[]]
        # Create a scheduled task that runs on specific months. To create a monthly/ task, use the `Monthly` switch.
        $Month,

        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month',Mandatory=$true)]
        [ValidateRange(1,31)]
        [int]
        # The day of the month to run a monthly task.
        $DayOfMonth,

        [Parameter(ParameterSetName='WeekOfMonth',Mandatory=$true)]
        [Carbon.TaskScheduler.WeekOfMonth]
        # Create a scheduled task that runs a particular week of the month.
        $WeekOfMonth,

        [Parameter(ParameterSetName='WeekOfMonth',Mandatory=$true)]
        [Parameter(ParameterSetName='Weekly')]
        [DayOfWeek[]]
        # The day of the week to run the task. Default is today.
        $DayOfWeek,

        [Parameter(ParameterSetName='Once',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs once.
        $Once,

        [Parameter(ParameterSetName='OnStart',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs at startup.
        $OnStart,

        [Parameter(ParameterSetName='OnLogon',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs when the user running the task logs on.  Requires the `Credential` parameter.
        $OnLogon,

        [Parameter(ParameterSetName='OnIdle',Mandatory=$true)]
        [ValidateRange(1,999)]
        [int]
        # Create a scheduled task that runs when the computer is idle for N minutes.
        $OnIdle,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        # Create a scheduled task that runs when the computer is idle for N minutes.
        $OnEvent,

        [Parameter(Mandatory=$true,ParameterSetName='Xml')]
        [string]
        # Install the task from this XML path.
        $TaskXmlPath,

        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateRange(1,599940)]
        [int]
        # Re-run the task every N minutes.
        $Interval,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [DateTime]
        # The date the task can start running.
        $StartDate,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once',Mandatory=$true)]
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        # The start time to run the task. Must be less than `24:00`.
        $StartTime,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [TimeSpan]
        # The duration to run the task. Usually used with `Interval` to repeatedly run a task over a given time span. By default, re-runs for an hour. Can't be used with `EndTime`.
        $Duration,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [DateTime]
        # The last date the task should run.
        $EndDate,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        # The end time to run the task. Must be less than `24:00`. Can't be used with `Duration`.
        $EndTime,

        [Switch]
        # Enables the task to run interactively only if the user is currently logged on at the time the job runs. The task will only run if the user is logged on. Must be used with `Credential` parameter.
        $Interactive,

        [Switch]
        # No password is stored. The task runs non-interactively as the given user, who must be logged in. Only local resources are available. Must be used with `Credential` parameter.
        $NoPassword,

        [Switch]
        # Marks the task for deletion after its final run.
        $HighestAvailableRunLevel,

        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateScript({ $_ -lt '6:22:40:00'})]
        [timespan]
        # The wait time to delay the running of the task after the trigger is fired.  Must be less than 10,000 minutes (6 days, 22 hours, and 40 minutes).
        $Delay,

        [Management.Automation.PSCredential]
        # The principal the task should run as. Use `Principal` parameter to run as a built-in security principal. Required if `Interactive` or `NoPassword` switches are used.
        $Credential,

        [ValidateSet('System','LocalService','NetworkService')]
        [string]
        # The built-in identity to use. The default is `System`. Use the `Credential` parameter to run as non-built-in security principal.
        $Principal = 'System',

        [Switch]
        # Create the task and suppress warnings if the specified task already exists.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    #$Name = Join-Path -Path '\' -ChildPath $Name

    if( (Test-ScheduledTask -Name $Name) )
    {
        Uninstall-ScheduledTask -Name $Name -Verbose:$VerbosePreference
    }

    $parameters = New-Object 'Collections.ArrayList'

    if( $Credential )
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( $Credential.UserName )
        [void]$parameters.Add( '/RP' )
        [void]$parameters.Add( $Credential.GetNetworkCredential().Password )
        Grant-Privilege -Identity $Credential.UserName -Privilege 'SeBatchLogonRight' -Verbose:$VerbosePreference
    }
    else
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( (Resolve-IdentityName -Name $Principal) )
    }

    function ConvertTo-SchtasksCalendarNameList
    {
        param(
            [Parameter(Mandatory=$true)]
            [object[]]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $list = $InputObject | ForEach-Object { $_.ToString().Substring(0,3).ToUpperInvariant() }
        return $list -join ','
    }

    $scheduleType = $PSCmdlet.ParameterSetName.ToUpperInvariant()
    $modifier = $null
    switch( $PSCmdlet.ParameterSetName )
    {
        'Minute'
        {
            $modifier = $Minute
        }
        'Hourly'
        {
            $modifier = $Hourly
        }
        'Daily'
        {
            $modifier = $Daily
        }
        'Weekly'
        {
            $modifier = $Weekly
            if( $DayOfWeek )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $DayOfWeek) )
            }
        }
        'Monthly'
        {
            $modifier = 1
            if( $DayOfMonth )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( ($DayOfMonth -join ',') )
            }
        }
        'Month'
        {
            $scheduleType = 'MONTHLY'
            [void]$parameters.Add( '/M' )
            [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $Month) )
            if( ($Month | Select-Object -Unique | Measure-Object).Count -eq 12 )
            {
                Write-Error ('It looks like you''re trying to schedule a monthly task, since you passed all 12 months as the `Month` parameter. Please use the `-Monthly` switch to schedule a monthly task.')
                return
            }

            if( $DayOfMonth )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( ($DayOfMonth -join ',') )
            }
        }
        'LastDayOfMonth'
        {
            $modifier = 'LASTDAY'
            $scheduleType = 'MONTHLY'
            [void]$parameters.Add( '/M' )
            if( $Month )
            {
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $Month) )
            }
            else
            {
                [void]$parameters.Add( '*' )
            }
        }
        'WeekOfMonth'
        {
            $scheduleType = 'MONTHLY'
            $modifier = $WeekOfMonth
            [void]$parameters.Add( '/D' )
            if( $DayOfWeek )
            {
                if( $DayOfWeek.Count -eq 1 )
                {
                    [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $DayOfWeek) )
                }
                else
                {
                    Write-Error ('Tasks that run during a specific week of the month can only occur on a single weekday (received {0} days: {1}). Please pass one weekday with the `-DayOfWeek` parameter.' -f $DayOfWeek.Length,($DayOfWeek -join ','))
                    return
                }
            }
        }
        'OnIdle'
        {
            $scheduleType = 'ONIDLE'
            [void]$parameters.Add( '/I' )
            [void]$parameters.Add( $OnIdle )
        }
        'OnEvent'
        {
            $modifier = $OnEvent
        }
        'TaskXml'
        {
        }
    }

    if( $modifier )
    {
        [void]$parameters.Add( '/MO' )
        [void]$parameters.Add( $modifier )
    }

    $parameterNameToSchtasksMap = @{
                                        'StartTime' = '/ST';
                                        'Interval' = '/RI';
                                        'EndTime' = '/ET';
                                        'Duration' = '/DU';
                                        'StopAtEnd' = '/K';
                                        'StartDate' = '/SD';
                                        'EndDate' = '/ED';
                                        'EventChannelName' = '/EC';
                                        'Interactive' = '/IT';
                                        'NoPassword' = '/NP';
                                        'Force' = '/F';
                                        'Delay' = '/DELAY';
                                  }

    foreach( $parameterName in $parameterNameToSchtasksMap.Keys )
    {
        if( -not $PSBoundParameters.ContainsKey( $parameterName ) )
        {
            continue
        }

        $schtasksParamName = $parameterNameToSchtasksMap[$parameterName]
        $value = $PSBoundParameters[$parameterName]
        if( $value -is [timespan] )
        {
            if( $parameterName -eq 'Duration' )
            {
                $value = '{0:0000}:{1:00}' -f $value.TotalHours,$value.Minutes
            }
            elseif( $parameterName -eq 'Delay' )
            {
                $totalMinutes = ($value.Days * 24 * 60) + ($value.Hours * 60) + $value.Minutes
                $value = '{0:0000}:{1:00}' -f $totalMinutes,$value.Seconds
            }
            else
            {
                $value = '{0:00}:{1:00}' -f $value.Hours,$value.Minutes
            }
        }
        elseif( $value -is [datetime] )
        {
            $value = $value.ToString('MM/dd/yyyy')
        }

        [void]$parameters.Add( $schtasksParamName )

        if( $value -isnot [switch] )
        {
            [void]$parameters.Add( $value )
        }
    }

    [void]$parameters.Add( '/RL' )
    if( $HighestAvailableRunLevel )
    {
        [void]$parameters.Add( 'HIGHEST' )
    }
    else
    {
        [void]$parameters.Add( 'LIMITED' )
    }

    $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Uninstall-ScheduledTask+{0}' -f ([IO.Path]::GetRandomFileName()))
    $originalEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $paramLogString = $parameters -join ' '
    if( $Credential )
    {
        $paramLogString = $paramLogString -replace ([Text.RegularExpressions.Regex]::Escape($Credential.GetNetworkCredential().Password)),'********'
    }
    Write-Verbose ('/TN {0} /TR {1} /SC {2} {3}' -f $Name,$TaskToRun,$scheduleType,$paramLogString)
    $output = schtasks /create /TN $Name /TR $TaskToRun /SC $scheduleType $parameters 2> $errFile 
    $ErrorActionPreference = $originalEap

    $createFailed = $false
    if( $LASTEXITCODE )
    {
        $createFailed = $true
        Write-Error ((Get-Content -Path $errFile) -join ([Environment]::NewLine))
    }

    $output | ForEach-Object { 
        if( $_ -match '\bERROR\b' )
        {
            Write-Error $_
        }
        elseif( $_ -match '\bWARNING\b' )
        {
            Write-Warning $_
        }
        else
        {
            Write-Verbose $_
        }
    }

    if( -not $createFailed )
    {
        Get-ScheduledTask -Name $Name
    }
}