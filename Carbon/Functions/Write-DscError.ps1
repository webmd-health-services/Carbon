
function Write-CDscError
{
    <#
    .SYNOPSIS
    Writes DSC errors out as errors.

    .DESCRIPTION
    The Local Configuration Manager (LCM) applies configuration in a separate process space as a background service which writes its errors to the `Microsoft-Windows-DSC/Operational` event log. This function is intended to be used with `Get-CDscError`, and will write errors returned by that function as PowerShell errors.

    `Write-CDscError` is new in Carbon 2.0.

    .OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

    .LINK
    Get-CDscError

    .EXAMPLE
    Get-CDscError | Write-CDscError

    Demonstrates how `Write-CDscError` is intended to be used. `Get-CDscError` gets the appropriate event objects that `Write-CDscError` writes out.
    #>
    [CmdletBinding()]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Diagnostics.Eventing.Reader.EventLogRecord[]]
        # The error record to write out as an error.
        $EventLogRecord,

        [Switch]
        # Return the event log record after writing an error.
        $PassThru
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        foreach( $record in $EventLogRecord )
        {
            [string[]]$property = $record.Properties | Select-Object -ExpandProperty Value

            $message = $property[-1]

            Write-Error -Message ('[{0}] [{1}] [{2}] {3}' -f $record.TimeCreated,$record.MachineName,($property[0..($property.Count - 2)] -join '] ['),$message)

            if( $PassThru )
            {
                return $record
            }
        }
    }
}
