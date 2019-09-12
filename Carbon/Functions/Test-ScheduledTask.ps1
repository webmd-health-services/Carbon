
function Test-CScheduledTask
{
    <#
    .SYNOPSIS
    Tests if a scheduled task exists on the current computer.

    .DESCRIPTION
    The `Test-CScheduledTask` function uses `schtasks.exe` to tests if a task with a given name exists on the current computer. If it does, `$true` is returned. Otherwise, `$false` is returned. This name must be the *full task name*, i.e. the task's path/location and its name.

    .LINK
    Get-CScheduledTask

    .EXAMPLE
    Test-CScheduledTask -Name 'AutoUpdateMyApp'

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
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Name = Join-Path -Path '\' -ChildPath $Name

    $task = Get-CScheduledTask -Name $Name -AsComObject -ErrorAction Ignore
    if( $task )
    {
        return $true
    }
    else
    {
        return $false
    }
}
