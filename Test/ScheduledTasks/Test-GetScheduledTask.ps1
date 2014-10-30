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

        if( $task -is 'Object[]' )
        {
            return
        }

        Assert-ScheduledTaskEqual $expectedTask $task
    }
}

function Test-ShouldSupportWildcards
{
    $expectedTask = schtasks /query /v /fo csv | Select-Object -First 2 | ConvertFrom-Csv
    $task = Get-ScheduledTask -Name ('*{0}*' -f $expectedTask.TaskName.Substring(1,$expectedTask.TaskName.Length - 2))
    Assert-NotNull $task
    Assert-ScheduledTaskEqual $expectedTask $task
}

function Test-ShouldGetAllScheduledTasks
{
    $expectedTasks = schtasks /query /v /fo csv | ConvertFrom-Csv | Where-Object { $_.TaskName -and $_.HostName -ne 'HostName' }
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
                                }

    foreach( $property in (Get-Member -InputObject $Expected -MemberType NoteProperty) )
    {
        $columnName = $property.Name
        $propertyName = $columnName -replace '[^A-Za-z0-9_]',''
        if( $propertyName -eq 'NextRunTime' -and $randomNextRunTimeTasks.ContainsKey($task.TaskName) )
        {
            # This task's next run time changes every time you retrieve it.
            continue
        }
        $failMsg = '{0}; column {1}; property {2}' -f $Actual.TaskName,$columnName,$propertyName
        Assert-NotNull ($Actual | Get-Member -Name $propertyName) $failMsg
        Assert-Equal $Expected.$columnName $Actual.$propertyName $failMsg
    }
}
