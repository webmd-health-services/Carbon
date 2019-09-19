
function Get-CServiceAcl
{
    <#
    .SYNOPSIS
    Gets the discretionary access control list (i.e. DACL) for a service.
    
    .DESCRIPTION
    You wanted it, you got it!  You probably want to use `Get-CServicePermission` instead.  If you want to chagne a service's permissions, use `Grant-CServicePermission` or `Revoke-ServicePermissions`.
    
    .LINK
    Get-CServicePermission
    
    .LINK
    Grant-CServicePermission
    
    .LINK
    Revoke-CServicePermission
    
    .EXAMPLE
    Get-CServiceAcl -Name Hyperdrive
    
    Gets the `Hyperdrive` service's DACL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service whose DACL to return.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rawSD = Get-CServiceSecurityDescriptor -Name $Name
    $rawDacl = $rawSD.DiscretionaryAcl
    New-Object Security.AccessControl.DiscretionaryAcl $false,$false,$rawDacl
}

