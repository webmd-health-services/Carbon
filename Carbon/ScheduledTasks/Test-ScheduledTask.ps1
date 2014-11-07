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

function Test-ScheduledTask
{
    <#
    .SYNOPSIS
    Tests if a scheduled task exists on the current computer.

    .DESCRIPTION
    The `Test-ScheduledTask` function uses `schtasks.exe` to tests if a task with a given name exists on the current computer. If it does, `$true` is returned. Otherwise, `$false` is returned. This name must be the *full task name*, i.e. the task's path/location and its name.

    .LINK
    Get-ScheduledTask

    .EXAMPLE
    Test-ScheduledTask -Name 'AutoUpdateMyApp'

    Demonstrates how to test if a scheduled tasks exists.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to check. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $Name = Join-Path -Path '\' -ChildPath $Name

    $task = schtasks /query /fo csv 2> $null | ConvertFrom-Csv | Where-Object { $_.TaskName -eq $Name }
    if( $task )
    {
        return $true
    }
    else
    {
        return $false
    }
}