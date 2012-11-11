
function Get-Privileges
{
    <#
    .SYNOPSIS
    Gets the privileges and identity has to perform system operations.
    
    .DESCRIPTION
    These privileges are usually managed by Group Policy.
    
    Note: if a computer is not on a domain, this function won't work.
    
    .OUTPUTS
    System.String.
    
    .LINK
    Grant-Privilege
    
    .LINK
    Revoke-Prvileges
    
    .LINK
    Test-Privilege
    
    .EXAMPLE
    
    Get-Privileges -Identity TheBeast
    
    Gets TheBeast's privileges as an array of strings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose privileges to return.
        $Identity
    )
    
    [Carbon.Lsa]::GetPrivileges( $Identity )
}

function Grant-Privilege
{
    <#
    .SYNOPSIS
    Grants an identity priveleges to perform system operations.
    
    .DESCRIPTION
    The most current list of privileges can be found [on Microsoft's website](http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx). Here is the most current list, as of November 2012:

     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeBatchLogonRight
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
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
     * SeInteractiveLogonRight
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeNetworkLogonRight
     * SeProfileSingleProcessPrivilege
     * SeRestorePrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeReserveProcessorPrivilege
     * SeSecurityPrivilege
     * SeServiceLogonRight
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx
    
    .LINK
    Get-Privileges
    
    .LINK
    Revoke-Privilege
    
    .LINK
    Test-Privilege
    
    .EXAMPLE
    Grant-Privilege -Identity Batcomputer -Privilege SeServiceLogonRight
    
    Grants the Batcomputer account the ability to logon as a service.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity to grant a privilege.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The privileges to grant.
        $Privilege
    )
    [Carbon.Lsa]::GrantPrivileges( $Identity, $Privilege )
}

function Revoke-Privilege
{
    <#
    .SYNOPSIS
    Revokes an identity's priveleges to perform system operations.
    
    .DESCRIPTION
    The most current list of privileges can be found [on Microsoft's website](http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx). Here is the most current list, as of November 2012:

     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeBatchLogonRight
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
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
     * SeInteractiveLogonRight
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeNetworkLogonRight
     * SeProfileSingleProcessPrivilege
     * SeRestorePrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeReserveProcessorPrivilege
     * SeSecurityPrivilege
     * SeServiceLogonRight
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx
    
    .LINK
    Get-Privileges
    
    .LINK
    Grant-Privilege
    
    .LINK
    Test-Privilege
    
    .EXAMPLE
    Revoke-Privilege -Identity Batcomputer -Privilege SeServiceLogonRight
    
    Revokes the Batcomputer account's ability to logon as a service.  Don't restart that thing!
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity to grant a privilege.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The privileges to grant.
        $Privilege
    )
    
    [Carbon.Lsa]::RevokePrivileges($Identity,$Privilege)
}

function Test-Privilege
{
    <#
    .SYNOPSIS
    Tests if an identity has a given privilege.
    
    .DESCRIPTION
    Returns `true` if an identity has a privilege.  `False` otherwise.
    
    .EXAMPLE
    Test-Privilege -Identity Forrester -Privilege SeServiceLogonRight
    
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
    
    $matchingPrivilege = Get-Privileges -Identity $Identity |
                            Where-Object { $_ -eq $Privilege }
    return ($matchingPrivilege -ne $null)
}
