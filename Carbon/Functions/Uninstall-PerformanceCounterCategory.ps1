
function Uninstall-CPerformanceCounterCategory
{
    <#
    .SYNOPSIS
    Removes an entire performance counter category.

    .DESCRIPTION
    Removes, with extreme prejudice, the performance counter category `CategoryName`.  All its performance counters are also deleted.  If the performance counter category doesn't exist, nothing happens.  I hope you have good backups!  

    .EXAMPLE
    Uninstall-CPerformanceCounterCategory -CategoryName 'ToyotaCamry'

    Removes the `ToyotaCamry` performance counter category and all its performance counters.  So sad!
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's category name that should be deleted.
        $CategoryName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CPerformanceCounterCategory -CategoryName $CategoryName) )
    {
        if( $pscmdlet.ShouldProcess( $CategoryName, 'uninstall performance counter category' ) )
        {
            [Diagnostics.PerformanceCounterCategory]::Delete( $CategoryName )
        }
    }
}

