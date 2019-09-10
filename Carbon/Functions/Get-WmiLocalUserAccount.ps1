
function Get-CWmiLocalUserAccount
{
    <#
    .SYNOPSIS
    Gets a WMI `Win32_UserAccount` object for a *local* user account.

    .DESCRIPTION
    Man, there are so many ways to get a user account in Windows.  This function uses WMI to get a local user account.  It returns a `Win32_UserAccount` object.  The username has to be less than 20 characters.  We don't remember why anymore, but it's probaly a restriction of WMI.  Or Windows.  Or both.

    You can do this with `Get-WmiObject`, but when you try to get a `Win32_UserAccount`, PowerShell reaches out to your domain and gets all the users it finds, even if you filter by name.  This is slow!  This function stops WMI from talking to your domain, so it is faster.

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa394507(v=vs.85).aspx

    .EXAMPLE
    Get-CWmiLocalUserAccount -Username Administrator

    Gets the local Administrator account as a `Win32_UserAccount` WMI object.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(0,20)]
        [string]
        # The username of the local user to get.
        $Username
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    return Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)' and Name='$Username'"
}

