
function Test-CPerformanceCounterCategory
{
    <#
    .SYNOPSIS
    Tests if a performance counter category exists.

    .DESCRIPTION
    Returns `True` if category `CategoryName` exists.  `False` if it does not exist.

    .EXAMPLE
    Test-CPerformanceCounterCategory -CategoryName 'ToyotaCamry'

    Returns `True` if the `ToyotaCamry` performance counter category exists.  `False` if the category doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the cateogry whose existence to check.
        $CategoryName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return [Diagnostics.PerformanceCounterCategory]::Exists( $CategoryName )
}

