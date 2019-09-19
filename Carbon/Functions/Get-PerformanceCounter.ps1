
function Get-CPerformanceCounter
{
    <#
    .SYNOPSIS
    Gets the performance counters for a category.

    .DESCRIPTION
    Returns `PerformanceCounterCategory` objects for the given category name.  If not counters exist for the category exits, an empty array is returned.

    .OUTPUTS
    System.Diagnostics.PerformanceCounterCategory.

    .EXAMPLE
    Get-CPerformanceCounter -CategoryName Processor

    Gets all the `Processor` performance counters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name whose performance counters will be returned.
        $CategoryName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CPerformanceCounterCategory -CategoryName $CategoryName) )
    {
        $category = New-Object Diagnostics.PerformanceCounterCategory $CategoryName
        return $category.GetCounters("")
    }
}

Set-Alias -Name 'Get-PerformanceCounters' -Value 'Get-CPerformanceCounter'

