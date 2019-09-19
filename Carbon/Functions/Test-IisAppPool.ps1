
function Test-CIisAppPool
{
    <# 
    .SYNOPSIS
    Checks if an app pool exists.

    .DESCRIPTION 
    Returns `True` if an app pool with `Name` exists.  `False` if it doesn't exist.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Test-CIisAppPool -Name Peanuts

    Returns `True` if the Peanuts app pool exists, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app pool.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name
    if( $appPool )
    {
        return $true
    }
    
    return $false
}

Set-Alias -Name 'Test-IisAppPoolExists' -Value 'Test-CIisAppPool'
