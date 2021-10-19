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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity of the principal whose privileges to get.
        $Identity,
        
        [AllowEmptyCollection()]
        [string[]]
        # The user's expected/desired privileges.
        $Privilege = @(),
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    [string[]]$currentPrivileges = Get-CPrivilege -Identity $Identity
    $Ensure = 'Present'
    if( -not $currentPrivileges )
    {
        [string[]]$currentPrivileges = @()
    }

    foreach( $item in $Privilege )
    {
        if( $currentPrivileges -notcontains $item )
        {
            $Ensure = 'Absent'
            break
        }
    }

    foreach( $item in $currentPrivileges )
    {
        if( $Privilege -notcontains $item )
        {
            $Ensure = 'Absent'
            break
        }
    }

    $resource = @{
                    Identity = $Identity;
                    Privilege = $currentPrivileges;
                    Ensure = $Ensure;
                }

    
    return $resource
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for managing privileges.

    .DESCRIPTION
    The `Carbon_Privilege` resource manages privileges, i.e. the system operations and logons a user or group can perform.

    Privileges are granted by default. The user/group is granted only the privileges specified by the `Privilege` property. All other privileges are revoked.
    
    To revoke *all* a user's privileges, set the `Ensure` property to `Absent`. To revoke specific privileges, grant the user just the desired privileges. All others are revoked.

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

    `Carbon_Privilege` is new in Carbon 2.0.

    .LINK
    Get-CPrivilege

    .LINK
    Grant-CPrivilege

    .LINK
    Revoke-CPrivilege

    .LINK
    Test-CPrivilege

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx

    .EXAMPLE
    >
    Demonstrates how to grant a service user the ability to log in as a service.

        Carbon_Privilege GrantServiceLogonPrivileges
        {
            Identity = 'CarbonServiceUser'
            Privilege = 'SeBatchLogonRight','SeServiceLogonRight';
        }

    .EXAMPLE
    >
    Demonstrates how to revoke all a user/group's privileges. To revoke specific privileges, grant just the privileges you want. All other privileges are revoked.

        Carbon_Privilege RevokePrivileges
        {
            Identity = 'CarbonServiceUser'
            Ensure = 'Absent'
        }
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity of the principal whose privileges to set.
        $Identity,
        
        [AllowEmptyCollection()]
        [string[]]
        # The user's expected/desired privileges. *Privilege names are **case-sensitive**.* Ignored when `Ensure` is set to `Absent`.
        $Privilege = @(),
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $currentPrivileges = Get-CPrivilege -Identity $Identity
    if( $currentPrivileges )
    {
        Write-Verbose ('Revoking ''{0}'' privileges: {1}' -f $Identity,($currentPrivileges -join ','))
        Revoke-CPrivilege -Identity $Identity -Privilege $currentPrivileges
    }

    if( $Ensure -eq 'Present' -and $Privilege )
    {
        Write-Verbose ('Granting ''{0}'' privileges: {1}' -f $Identity,($Privilege -join ','))
        Grant-CPrivilege -Identity $Identity -Privilege $Privilege
    }
}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity of the principal whose privileges to test.
        $Identity,
        
        [AllowEmptyCollection()]
        [string[]]
        # The user's expected/desired privileges.
        $Privilege = @(),
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Identity $Identity -Privilege $Privilege

    $privilegeMissing = $resource.Ensure -eq 'Absent'
    if( $Ensure -eq 'Absent' )
    {
        $absent = $resource.Privilege.Length -eq 0
        if( $absent )
        {
            Write-Verbose ('Identity ''{0}'' has no privileges' -f $Identity)
            return $true
        }
        
        Write-Verbose ('Identity ''{0}'' has privilege(s) {1}' -f $Identity,($resource.Privilege -join ','))
        return $false
    }

    if( $privilegeMissing )
    {
        $msgParts = @()
        $extraPrivileges = $resource.Privilege | Where-Object { $Privilege -notcontains $_ }
        if( $extraPrivileges )
        {
            $msgParts += 'extra privilege(s): {0}' -f ($extraPrivileges -join ',')
        }

        $missingPrivileges = $Privilege | Where-Object { $resource.Privilege -notcontains $_ }
        if( $missingPrivileges )
        {
            $msgParts += 'missing privilege(s): {0}' -f ($missingPrivileges -join ',')
        }
        Write-Verbose ('Identity ''{0}'' {1}' -f $Identity,($msgParts -join '; '))
        return $false
    }

    return $true
}
