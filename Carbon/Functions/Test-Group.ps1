
function Test-CGroup
{
    <#
    .SYNOPSIS
    Checks if a *local* group exists.

    .DESCRIPTION
    Uses .NET's AccountManagement API to check if a *local* group exists.  Returns `True` if the *local* account exists, or `False` if it doesn't.

    .OUTPUTS
    System.Boolean

    .LINK
    Get-CGroup

    .LINK
    Install-CGroup

    .LINK
    Uninstall-CGroup

    .EXAMPLE
    Test-CGroup -Name RebelAlliance

    Checks if the `RebelAlliance` *local* group exists.  Returns `True` if it does, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the *local* group to check.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $group = Get-CGroup -Name $Name -ErrorAction Ignore
    if( $group )
    {
        $group.Dispose()
        return $true
    }
    else
    {
        return $false
    }
}

