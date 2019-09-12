
function Get-CDscError
{
    <#
    .SYNOPSIS
    Gets DSC errors from a computer's event log.

    .DESCRIPTION
    The DSC Local Configuration Manager (LCM) writes any errors it encounters to the `Microsoft-Windows-DSC/Operational` event log, in addition to some error messages that report that encountered an error. This function gets just the important error log messages, skipping the superflous ones that won't help you track down where the problem is.

    By default, errors on the local computer are returned. You can return errors from another computer via the `ComputerName` parameter.

    You can filter the results further with the `StartTime` and `EndTime` parameters. `StartTime` will return entries after the given time. `EndTime` will return entries before the given time.

    If no items are found, nothing is returned.

    It can take several seconds for event log entries to get written to the log, so you might not get results back. If you want to wait for entries to come back, use the `-Wait` switch. You can control how long to wait (in seconds) via the `WaitTimeoutSeconds` parameter. The default is 10 seconds.

    When getting errors on a remote computer, that computer must have Remote Event Log Management firewall rules enabled. To enable them, run

        Get-CFirewallRule -Name '*Remove Event Log Management*' |
            ForEach-Object { netsh advfirewall firewall set rule name= $_.Name new enable=yes }

    `Get-CDscError` is new in Carbon 2.0.

    .OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

    .LINK
    Write-CDscError

    .EXAMPLE
    Get-CDscWinEvent

    Demonstrates how to get all the DSC errors from the local computer.

    .EXAMPLE
    Get-CDscError -ComputerName 10.1.2.3

    Demonstrates how to get all the DSC errors from a specific computer.

    .EXAMPLE
    Get-CDscError -StartTime '8/1/2014 0:00'

    Demonstrates how to get errors that occurred *after* a given time.

    .EXAMPLE
    Get-CDscError -EndTime '8/30/2014 11:59:59'

    Demonstrates how to get errors that occurred *before* a given time.

    .EXAMPLE
    Get-CDscError -StartTime '8/1/2014 2:58 PM' -Wait -WaitTimeoutSeconds 5

    Demonstrates how to wait for entries that match the specified criteria to appear in the event log. It can take several seconds between the time a log entry is written to when you can read it.
    #>
    [CmdletBinding(DefaultParameterSetName='NoWait')]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [string[]]
        # The computer whose DSC errors to return.
        $ComputerName,

        [DateTime]
        # Get errors that occurred after this date/time.
        $StartTime,

        [DateTime]
        # Get errors that occurred before this date/time.
        $EndTime,

        [Parameter(Mandatory=$true,ParameterSetName='Wait')]
        [Switch]
        # Wait for entries to appear, as it can sometimes take several seconds for entries to get written to the event log.
        $Wait,

        [Parameter(ParameterSetName='Wait')]
        [uint32]
        # The time to wait for entries to appear before giving up. Default is 10 seconds. There is no way to wait an infinite amount of time.
        $WaitTimeoutSeconds = 10
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-CDscWinEvent @PSBoundParameters -ID 4103 -Level ([Diagnostics.Eventing.Reader.StandardEventLevel]::Error)
}
