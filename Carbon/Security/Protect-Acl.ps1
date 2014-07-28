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

function Protect-Acl
{
    <#
    .SYNOPSIS
    Protects an ACL so that changes to its parent can't be inherited to it.
    
    .DESCRIPTION
    New items in the registry or file system will usually inherit ACLs from its parent.  This function stops an item from inheriting rules from its, and will optionally preserve the existing inherited rules.  Any existing, non-inherited access rules are left in place.
    
    .LINK
    Grant-Permission
    
    .EXAMPLE
    Protect-Acl -Path C:\Projects\Carbon
    
    Removes all inherited access rules from the `C:\Projects\Carbon` directory.  Non-inherited rules are preserved.
    
    .EXAMPLE
    Protect-Acl -Path hklm:\Software\Carbon -Preserve
    
    Stops `HKLM:\Software\Carbon` from inheriting acces rules from its parent, but preserves the existing, inheritied access rules.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]
        # The file system or registry path whose 
        $Path,
        
        [Switch]
        # Keep the inherited access rules on this item.
        $Preserve
    )
    
    Write-Verbose "Removing access rule inheritance on '$Path'."
    $acl = Get-Acl -Path $Path
    $acl.SetAccessRuleProtection( $true, $Preserve )
    $acl | Set-Acl -Path $Path
}

Set-Alias -Name Unprotect-AclAccessRules -Value Protect-Acl
