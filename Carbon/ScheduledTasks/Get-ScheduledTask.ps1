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
    The `Get-ScheduledTask` function gets the scheduled tasks on the current computer. It returns `Carbon.ScheduledTaskInfo` objects for each one.

    With no parameters, `Get-ScheduledTask` returns all scheduled tasks. To get a specific scheduled task, use the `Name` parameter. The name parameter accepts wildcards. If a scheduled task with the given name isn't found, an error is written.

    This function has the same name as the built-in `Get-ScheduledTask` function that comes on Windows 2012/8 and later. It returns objects with the same properties, but if you want to use the built-in function, use the `ScheduledTasks` qualifier, e.g. `ScheduledTasks\Get-ScheduledTask`.

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
    [OutputType([Carbon.ScheduledTaskInfo])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported.
        $Name
    )

    Set-StrictMode -Version 'Latest'

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
            $optionalArgs = @( '/tn', $Name )
        }
    }

    $originalErrPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Get-ScheduledTask+{0}' -f [IO.Path]::GetRandomFileName())
    schtasks /query /v /fo csv $optionalArgs 2> $errFile | ConvertFrom-Csv |
        Where-Object { $_.HostName -ne 'HostName' } |
        ForEach-Object { 
                $ctorArgs = @(
                                $_.HostName,
                                $_.TaskName,
                                $_.'Next Run Time',
                                $_.Status,
                                $_.'Logon Mode',
                                $_.'Last Run Time',
                                $_.'Last Result',
                                $_.Author,
                                $_.'Task To Run',
                                $_.'Start In',
                                $_.Comment,
                                $_.'Scheduled Task State',
                                $_.'Idle Time',
                                $_.'Power Management',
                                $_.'Run As User',
                                $_.'Delete Task If Not Rescheduled',
                                $_.'Stop Task If Runs X Hours And X Mins',
                                $_.Schedule,
                                $_.'Schedule Type',
                                $_.'Start Time',
                                $_.'Start Date',
                                $_.'End Date',
                                $_.Days,
                                $_.Months,
                                $_.'Repeat: Every',
                                $_.'Repeat: Until: Time',
                                $_.'Repeat: Until: Duration',
                                $_.'Repeat: Stop If Still Running'
                            )
                New-Object -TypeName 'Carbon.ScheduledTaskInfo' -ArgumentList $ctorArgs
            } |
        Where-Object { 
            if( $wildcardSearch )
            {
                return ($_.TaskName -like $Name)
            }
            return $true
        }

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
    }
}