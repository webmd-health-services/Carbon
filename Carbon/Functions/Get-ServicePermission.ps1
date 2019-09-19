
function Get-CServicePermission
{
    <#
    .SYNOPSIS
    Gets the permissions for a service.
    
    .DESCRIPTION
    Uses the Win32 advapi32 API to query the permissions for a service.  Returns `Carbon.ServiceAccessRule` objects for each.  The two relavant properties on this object are
    
     * IdentityReference - The identity of the permission.
     * ServiceAccessRights - The permissions the user has.
     
    .OUTPUTS
    Carbon.Security.ServiceAccessRule.
    
    .LINK
    Grant-ServicePermissions
    
    .LINK
    Revoke-ServicePermissions
    
    .EXAMPLE
    Get-CServicePermission -Name 'Hyperdrive'
    
    Gets the access rules for the `Hyperdrive` service.
    
    .EXAMPLE
    Get-CServicePermission -Name 'Hyperdrive' -Identity FALCON\HSolo
    
    Gets just Han's permissions to control the `Hyperdrive` service.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service whose permissions to return.
        $Name,
        
        [string]
        # The specific identity whose permissions to get.
        $Identity
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $dacl = Get-CServiceAcl -Name $Name
    
    $account = $null
    if( $Identity )
    {
        $account = Resolve-CIdentity -Name $Identity
        if( -not $account )
        {
            return
        }
    }

    $dacl |
        ForEach-Object {
            $ace = $_
            
            $aceSid = $ace.SecurityIdentifier;
            if( $aceSid.IsValidTargetType([Security.Principal.NTAccount]) )
            {
                try
                {
                    $aceSid = $aceSid.Translate([Security.Principal.NTAccount])
                }
                catch [Security.Principal.IdentityNotMappedException]
                {
                    # user doesn't exist anymore.  So sad.
                }
            }

            if ($ace.AceType -eq [Security.AccessControl.AceType]::AccessAllowed)
            {
                $ruleType = [Security.AccessControl.AccessControlType]::Allow
            }
            elseif ($ace.AceType -eq [Security.AccessControl.AceType]::AccessDenied)
            {
                $ruleType = [Security.AccessControl.AccessControlType]::Deny
            }
            else
            {
                Write-Error ("Unsupported aceType {0}." -f $ace.AceType)
                return
            }
            New-Object Carbon.Security.ServiceAccessRule $aceSid,$ace.AccessMask,$ruleType            
        } |
        Where-Object { 
            if( $account )
            {
                return ($_.IdentityReference.Value -eq $account.FullName)
            }
            return $_
        }
}

Set-Alias -Name 'Get-ServicePermissions' -Value 'Get-CServicePermission'

