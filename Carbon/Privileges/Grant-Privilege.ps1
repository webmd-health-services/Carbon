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

function Grant-Privilege
{
    <#
    .SYNOPSIS
    Grants an identity priveleges to perform system operations.
    
    .DESCRIPTION
    *Privilege names are **case-sensitive**.* The most current list of privileges can be found [on Microsoft's website](http://msdn.microsoft.com/en-us/library/windows/desktop/aa375728(v=vs.85).aspx). Here is the most current list, as of November 2012:

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
    Revoke-Privilege
    
    .LINK
    Test-Privilege
    
    .EXAMPLE
    Grant-Privilege -Identity Batcomputer -Privilege SeServiceLogonRight
    
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
    
    if( -not (Test-Identity -Name $Identity) )
    {
        Write-Error -Message ('[Carbon] [Grant-Privilege] Identity {0} not found.' -f $Identity) `
                    -Category ObjectNotFound
        return
    }
    
    try
    {
        [Carbon.Lsa]::GrantPrivileges( $Identity, $Privilege )
    }
    catch
    {
        $ex = $_.Exception
        do
        {
            if( $ex -is [ComponentModel.Win32Exception] -and $ex.Message -eq 'No such privilege. Indicates a specified privilege does not exist.' )
            {
                $msg = 'Failed to grant {0} {1} privilege(s): {2}  *Privilege names are **case-sensitive**.*' -f `
                        $Identity,($Privilege -join ','),$ex.Message
                Write-Error -Message $msg -Exception $ex
                return
            }
            else
            {
                $ex = $ex.InnerException
            }
        }
        while( $ex )

        $ex = $_.Exception        
        Write-Error -Message ('Failed to grant {0} {1} privilege(s): {2}' -f $Identity,($Privilege -join ', '),$ex.Message) `
                    -Exception $ex
        
        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}
