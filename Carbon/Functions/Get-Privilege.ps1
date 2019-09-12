
function Get-CPrivilege
{
    <#
    .SYNOPSIS
    Gets an identity's privileges.
    
    .DESCRIPTION
    These privileges are usually managed by Group Policy and control the system operations and types of logons a user/group can perform.
    
    Note: if a computer is not on a domain, this function won't work.
    
    .OUTPUTS
    System.String
    
    .LINK
    Carbon_Privilege

    .LINK
    Grant-CPrivilege
    
    .LINK
    Revoke-Prvileges
    
    .LINK
    Test-CPrivilege
    
    .EXAMPLE
    Get-CPrivilege -Identity TheBeast
    
    Gets `TheBeast`'s privileges as an array of strings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose privileges to return.
        $Identity
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [Carbon.Security.Privilege]::GetPrivileges( $Identity )
}

Set-Alias -Name 'Get-Privileges' -Value 'Get-CPrivilege'

