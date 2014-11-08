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
    The `Install-ScheduledTask` function uses `schtasks.exe` to install a scheduled task on the current computer. If a task with the same name already exists, the existing task is left in place. Use the `-Force` switch to force `Install-ScheduledTask` to delete any existing tasks before installation.

    If a new task is created, a `Carbon.TaskScheduler.TaskInfo` object is returned.

    The `schtasks.exe` command line application is pretty limited in the kind of tasks it will create. If you need a scheduled task created with options not supported by `Install-ScheduledTask`, you can create an XML file using the [Task Scheduler Schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) or create a task with the Task Scheduler MMC then export that task as XML with the `schtasks.exe /query /xml /tn <TaskName>`. Pass the XML file (or the raw XML) with the `TaskXmlFilePath` or `TaskXml` parameters, respectively.

    .LINK
    Get-ScheduledTask

    .LINK
    Test-ScheduledTask

    .LINK
    Uninstall-ScheduledTask

    .LINK
    http://technet.microsoft.com/en-us/library/cc725744.aspx#BKMK_create
    
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'C:\Windows\system32\notepad.exe' -Minute 5

    Creates a scheduled task "CarbonSample" to run notepad.exe every five minutes. No credential or principal is provided, so the task will run as `System`.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'C:\Windows\system32\notepad.exe' -Minute 1 -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to run a task every minute as a specific user with the `TaskCredential` parameter.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'C:\Windows\system32\notepad.exe' -Minute 1 -Principal LocalService

    Demonstrates how to run a task every minute as a built-in principal, in this case `Local Service`.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'calc.exe' -Minute 5 -StartTime '12:00' -EndTime '14:00' -StartDate '6/6/2006' -EndDate '6/6/2006' 

    Demonstrates how to run a task every 5 minutes between the given start date/time and end date/time. In this case, the task will run between noon and 2 pm on `6/6/2006`.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad' -Hourly 1

    Creates a scheduled task `CarbonSample` which runs `notepad.exe` every hour as the `LocalService` user.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Weekly 1

    Demonstrates how to run a task ever *N* weeks, in this case every week.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Monthly

    Demonstrates how to run a task the 1st of every month.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Monthly -DayOfMonth 15

    Demonstrates how to run a monthly task on a specific day of the month.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Month 1,4,7,10 -DayOfMonth 5

    Demonstrates how to run a task on specific months of the year on a specific day of the month.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -WeekOfMonth First -DayOfWeek Sunday

    Demonstrates how to run a task on a specific week of each month. In this case, the task will run the first Sunday of every month.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Month 1,5,9 -WeekOfMonth First -DayOfWeek Sunday

    Demonstrates how to run a task on a specific week of specific months. In this case, the task will run the first Sunday of January, May, and September.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -LastDayOfMonth

    Demonstrates how to run a task the last day of every month.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -LastDayOfMonth -Month 1,6

    Demonstrates how to run a task the last day of specific months. In this case, the task will run the last day of January and June.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Once -StartTime '0:00'

    Demonstrates how to run a task once. In this case, the task will run at midnight of today (which means it probably won't run since it is always past midnight).

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnStart

    Demonstrates how to run a task when the computer starts up.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnStart -Delay '0:30'

    Demonstrates how to run a task when the computer starts up after a certain amount of time passes. In this case, the task will run 30 minutes after the computer starts.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnLogon -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to run a task when the user running the task logs on. Usually you want to pass a credential when setting up a logon task, since the built-in users never log in.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnLogon -Delay '1:45' -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to run a task after a certain amount of time passes after a user logs in. In this case, the task will run after 1 hour and 45 minutes after `runasuser` logs in.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnIdle

    Demonstrates how to run a task when the computer is idle.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnIdle -Delay '0:05'

    Demonstrates how to run a task when the computer has been idle for a desired amount of time. In this case, the task will run after the computer has been idle for 5 minutes.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'wevtvwr.msc' -OnEvent -EventChannelName System -EventXPathQuery '*[Sytem/EventID=101]'

    Demonstrates how to run an event when certain events are written to the event log. In this case, wevtvwr.msc will run whenever an event with ID `101` is published in the System event channel.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXmlFilePath $taskXmlPath

    Demonstrates how to create a task using the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that runs as a built-in principal. You can export task XML with the `schtasks /query /xml /tn <Name>` command.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXmlFilePath $taskXmlPath -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to create a task using the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that will run as a specific user. The username in the XML file should match the username in the credential.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXml $taskXml

    Demonstrates how to create a task using raw XML that conforms to the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that will run as a built-in principal. In this case, `$taskXml` should be an XML document.

    .EXAMPLE
    Install-ScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXml $taskXml -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to create a task using raw XML that conforms to the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that will run as a specific user. In this case, `$taskXml` should be an XML document.  The username in the XML document should match the username in the credential.
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

        [Parameter(Mandatory=$true,ParameterSetName='Minute')]
        [Parameter(Mandatory=$true,ParameterSetName='Hourly')]
        [Parameter(Mandatory=$true,ParameterSetName='Daily')]
        [Parameter(Mandatory=$true,ParameterSetName='Weekly')]
        [Parameter(Mandatory=$true,ParameterSetName='Monthly')]
        [Parameter(Mandatory=$true,ParameterSetName='Month')]
        [Parameter(Mandatory=$true,ParameterSetName='LastDayOfMonth')]
        [Parameter(Mandatory=$true,ParameterSetName='WeekOfMonth')]
        [Parameter(Mandatory=$true,ParameterSetName='Once')]
        [Parameter(Mandatory=$true,ParameterSetName='OnStart')]
        [Parameter(Mandatory=$true,ParameterSetName='OnLogon')]
        [Parameter(Mandatory=$true,ParameterSetName='OnIdle')]
        [Parameter(Mandatory=$true,ParameterSetName='OnEvent')]
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
        # Create a scheduled task that runs on specific months. To create a monthly task, use the `Monthly` switch.
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
        # Create a scheduled task that runs when the user running the task logs on.  Requires the `TaskCredential` parameter.
        $OnLogon,

        [Parameter(ParameterSetName='OnIdle',Mandatory=$true)]
        [ValidateRange(1,999)]
        [int]
        # Create a scheduled task that runs when the computer is idle for N minutes.
        $OnIdle,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs when events appear in the Windows event log.
        $OnEvent,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        # The name of the event channel to look at.
        $EventChannelName,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        # The XPath event query to use to determine when to fire `OnEvent` tasks.
        $EventXPathQuery,

        [Parameter(Mandatory=$true,ParameterSetName='XmlFile')]
        [string]
        # Install the task from this XML path.
        $TaskXmlFilePath,

        [Parameter(Mandatory=$true,ParameterSetName='Xml')]
        [xml]
        # Install the task from this XML.
        $TaskXml,

        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
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
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        # The end time to run the task. Must be less than `24:00`. Can't be used with `Duration`.
        $EndTime,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        # Enables the task to run interactively only if the user is currently logged on at the time the job runs. The task will only run if the user is logged on. Must be used with `TaskCredential` parameter.
        $Interactive,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        # No password is stored. The task runs non-interactively as the given user, who must be logged in. Only local resources are available. Must be used with `TaskCredential` parameter.
        $NoPassword,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        # Marks the task for deletion after its final run.
        $HighestAvailableRunLevel,

        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateScript({ $_ -lt '6.22:40:00'})]
        [timespan]
        # The wait time to delay the running of the task after the trigger is fired.  Must be less than 10,000 minutes (6 days, 22 hours, and 40 minutes).
        $Delay,

        [Management.Automation.PSCredential]
        # The principal the task should run as. Use `Principal` parameter to run as a built-in security principal. Required if `Interactive` or `NoPassword` switches are used.
        $TaskCredential,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateSet('System','LocalService','NetworkService')]
        [string]
        # The built-in identity to use. The default is `System`. Use the `TaskCredential` parameter to run as non-built-in security principal.
        $Principal = 'System',

        [Switch]
        # Create the task even if a task with the same name already exists (i.e. delete any task with the same name before installation).
        $Force
    )

    Set-StrictMode -Version 'Latest'

    if( (Test-ScheduledTask -Name $Name) )
    {
        if( $Force )
        {
            Uninstall-ScheduledTask -Name $Name -Verbose:$VerbosePreference
        }
        else
        {
            Write-Verbose ('Scheduled task ''{0}'' already exists. Use -Force switch to re-create it.' -f $Name)
            return
        }
    }

    $parameters = New-Object 'Collections.ArrayList'

    if( $TaskCredential )
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( $TaskCredential.UserName )
        [void]$parameters.Add( '/RP' )
        [void]$parameters.Add( $TaskCredential.GetNetworkCredential().Password )
        Grant-Privilege -Identity $TaskCredential.UserName -Privilege 'SeBatchLogonRight' -Verbose:$VerbosePreference
    }
    elseif( $PSCmdlet.ParameterSetName -notlike 'Xml*' )
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
    switch -Wildcard ( $PSCmdlet.ParameterSetName )
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
            $modifier = $EventXPathQuery
        }
        'Xml*'
        {
            if( $PSCmdlet.ParameterSetName -eq 'Xml' )
            {
                $TaskXmlFilePath = 'Carbon+Install-ScheduledTask+{0}.xml' -f [IO.Path]::GetRandomFileName()
                $TaskXmlFilePath = Join-Path -Path $env:TEMP -ChildPath $TaskXmlFilePath
                $TaskXml.Save($TaskXmlFilePath)
            }

            $scheduleType = $null
            $TaskXmlFilePath = Resolve-Path -Path $TaskXmlFilePath
            if( -not $TaskXmlFilePath )
            {
                return
            }

            [void]$parameters.Add( '/XML' )
            [void]$parameters.Add( $TaskXmlFilePath )
        }
    }

    try
    {
        if( $modifier )
        {
            [void]$parameters.Add( '/MO' )
            [void]$parameters.Add( $modifier )
        }

        if( $PSBoundParameters.ContainsKey('TaskToRun') )
        {
            [void]$parameters.Add( '/TR' )
            [void]$parameters.Add( $TaskToRun )
        }

        if( $scheduleType )
        {
            [void]$parameters.Add( '/SC' )
            [void]$parameters.Add( $scheduleType )
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
                    $totalHours = ($value.Days * 24) + $value.Hours
                    $value = '{0:0000}:{1:00}' -f $totalHours,$value.Minutes
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

        if( $PSBoundParameters.ContainsKey('HighestAvailableRunLevel') -and $HighestAvailableRunLevel )
        {
            [void]$parameters.Add( '/RL' )
            [void]$parameters.Add( 'HIGHEST' )
        }

        $originalEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $paramLogString = $parameters -join ' '
        if( $TaskCredential )
        {
            $paramLogString = $paramLogString -replace ([Text.RegularExpressions.Regex]::Escape($TaskCredential.GetNetworkCredential().Password)),'********'
        }
        Write-Verbose ('/TN {0} {1}' -f $Name,$paramLogString)
        # Warnings get written by schtasks to the error stream. Fortunately, errors and warnings 
        # are prefixed with ERRROR and WARNING, so we can combine output/error streams and parse 
        # it later. We just have to make sure we remove any errors added to the $Error variable.
        $errorCount = $Global:Error.Count
        $output = schtasks /create /TN $Name $parameters 2>&1
        if( $Global:Error.Count -gt $errorCount )
        {
            for( $idx = 0; $idx -lt ($Global:Error.Count - $errorCount); ++$idx )
            {
                $Global:Error.RemoveAt(0)
            }
        }
        $ErrorActionPreference = $originalEap

        $createFailed = $false
        if( $LASTEXITCODE )
        {
            $createFailed = $true
        }

        $output | ForEach-Object { 
            if( $_ -match '\bERROR\b' )
            {
                Write-Error $_
            }
            elseif( $_ -match '\bWARNING\b' )
            {
                Write-Warning ($_ -replace '^WARNING: ','')
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
    finally
    {
        if( $PSCmdlet.ParameterSetName -eq 'Xml' -and (Test-Path -Path $TaskXmlFilePath -PathType Leaf) )
        {
            Remove-Item -Path $TaskXmlFilePath -ErrorAction SilentlyContinue
        }
    }
}