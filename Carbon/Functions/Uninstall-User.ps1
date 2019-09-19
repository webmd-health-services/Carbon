
function Uninstall-CUser
{
    <#
    .SYNOPSIS
    Removes a user from the local computer.

    .DESCRIPTION
    Removes a *local* user account.  If the account doesn't exist, nothing happens.

    .LINK
    Get-CUser

    .LINK
    Install-CUser

    .LINK
    Test-CUser

    .LINK
    Uninstall-CUser

    .EXAMPLE
    Uninstall-CUser -Username WTarkin

    Removes the `WTarkin` *local* user account.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username of the account to remove.
        $Username
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( Test-CUser -Username $username )
    {
        $user = Get-CUser -Username $Username
        try
        {
            if( $pscmdlet.ShouldProcess( $Username, "remove local user" ) )
            {
                $user.Delete()
            }
        }
        finally
        {
            $user.Dispose()
        }
    }
}

Set-Alias -Name 'Remove-User' -Value 'Uninstall-CUser'

