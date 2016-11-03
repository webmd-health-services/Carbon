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

function Disable-AclInheritance
{
    <#
    .SYNOPSIS
    Protects an ACL so that changes to its parent can't be inherited to it.
    
    .DESCRIPTION
    Items in the registry or file system will inherit permissions from its parent.  The `Disable-AclInheritnace` function disables inheritance, removing all inherited permissions. You can optionally preserve the currently inherited permission as explicit permissions using the `-Preserve` switch.
    
    This function is paired with `Enable-AclInheritance`.

    Beginning in Carbon 2.4, this function will only disable inheritance if it is currently enabled. In previous versions, it always disabled inheritance.

    .LINK
    Disable-AclInheritance
    
    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Revoke-Permission
    
    .EXAMPLE
    Disable-AclInheritance -Path C:\Projects\Carbon
    
    Removes all inherited access rules from the `C:\Projects\Carbon` directory.  Non-inherited rules are preserved.
    
    .EXAMPLE
    Disable-AclInheritance -Path hklm:\Software\Carbon -Preserve
    
    Stops `HKLM:\Software\Carbon` from inheriting acces rules from its parent, but preserves the existing, inheritied access rules.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string]
        # The file system or registry path whose access rule should stop inheriting from its parent.
        $Path,
        
        [Switch]
        # Keep the inherited access rules on this item.
        $Preserve
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $acl = Get-Acl -Path $Path
    if( -not $acl.AreAccessRulesProtected )
    {
        Write-Verbose -Message ("[{0}] Disabling access rule inheritance." -f $Path)
        $acl.SetAccessRuleProtection( $true, $Preserve )
        $acl | Set-Acl -Path $Path
    }
}

Set-Alias -Name 'Unprotect-AclAccessRules' -Value 'Disable-AclInheritance'
Set-Alias -Name 'Protect-Acl' -Value 'Disable-AclInheritance'

