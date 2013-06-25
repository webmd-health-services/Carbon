# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Revoke-Privilege
{
    <#
    .SYNOPSIS
    Revokes an identity's priveleges to perform system operations.
    
    .DESCRIPTION
    The most current list of privileges can be found [on Microsoft's website](http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728.aspx). Here is the most current list, as of November 2012:

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
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728.aspx
    
    .LINK
    Get-Privilege
    
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
    
    Set-StrictMode -Version Latest
    
    if( -not (Test-Identity -Name $Identity) )
    {
        Write-Error -Message ('[Carbon] [Revoke-Privilege] Identity {0} not found.' -f $identity) `
                    -Category ObjectNotFound
        return
    }
    
    # Convert the privileges from the user into their canonical names.
    $cPrivileges = Get-Privilege -Identity $Identity |
                        Where-Object { $Privilege -contains $_ }
    if( -not $cPrivileges )
    {
        return
    }
    
    try
    {
        [Carbon.Lsa]::RevokePrivileges($Identity,$cPrivileges)
    }
    catch
    {
        Write-Error -Message ('Failed to revoke {0}''s {1} privilege(s).' -f $Identity,($cPrivileges -join ', ')) `
                    -Exception $_.Exception

        $ex = $_.Exception
        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}
