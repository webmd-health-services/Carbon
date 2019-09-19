
function Get-CScheduledTask
{
    <#
    .SYNOPSIS
    Gets the scheduled tasks for the current computer.

    .DESCRIPTION
    The `Get-CScheduledTask` function gets the scheduled tasks on the current computer. It returns `Carbon.TaskScheduler.TaskInfo` objects for each one.

    With no parameters, `Get-CScheduledTask` returns all scheduled tasks. To get a specific scheduled task, use the `Name` parameter, which must be the full name of the task, i.e. path plus name. The name parameter accepts wildcards. If a scheduled task with the given name isn't found, an error is written.

    By default, `Get-CScheduledTask` uses the `schtasks.exe` application to get scheduled task information. Beginning in Carbon 2.8.0, you can return `RegisteredTask` objects from the `Schedule.Service` COM API with the `AsComObject` switch. Using this switch is an order of magnitude faster. In the next major version of Carbon, this will become the default behavior.

    Before Carbon 2.7.0, this function has the same name as the built-in `Get-ScheduledTask` function that comes on Windows 2012/8 and later. It returns objects with the same properties, but if you want to use the built-in function, use the `ScheduledTasks` qualifier, e.g. `ScheduledTasks\Get-ScheduledTask`.

    .LINK
    Test-CScheduledTask

    .EXAMPLE
    Get-CScheduledTask

    Demonstrates how to get all scheduled tasks.

    .EXAMPLE
    Get-CScheduledTask -Name 'AutoUpdateMyApp'

    Demonstrates how to get a specific task.

    .EXAMPLE
    Get-CScheduledTask -Name '*Microsoft*'

    Demonstrates how to get all tasks that match a wildcard pattern.

    .EXAMPLE
    ScheduledTasks\Get-CScheduledTask

    Demonstrates how to call the `Get-CScheduledTask` function in the `ScheduledTasks` module which ships on Windows 2012/8 and later.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.TaskScheduler.TaskInfo])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [Switch]
        # Return the scheduled task as a [RegisteredTask Windows COM object](https://docs.microsoft.com/en-us/windows/desktop/taskschd/registeredtask), using the `Schedule.Service` COM API. This is faster and more reliable. See [Task Scheduler Reference](https://docs.microsoft.com/en-us/windows/desktop/taskschd/task-scheduler-reference) for more information.
        #
        # This parameter was introduced in Carbon 2.8.0.
        $AsComObject
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function ConvertFrom-DurationSpec
    {
        param(
            $Duration
        )

        if( $Duration -match '^P((\d+)D)?T((\d+)H)?((\d+)M)?((\d+)S)?$' )
        {
            return New-Object 'TimeSpan' $Matches[2],$Matches[4],$Matches[6],$Matches[8]
        }
    }

    function ConvertFrom-RepetitionElement
    {
        param(
            [Xml.XmlElement]
            $TriggerElement
        )

        Set-StrictMode -Version 'Latest'

        [Carbon.TaskScheduler.ScheduleType]$scheduleType = [Carbon.TaskScheduler.ScheduleType]::Unknown
        $interval = $null
        $modifier = $null
        $duration = $null
        $stopAtEnd = $false
        [TimeSpan]$delay = [TimeSpan]::Zero

        if( $TriggerElement.GetElementsByTagName('Repetition').Count -gt 0 )
        {
            $repetition = $TriggerElement.Repetition

            $interval = $repetition.Interval
            if( $interval -match 'PT(\d+)(.*)$' )
            {
                $modifier = $Matches[1]
                $unit = $Matches[2]

                $hour = 0
                $minute = 0
                $second = 0
                switch( $unit )
                {
                    'H' { $hour = $modifier }
                    'M' { $minute = $modifier }
                }

                $scheduleTypes = @{
                                        'H' = 'Hourly';
                                        'M' = 'Minute';
                                  }
                if( $scheduleTypes.ContainsKey( $unit ) )
                {
                    $scheduleType = $scheduleTypes[$unit]
                }
                $timespan = New-Object 'TimeSpan' $hour,$minute,$second
                switch( $scheduleType )
                {
                    'Hourly' { $modifier = $timespan.TotalHours }
                    'Minute' { $modifier = $timespan.TotalMinutes }
                }
            }
        
            if( $repetition | Get-Member -Name 'Duration' )
            {
                $duration = $repetition.Duration
                $durationAsTimeSpan = ConvertFrom-DurationSpec -Duration $repetition.Duration
                if( $durationAsTimeSpan -ne $null )
                {
                    $duration = $durationAsTimeSpan
                }
            }

            if( $repetition | Get-Member -Name 'StopAtDurationEnd' )
            {
                $stopAtEnd = ($repetition.StopAtDurationEnd -eq 'true')
            }
        }

        if( $TriggerElement | Get-Member -Name 'Delay' )
        {
            $delayAsTimeSpan = ConvertFrom-DurationSpec -Duration $TriggerElement.Delay
            if( $delayAsTimeSpan -ne $null )
            {
                $delay = $delayAsTimeSpan
            }
        }

        return $scheduleType,$modifier,$duration,$stopAtEnd,$delay
    }

    $optionalArgs = @()
    $wildcardSearch = $false
    if( $Name )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name) )
        {
            $wildcardSearch = $true
        }
        else
        {
            $Name = Join-Path -Path '\' -ChildPath $Name
            $optionalArgs = @( '/tn', $Name )
        }
    }

    if( $AsComObject )
    {
        $taskScheduler = New-Object -ComObject 'Schedule.Service'
        $taskScheduler.Connect()


        function Get-Tasks
        {
            param(
                $Folder
            )
    
            $getHiddenTasks = 1
    
            $Folder.GetTasks($getHiddenTasks) | ForEach-Object { $_ }
    
            foreach( $subFolder in $Folder.GetFolders($getHiddenTasks) )
            {
                Get-Tasks -Folder $subFolder
            }
        }

        $tasks = Get-Tasks -Folder $taskScheduler.GetFolder("\") |
                    Where-Object { 
                        if( -not $Name )
                        {
                            return $true
                        }
                    
                        return $_.Path -like $Name
                    }

        if( -not $wildcardSearch -and -not $tasks )
        {
            Write-Error -Message ('Scheduled task "{0}" not found.' -f $Name) -ErrorAction $ErrorActionPreference
            return
        }

        return $tasks
    }

    $originalErrPreference = $ErrorActionPreference
    $originalEncoding = [Console]::OutputEncoding
    # Some tasks from Intel have special characters in them.
    $OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(1252)
    $ErrorActionPreference = 'Continue'
    [object[]]$output = $null
    $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Get-CScheduledTask+{0}' -f [IO.Path]::GetRandomFileName())
    try
    {
        $output = schtasks /query /v /fo csv $optionalArgs 2> $errFile | 
                    ConvertFrom-Csv | 
                    Where-Object { $_.HostName -ne 'HostName' } 
    }
    finally
    {
        $ErrorActionPreference = $originalErrPreference
        $OutputEncoding = [Console]::OutputEncoding = $originalEncoding
    }

    if( $LASTEXITCODE )
    {
        if( (Test-Path -Path $errFile -PathType Leaf) )
        {
            $error = (Get-Content -Path $errFile) -join ([Environment]::NewLine)
            try
            {
                if( $error -match 'The\ system\ cannot\ find\ the\ (file|path)\ specified\.' )
                {
                    Write-Error ('Scheduled task ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
                }
                else
                {
                    Write-Error ($error) -ErrorAction $ErrorActionPreference
                }
            }
            finally
            {
                Remove-Item -Path $errFile
            }
        }
        return
    }

    if( -not $output )
    {
        return
    }

    $comTasks = Get-CScheduledTask -AsComObject

    for( $idx = 0; $idx -lt $output.Count; ++$idx )
    {
        $csvTask = $output[$idx]

        $comTask = $comTasks | Where-Object { $_.Path -eq $csvTask.TaskName }
        if( $comTask )
        {
            $xmlDoc = [xml]$comTask.Xml
        }
        else
        {
            $xml = schtasks /query /tn $csvTask.TaskName /xml | Where-Object { $_ }
            $xml = $xml -join ([Environment]::NewLine)
            $xmlDoc = [xml]$xml            
        }

        $taskPath = Split-Path -Parent -Path $csvTask.TaskName
        # Get-CScheduledTask on Win2012/8 has a trailing slash so we include it here.
        if( $taskPath -ne '\' )
        {
            $taskPath = '{0}\' -f $taskPath
        }
        $taskName = Split-Path -Leaf -Path $csvTask.TaskName

        if( -not ($xmlDoc | Get-Member -Name 'Task') )
        {
            Write-Error -Message ('Unable to get information for scheduled task "{0}": XML task information is missing the "Task" element.' -f $csvTask.TaskName) -ErrorAction $ErrorActionPreference
            continue
        }

        $xmlTask = $xmlDoc.Task
        $principal = $xmlTask.Principals.Principal
        $isInteractive = $false
        $noPassword = $false
        if( $principal | Get-Member 'LogonType' )
        {
            $isInteractive = $principal.LogonType -eq 'InteractiveTokenOrPassword'
            $noPassword = $principal.LogonType -eq 'S4U'
        }

        $highestRunLevel = $false
        if( $principal | Get-Member 'RunLevel' )
        {
            $highestRunLevel = ($principal.RunLevel -eq 'HighestAvailable')
        }

        $createDate = [DateTime]::MinValue
        if( $xmlTask | Get-Member -Name 'RegistrationInfo' )
        {
            $regInfo = $xmlTask.RegistrationInfo 
            if( $regInfo | Get-Member -Name 'Date' )
            {
                $createDate = [datetime]$regInfo.Date
            }
        }

        $taskToRun = $csvTask.'Task To Run'
        if( ($xmlTask | Get-Member -Name 'Actions') -and $xmlTask.Actions.ChildNodes.Count -eq 1 )
        {
            $actions = $xmlTask.Actions
            if( ($actions | Get-Member -Name 'Exec') -and ($actions.Exec | Measure-Object | Select-Object -ExpandProperty 'Count') -eq 1)
            {
                $exec = $actions.Exec

                if( $exec | Get-Member -Name 'Command' )
                {
                    $taskToRun = $exec.Command
                }

                if( $exec | Get-Member -Name 'Arguments' )
                {
                    $taskToRun = '{0} {1}' -f $taskToRun,$exec.Arguments
                }
            }
        }

        $ctorArgs = @(
                        $csvTask.HostName,
                        $taskPath,
                        $taskName,
                        $csvTask.'Next Run Time',
                        $csvTask.Status,
                        $csvTask.'Logon Mode',
                        $csvTask.'Last Run Time',
                        $csvTask.Author,
                        $createDate,
                        $taskToRun,
                        $csvTask.'Start In',
                        $csvTask.Comment,
                        $csvTask.'Scheduled Task State',
                        $csvTask.'Idle Time',
                        $csvTask.'Power Management',
                        $csvTask.'Run As User',
                        $isInteractive,
                        $noPassword,
                        $highestRunLevel,
                        $csvTask.'Delete Task If Not Rescheduled'
                    )

        $task = New-Object -TypeName 'Carbon.TaskScheduler.TaskInfo' -ArgumentList $ctorArgs

        $scheduleIdx = 0
        while( $idx -lt $output.Count -and $output[$idx].TaskName -eq $csvTask.TaskName )
        {
            $csvTask = $output[$idx++]
            [Carbon.TaskScheduler.ScheduleType]$scheduleType = [Carbon.TaskScheduler.ScheduleType]::Unknown

            [int[]]$days = @()
            [int]$csvDay = 0
            if( [int]::TryParse($csvTask.Days, [ref]$csvDay) )
            {
                $days = @( $csvDay )
            }

            $duration = $csvTask.'Repeat: Until: Duration'
            [Carbon.TaskScheduler.Month[]]$months = @()
            $modifier = $null
            $stopAtEnd = $false
            [int]$interval = 0
            [TimeSpan]$endTime = [TimeSpan]::Zero
            [DayOfWeek[]]$daysOfWeek = @()
            [TimeSpan]$delay = [TimeSpan]::Zero
            [int]$idleTime = 0
            $eventChannelName = $null

            $triggers = $xmlTask.GetElementsByTagName('Triggers') | Select-Object -First 1
            if( -not $triggers -or $triggers.ChildNodes.Count -eq 0 )
            {
                $scheduleType = [Carbon.TaskScheduler.ScheduleType]::OnDemand
            }
            elseif( $triggers.ChildNodes.Count -gt 0 )
            {
                [Xml.XmlElement]$trigger = $triggers.ChildNodes.Item($scheduleIdx++)
                if( $trigger | Get-Member -Name 'EndBoundary' )
                {
                    $endDateTime = [datetime]$trigger.EndBoundary
                    $endTime = New-TimeSpan -Hours $endDateTime.Hour -Minutes $endDateTime.Minute -Seconds $endDateTime.Second
                }

                $scheduleType,$modifier,$duration,$stopAtEnd,$delay = ConvertFrom-RepetitionElement $trigger
                if( $trigger.Name -eq 'TimeTrigger' )
                {
                    $days = @( )
                    if( $csvTask.'Schedule Type' -eq 'One Time Only' )
                    {
                        $scheduleType = 'Once'
                        $interval = $modifier
                        $modifier = $null
                    }
                }
                elseif( $trigger.Name -eq 'LogonTrigger' )
                {
                    $scheduleType = 'OnLogon'
                    $interval = 0
                    $modifier = $null
                }
                elseif( $trigger.Name -eq 'BootTrigger' )
                {
                    $scheduleType = 'OnStart'
                    $interval = 0
                    $modifier = $null
                }
                elseif( $trigger.Name -eq 'IdleTrigger' )
                {
                    $scheduleType = 'OnIdle'
                    $interval = 0
                    $modifier = $null
                    $settingsNode = $xmlTask.Settings
                    if( $settingsNode | Get-Member 'IdleSettings' )
                    {
                        $idleSettingsNode = $settingsNode.IdleSettings
                        if( $idleSettingsNode | Get-Member 'Duration' )
                        {
                            $idleTimeAsTimeSpan = ConvertFrom-DurationSpec -Duration $xmlTask.Settings.IdleSettings.Duration
                            if( $idleTimeAsTimeSpan -ne $null )
                            {
                                $idleTime = $idleTimeAsTimeSpan.TotalMinutes
                            }
                        }
                    }
                }
                elseif( $trigger.Name -eq 'EventTrigger' )
                {
                    $scheduleType = 'OnEvent'
                    $subscription = [xml]$trigger.Subscription
                    $selectNode = $subscription.QueryList.Query.Select
                    $modifier = $selectNode.InnerText
                    $eventChannelName = $selectNode.GetAttribute('Path')
                }
                elseif( $trigger.Name -eq 'SessionStateChangeTrigger' )
                {
                    $scheduleType = [Carbon.TaskScheduler.ScheduleType]::SessionStateChange
                }
                elseif( $trigger.Name -eq 'RegistrationTrigger' )
                {
                    $scheduleType = [Carbon.TaskScheduler.ScheduleType]::Registration
                }
                elseif( $trigger.Name -eq 'CalendarTrigger' )
                {
                    if( $trigger.GetElementsByTagName('ScheduleByDay').Count -eq 1 )
                    {
                        $scheduleType = 'Daily'
                        $modifier = $trigger.ScheduleByDay.DaysInterval
                        $null,$interval,$null,$null = ConvertFrom-RepetitionElement $trigger
                    }
                    elseif( $trigger.GetElementsByTagName('ScheduleByWeek').Count -eq 1 )
                    {
                        $scheduleType = 'Weekly'
                        $interval = $modifier
                        $modifier = $trigger.ScheduleByWeek.WeeksInterval
                        $days = @( )
                        $daysOfWeek = $trigger.ScheduleByWeek.DaysOfWeek.ChildNodes | ForEach-Object { [DayOfWeek]$_.Name }
                    }
                    elseif( $trigger.GetElementsByTagName('ScheduleByMonth').Count -eq 1 )
                    {
                        $scheduleType = 'Monthly'
                        $monthsNode = $trigger.ScheduleByMonth.Months
                        $daysOfMonth = $trigger.ScheduleByMonth.DaysOfMonth.ChildNodes | ForEach-Object { $_.InnerText }
                        if( $daysOfMonth -eq 'Last' )
                        {
                            $interval = $modifier
                            $modifier = 'LastDay'
                            $days = @()
                        }
                        else
                        {
                            $days = $daysOfMonth | ForEach-Object { [int]$_ }
                            $interval = $modifier
                            # Monthly tasks.
                            if( $monthsNode.ChildNodes.Count -eq 12 )
                            {
                                $modifier = 1
                            }
                            else
                            {
                                # Non-monthly tasks.
                                $modifier = $null
                            }
                        }

                        [Carbon.TaskScheduler.Month[]]$months = $monthsNode.ChildNodes | ForEach-Object { ([Carbon.TaskScheduler.Month]$_.Name) }
                    }
                    elseif( $triggers.GetElementsByTagName('ScheduleByMonthDayOfWeek').Count -eq 1 )
                    {
                        $scheduleType = 'Monthly'
                        $interval = $modifier
                        $scheduleNode = $trigger.ScheduleByMonthDayOfWeek
                        $daysOfWeek = $scheduleNode.DaysOfWeek.ChildNodes | ForEach-Object { [DayOfWeek]$_.Name }
                        $months = $scheduleNode.Months.ChildNodes | ForEach-Object { ([Carbon.TaskScheduler.Month]$_.Name) }
                        switch( $scheduleNode.Weeks.Week )
                        {
                            1 { $modifier = 'First' }
                            2 { $modifier = 'Second' }
                            3 { $modifier = 'Third' }
                            4 { $modifier = 'Fourth' }
                            'Last' { $modifier = 'Last' }
                        }
                    }
                }
            }

            function ConvertFrom-SchtasksDate
            {
                param(
                    [Parameter(Mandatory=$true)]
                    [string]
                    $SchtasksDate,

                    [Parameter(Mandatory=$true)]
                    [DateTime]
                    $DefaultValue
                )

                Set-StrictMode -Version 'Latest'

                [DateTime]$dateTime = $DefaultValue
                if( -not [DateTime]::TryParse( $SchtasksDate, [ref] $dateTime ) )
                {
                    return $DefaultValue
                }
                return New-Object 'DateTime' $dateTime.Year,$dateTime.Month,$dateTime.Day
            }

            function ConvertFrom-SchtasksTime
            {
                param(
                    [Parameter(Mandatory=$true)]
                    [string]
                    $SchtasksTime
                )

                Set-StrictMode -Version 'Latest'

                [TimeSpan]$timespan = [TimeSpan]::Zero
                [DateTime]$dateTime = New-Object 'DateTime' 2015,11,6
                $schtasksTime = '{0} {1}' -f (Get-Date).ToString('d'),$SchtasksTime
                if( -not [DateTime]::TryParse( $SchtasksTime, [ref] $dateTime ) )
                {
                    return $timespan
                }

                return New-Object 'TimeSpan' $dateTime.Hour,$dateTime.Minute,$dateTime.Second
            }

            $startDate = ConvertFrom-SchtasksDate $csvTask.'Start Date' -DefaultValue ([DateTime]::MinValue)
            $startTime = ConvertFrom-SchtasksTime $csvTask.'Start Time'
            $endDate = ConvertFrom-SchtasksDate $csvTask.'End Date' -DefaultValue ([DateTime]::MaxValue)

            $scheduleCtorArgs = @(
                                    $csvTask.'Last Result',
                                    $csvTask.'Stop Task If Runs X Hours And X Mins',
                                    $scheduleType,
                                    $modifier,
                                    $interval,
                                    $startTime,
                                    $startDate,
                                    $endTime,
                                    $endDate,
                                    $daysOfWeek,
                                    $days,
                                    $months,
                                    $csvTask.'Repeat: Every',
                                    $csvTask.'Repeat: Until: Time',
                                    $duration,
                                    $csvTask.'Repeat: Stop If Still Running',
                                    $stopAtEnd,
                                    $delay,
                                    $idleTime,
                                    $eventChannelName
                                )

            $schedule = New-Object -TypeName 'Carbon.TaskScheduler.ScheduleInfo' -ArgumentList $scheduleCtorArgs 
            $task.Schedules.Add( $schedule )
        }
        --$idx;

        if( -not $wildcardSearch -or $task.FullName -like $Name )
        {
            $task
        }
    }

}
