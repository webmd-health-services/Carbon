
function Revoke-CServicePermission
{
    <#
    .SYNOPSIS
    Removes all permissions an identity has to manage a service.
    
    .DESCRIPTION
    No permissions are left behind.  This is an all or nothing operation, baby!
    
    .LINK
    Get-CServicePermission
    
    .LINK
    Grant-CServicePermission
    
    .EXAMPLE
    Revoke-CServicePermission -Name 'Hyperdrive` -Identity 'CLOUDCITY\LCalrissian'
    
    Removes all of Lando's permissions to control the `Hyperdrive` service.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose permissions are being revoked.
        $Identity
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = Resolve-CIdentity -Name $Identity
    if( -not $account )
    {
        return
    }
    
    if( -not (Assert-CService -Name $Name) )
    {
        return
    }
    
    if( (Get-CServicePermission -Name $Name -Identity $account.FullName) )
    {
        Write-Verbose ("Revoking {0}'s {1} service permissions." -f $account.FullName,$Name)
        
        $dacl = Get-CServiceAcl -Name $Name
        $dacl.Purge( $account.Sid )
        
        Set-CServiceAcl -Name $Name -Dacl $dacl
    }
 }
 
