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

function Get-ScheduledTask
{
    <#
    .SYNOPSIS
    Gets the scheduled tasks for the current computer.

    .DESCRIPTION
    The `Get-ScheduledTask` function gets the scheduled tasks on the current computer. It returns `Carbon.TaskScheduler.TaskInfo` objects for each one.

    With no parameters, `Get-ScheduledTask` returns all scheduled tasks. To get a specific scheduled task, use the `Name` parameter, which must be the full name of the task, i.e. path plus name. The name parameter accepts wildcards. If a scheduled task with the given name isn't found, an error is written.

    This function has the same name as the built-in `Get-ScheduledTask` function that comes on Windows 2012/8 and later. It returns objects with the same properties, but if you want to use the built-in function, use the `ScheduledTasks` qualifier, e.g. `ScheduledTasks\Get-ScheduledTask`.

    .LINK
    Test-ScheduledTask

    .EXAMPLE
    Get-ScheduledTask

    Demonstrates how to get all scheduled tasks.

    .EXAMPLE
    Get-ScheduledTask -Name 'AutoUpdateMyApp'

    Demonstrates how to get a specific task.

    .EXAMPLE
    Get-ScheduledTask -Name '*Microsoft*'

    Demonstrates how to get all tasks that match a wildcard pattern.

    .EXAMPLE
    ScheduledTasks\Get-ScheduledTask

    Demonstrates how to call the `Get-ScheduledTask` function in the `ScheduledTasks` module which ships on Windows 2012/8 and later.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.TaskScheduler.TaskInfo])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    function ConvertFrom-RepetitionElement
    {
        param(
            [Xml.XmlElement]
            $TriggerElement
        )

        Set-StrictMode -Version 'Latest'

        if( $TriggerElement.GetElementsByTagName('Repetition').Count -eq 0 )
        {
            return
        }

        $scheduleType = $null
        $interval = $null
        $duration = $null
        $stopAtEnd = $false

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
            $scheduleType = $scheduleTypes[$unit]
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
            if( $duration -match 'PT((\d+)H)?((\d+)M)?((\d+)S)?$' )
            {
                $hours = $Matches[2]
                $minutes = $Matches[4]
                $seconds = $Matches[6]
                $duration = New-Object -TypeName 'TimeSpan' -ArgumentList $hours,$minutes,$seconds
            }
        }

        if( $repetition | Get-Member -Name 'StopAtDurationEnd' )
        {
            $stopAtEnd = ($repetition.StopAtDurationEnd -eq 'true')
        }

        return $scheduleType,$modifier,$duration,$stopAtEnd
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

    $originalErrPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Get-ScheduledTask+{0}' -f [IO.Path]::GetRandomFileName())
    [object[]]$output = schtasks /query /v /fo csv $optionalArgs 2> $errFile | ConvertFrom-Csv | Where-Object { $_.HostName -ne 'HostName' } 
    $ErrorActionPreference = $originalErrPreference

    if( $LASTEXITCODE )
    {
        if( (Test-Path -Path $errFile -PathType Leaf) )
        {
            $error = Get-Content -Path $errFile -Raw
            try
            {
                if( $error -like '*The system cannot find the file specified.*' )
                {
                    Write-Error ('Scheduled task ''{0}'' not found.' -f $Name)
                }
                else
                {
                    Write-Error ($error)
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

    for( $idx = 0; $idx -lt $output.Count; ++$idx )
    {
        $csvTask = $output[$idx]

        $xml = schtasks /query /tn $csvTask.TaskName /xml | Where-Object { $_ }
        $xml = $xml -join ([Environment]::NewLine)
        $xmlDoc = [xml]$xml

        $taskPath = Split-Path -Parent -Path $csvTask.TaskName
        # Get-ScheduledTask on Win2012/8 has a trailing slash so we include it here.
        if( $taskPath -ne '\' )
        {
            $taskPath = '{0}\' -f $taskPath
        }
        $taskName = Split-Path -Leaf -Path $csvTask.TaskName

        $ctorArgs = @(
                        $csvTask.HostName,
                        $taskPath,
                        $taskName,
                        $csvTask.'Next Run Time',
                        $csvTask.Status,
                        $csvTask.'Logon Mode',
                        $csvTask.'Last Run Time',
                        $csvTask.Author,
                        $csvTask.'Task To Run',
                        $csvTask.'Start In',
                        $csvTask.Comment,
                        $csvTask.'Scheduled Task State',
                        $csvTask.'Idle Time',
                        $csvTask.'Power Management',
                        $csvTask.'Run As User',
                        $csvTask.'Delete Task If Not Rescheduled'
                    )

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

        $task = New-Object -TypeName 'Carbon.TaskScheduler.TaskInfo' -ArgumentList $ctorArgs | 
                    Add-Member -MemberType NoteProperty -Name Interactive -Value $isInteractive -PassThru |
                    Add-Member -MemberType NoteProperty -Name NoPassword -Value $noPassword -PassThru |
                    Add-Member -MemberType NoteProperty -Name HighestAvailableRunLevel -Value $highestRunLevel -PassThru |
                    Add-Member -MemberType NoteProperty -Name CreateDate -Value $createDate -PassThru

        $scheduleIdx = 0
        while( $idx -lt $output.Count -and $output[$idx].TaskName -eq $csvTask.TaskName )
        {
            $csvTask = $output[$idx++]
            $scheduleType = $csvTask.'Schedule Type'
            $days = $csvTask.Days
            $duration = $csvTask.'Repeat: Until: Duration'
            [Carbon.TaskScheduler.Months]$months = [Carbon.TaskScheduler.Months]::None
            $modifier = $null
            $stopAtEnd = $false
            [int]$interval = 0
            [TimeSpan]$endTime = [TimeSpan]::Zero

            $triggers = $xmlTask.GetElementsByTagName('Triggers') | Select-Object -First 1
            if( $triggers -and $triggers.ChildNodes.Count -gt 0 )
            {
                [Xml.XmlElement]$trigger = $triggers.ChildNodes[$scheduleIdx++]
                if( $trigger | Get-Member -Name 'EndBoundary' )
                {
                    $endDateTime = [datetime]$trigger.EndBoundary
                    $endTime = New-TimeSpan -Hours $endDateTime.Hour -Minutes $endDateTime.Minute -Seconds $endDateTime.Second
                }

                $scheduleType,$modifier,$duration,$stopAtEnd = ConvertFrom-RepetitionElement $trigger
                if( $trigger.Name -eq 'TimeTrigger' )
                {
                    $days = $null
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
                        [string[]]$days = $trigger.ScheduleByWeek.DaysOfWeek.ChildNodes | ForEach-Object { $_.Name }
                    }
                    elseif( $trigger.GetElementsByTagName('ScheduleByMonth').Count -eq 1 )
                    {
                        $scheduleType = 'Monthly'
                        $monthsNode = $trigger.ScheduleByMonth.Months
                        $days = $trigger.ScheduleByMonth.DaysOfMonth.ChildNodes | ForEach-Object { $_.InnerText }
                        if( $days -eq 'Last' )
                        {
                            $modifier = 'LastDay'
                            $days = $null
                        }
                        else
                        {
                            switch( $monthsNode.ChildNodes.Count )
                            {
                                12 { $modifier = 1 }
                                6 { $modifier = 2 }
                                4 { $modifier = 3 }
                                3 { $modifier = 4 }
                                2 {
                                    switch( $monthsNode.ChildNodes[0].Name )
                                    {
                                        'May' { $modifier = 5 }
                                        'June' { $modifier = 6 }
                                    }
                                }
                                1 { 
                                    switch( $monthsNode.ChildNodes[0].Name )
                                    {
                                        'July' { $modifier = 7 }
                                        'August' { $modifier = 8 }
                                        'September' { $modifier = 9 }
                                        'October' { $modifier = 10 }
                                        'November' { $modifier = 11 }
                                        'December' { $modifier = 12 }
                                    }
                                }
                            }
                        }

                        foreach( $monthNode in $monthsNode.ChildNodes )
                        {
                            $months = $months -bor ([Carbon.TaskScheduler.Months]$monthNode.Name)
                        }
                    }
                }
            }
            else
            {
                Write-Verbose ('Task ''{0}'' has no triggers.' -f $task.FullName)
            }

            $scheduleCtorArgs = @(
                                    $csvTask.'Last Result',
                                    $csvTask.'Stop Task If Runs X Hours And X Mins',
                                    $scheduleType,
                                    $modifier,
                                    $csvTask.'Start Time',
                                    $csvTask.'Start Date',
                                    $csvTask.'End Date',
                                    $days,
                                    $months,
                                    $csvTask.'Repeat: Every',
                                    $csvTask.'Repeat: Until: Time',
                                    $duration,
                                    $csvTask.'Repeat: Stop If Still Running'
                                )

            $schedule = New-Object -TypeName 'Carbon.TaskScheduler.ScheduleInfo' -ArgumentList $scheduleCtorArgs |
                            Add-Member -MemberType NoteProperty -Name 'StopAtEnd' -Value $stopAtEnd -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Interval' -Value $interval -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'EndTime' -Value $endTime -PassThru
            $task.Schedules.Add( $schedule )
        }
        --$idx;

        if( -not $wildcardSearch -or $task.FullName -like $Name )
        {
            $task
        }
    }

}