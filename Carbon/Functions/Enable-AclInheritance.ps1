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

function Enable-AclInheritance
{
    <#
    .SYNOPSIS
    Enables ACL inheritance on an item.
    
    .DESCRIPTION
    Items in the registry or file system will usually inherit ACLs from its parent. This inheritance can be disabled, either via Carbon's `Protect-Acl` function or using .NET's securei API. The `Enable-AclInheritance` function re-enables inheritance on containers where it has been disabled. By default, any explicit permissions on the item are removed. Use the `-Preserve` switch to keep any existing, explicit permissions on the item.
    
    This function is paired with `Disable-AclInheritance`. 

    This function was added in Carbon 2.4.

    .LINK
    Disable-AclInheritance
    
    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Revoke-Permission

    .EXAMPLE
    Enable-AclInheritance -Path C:\Projects\Carbon
    
    Re-enables ACL inheritance on `C:\Projects\Carbon`. ACLs on `C:\Projects` will be inherited to and affect `C:\Projects\Carbon`. Any explicit ACLs on `C:\Projects\Carbon` are removed.
    
    .EXAMPLE
    Enable-AclInheritance -Path hklm:\Software\Carbon -Preserve
    
    Re-enables ACL inheritance on `hklm:\Software\Carbon`. ACLs on `hklm:\Software` will be inherited to and affect `hklm:\Software\Carbon`. Any explicit ACLs on `C:\Projects\Carbon` are kept.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string]
        # The file system or registry path who should start inheriting ACLs from its parent.
        $Path,
        
        [Switch]
        # Keep the explicit access rules defined on the item.
        $Preserve
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $acl = Get-Acl -Path $Path
    if( $acl.AreAccessRulesProtected )
    {
        Write-Verbose -Message ('[{0}] Enabling access rule inheritance.' -f $Path)
        $acl.SetAccessRuleProtection($false, $Preserve)
        $acl | Set-Acl -Path $Path

        if( -not $Preserve )
        {
            Get-Permission -Path $Path | ForEach-Object { Revoke-Permission -Path $Path -Identity $_.IdentityReference }
        }
    }
}
