
function Test-CPerformanceCounter
{
    <#
    .SYNOPSIS
    Tests if a performance counter exists.

    .DESCRIPTION
    Returns `True` if counter `Name` exists in category `CategoryName`.  `False` if it does not exist or the category doesn't exist.

    .EXAMPLE
    Test-CPerformanceCounter -CategoryName 'ToyotaCamry' -Name 'MilesPerGallon'

    Returns `True` if the `ToyotaCamry` performance counter category has a `MilesPerGallon` counter.  `False` if the counter doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name where the performance counter exists.  Or might exist.  As the case may be.
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CPerformanceCounterCategory -CategoryName $CategoryName) )
    {
        return [Diagnostics.PerformanceCounterCategory]::CounterExists( $Name, $CategoryName )
    }
    
    return $false
}

