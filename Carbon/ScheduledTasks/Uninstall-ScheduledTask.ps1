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

function Uninstall-ScheduledTask
{
    <#
    .SYNOPSIS
    Uninstalls a scheduled task on the current computer.

    .DESCRIPTION
    The `Uninstall-ScheduledTask` function uses `schtasks.exe` to uninstall a scheduled task on the current computer. If the task doesn't exist, nothing happens.

    .LINK
    Get-ScheduledTask

    .LINK
    Test-ScheduledTask

    .LINK
    Install-ScheduledTask

    .EXAMPLE
    Uninstall-ScheduledTask -Name 'doc' 

    Demonstrates how to delete a scheduled task named `doc`.

    .EXAMPLE
    Uninstall-ScheduledTask -Name 'doc' -Force

    Demonstrates how to delete a scheduled task that is currently running.
    #>
    [CmdletBinding(DefaultParameterSetName='AsBuiltinPrincipal')]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to uninstall.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $Name = Join-Path -Path '\' -ChildPath $Name

    if( -not (Test-ScheduledTask -Name $Name) )
    {
        Write-Verbose ('Scheduled task ''{0}'' not found.' -f $Name)
        return
    }

    $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Uninstall-ScheduledTask+{0}' -f ([IO.Path]::GetRandomFileName()))
    schtasks.exe /delete /tn $Name '/F' 2> $errFile | ForEach-Object { 
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

    if( $LASTEXITCODE )
    {
        Write-Error ((Get-Content -Path $errFile) -join ([Environment]::NewLine))
    }
}