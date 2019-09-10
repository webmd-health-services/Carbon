
function Assert-CAdminPrivilege
{
    <#
    .SYNOPSIS
    Writes an error and returns false if the user doesn't have administrator privileges.

    .DESCRIPTION
    Many scripts and functions require the user to be running as an administrator.  This function checks if the user is running as an administrator or with administrator privileges and writes an error if the user doesn't.  

    .LINK
    Test-CAdminPrivilege

    .EXAMPLE
    Assert-CAdminPrivilege

    Writes an error that the user doesn't have administrator privileges.
    #>
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CAdminPrivilege) )
    {
        Write-Error "You are not currently running with administrative privileges.  Please re-start PowerShell as an administrator (right-click the PowerShell application, and choose ""Run as Administrator"")."
        return $false
    }
    return $true
}

Set-Alias -Name 'Assert-AdminPrivileges' -Value 'Assert-CAdminPrivilege'

