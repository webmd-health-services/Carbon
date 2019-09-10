
function Enable-CAclInheritance
{
    <#
    .SYNOPSIS
    Enables ACL inheritance on an item.
    
    .DESCRIPTION
    Items in the registry or file system will usually inherit ACLs from its parent. This inheritance can be disabled, either via Carbon's `Protect-Acl` function or using .NET's securei API. The `Enable-CAclInheritance` function re-enables inheritance on containers where it has been disabled. By default, any explicit permissions on the item are removed. Use the `-Preserve` switch to keep any existing, explicit permissions on the item.
    
    This function is paired with `Disable-CAclInheritance`. 

    This function was added in Carbon 2.4.

    .LINK
    Disable-CAclInheritance
    
    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission

    .EXAMPLE
    Enable-CAclInheritance -Path C:\Projects\Carbon
    
    Re-enables ACL inheritance on `C:\Projects\Carbon`. ACLs on `C:\Projects` will be inherited to and affect `C:\Projects\Carbon`. Any explicit ACLs on `C:\Projects\Carbon` are removed.
    
    .EXAMPLE
    Enable-CAclInheritance -Path hklm:\Software\Carbon -Preserve
    
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
            Get-CPermission -Path $Path | ForEach-Object { Revoke-CPermission -Path $Path -Identity $_.IdentityReference }
        }
    }
}
