
function Disable-CAclInheritance
{
    <#
    .SYNOPSIS
    Protects an ACL so that changes to its parent can't be inherited to it.
    
    .DESCRIPTION
    Items in the registry or file system will inherit permissions from its parent.  The `Disable-AclInheritnace` function disables inheritance, removing all inherited permissions. You can optionally preserve the currently inherited permission as explicit permissions using the `-Preserve` switch.
    
    This function is paired with `Enable-CAclInheritance`.

    Beginning in Carbon 2.4, this function will only disable inheritance if it is currently enabled. In previous versions, it always disabled inheritance.

    .LINK
    Disable-CAclInheritance
    
    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission
    
    .EXAMPLE
    Disable-CAclInheritance -Path C:\Projects\Carbon
    
    Removes all inherited access rules from the `C:\Projects\Carbon` directory.  Non-inherited rules are preserved.
    
    .EXAMPLE
    Disable-CAclInheritance -Path hklm:\Software\Carbon -Preserve
    
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

Set-Alias -Name 'Unprotect-AclAccessRules' -Value 'Disable-CAclInheritance'
Set-Alias -Name 'Protect-Acl' -Value 'Disable-CAclInheritance'

