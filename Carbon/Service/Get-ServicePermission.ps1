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

function Get-ServicePermission
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
    Get-ServicePermission -Name 'Hyperdrive'
    
    Gets the access rules for the `Hyperdrive` service.
    
    .EXAMPLE
    Get-ServicePermission -Name 'Hyperdrive' -Identity FALCON\HSolo
    
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
    
    $dacl = Get-ServiceAcl -Name $Name
    
    $rIdentity = $null
    if( $Identity )
    {
        $rIdentity = Resolve-IdentityName -Name $Identity
        if( -not $rIdentity )
        {
            Write-Error ("Identity {0} not found." -f $identity)
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
            if( $rIdentity )
            {
                return ($_.IdentityReference.Value -eq $rIdentity)
            }
            return $_
        }
}

Set-Alias -Name 'Get-ServicePermissions' -Value 'Get-ServicePermission'
