
function Test-CPrivilege
{
    <#
    .SYNOPSIS
    Tests if an identity has a given privilege.
    
    .DESCRIPTION
    Returns `true` if an identity has a privilege.  `False` otherwise.

    .LINK
    Carbon_Privilege

    .LINK
    Get-CPrivilege

    .LINK
    Grant-CPrivilege

    .LINK
    Revoke-CPrivilege
    
    .EXAMPLE
    Test-CPrivilege -Identity Forrester -Privilege SeServiceLogonRight
    
    Tests if `Forrester` has the `SeServiceLogonRight` privilege.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose privileges to check.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The privilege to check.
        $Privilege
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $matchingPrivilege = Get-CPrivilege -Identity $Identity |
                            Where-Object { $_ -eq $Privilege }
    return ($matchingPrivilege -ne $null)
}

