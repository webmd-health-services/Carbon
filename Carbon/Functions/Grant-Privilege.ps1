
function Grant-CPrivilege
{
    <#
    .SYNOPSIS
    Grants an identity priveleges to perform system operations.
    
    .DESCRIPTION
    *Privilege names are **case-sensitive**.* Valid privileges are documented on Microsoft's website: [Privilege Constants](http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx) and [Account Right Constants](http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx). Here is the most current list, as of August 2014:

     * SeAssignPrimaryTokenPrivilege
     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeBatchLogonRight
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
     * SeCreateSymbolicLinkPrivilege
     * SeCreateTokenPrivilege
     * SeDebugPrivilege
     * SeDenyBatchLogonRight
     * SeDenyInteractiveLogonRight
     * SeDenyNetworkLogonRight
     * SeDenyRemoteInteractiveLogonRight
     * SeDenyServiceLogonRight
     * SeEnableDelegationPrivilege
     * SeImpersonatePrivilege
     * SeIncreaseBasePriorityPrivilege
     * SeIncreaseQuotaPrivilege
     * SeIncreaseWorkingSetPrivilege
     * SeInteractiveLogonRight
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeNetworkLogonRight
     * SeProfileSingleProcessPrivilege
     * SeRelabelPrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeRestorePrivilege
     * SeSecurityPrivilege
     * SeServiceLogonRight
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTimeZonePrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    .LINK
    Get-CPrivilege
    
    .LINK
    Revoke-CPrivilege
    
    .LINK
    Test-CPrivilege
    
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx
    
    .EXAMPLE
    Grant-CPrivilege -Identity Batcomputer -Privilege SeServiceLogonRight
    
    Grants the Batcomputer account the ability to logon as a service. *Privilege names are **case-sensitive**.*
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity to grant a privilege.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The privileges to grant. *Privilege names are **case-sensitive**.*
        $Privilege
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $account = Resolve-CIdentity -Name $Identity
    if( -not $account )
    {
        return
    }
    
    try
    {
        [Carbon.Security.Privilege]::GrantPrivileges( $account.FullName, $Privilege )
    }
    catch
    {
        $ex = $_.Exception
        do
        {
            if( $ex -is [ComponentModel.Win32Exception] -and $ex.Message -eq 'No such privilege. Indicates a specified privilege does not exist.' )
            {
                $msg = 'Failed to grant {0} {1} privilege(s): {2}  *Privilege names are **case-sensitive**.*' -f `
                        $account.FullName,($Privilege -join ','),$ex.Message
                Write-Error -Message $msg
                return
            }
            else
            {
                $ex = $ex.InnerException
            }
        }
        while( $ex )

        $ex = $_.Exception        
        Write-Error -Message ('Failed to grant {0} {1} privilege(s): {2}' -f $account.FullName,($Privilege -join ', '),$ex.Message)
        
        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}

