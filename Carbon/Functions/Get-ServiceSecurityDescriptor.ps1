
function Get-CServiceSecurityDescriptor
{
    <#
    .SYNOPSIS
    Gets the raw security descriptor for a service.
    
    .DESCRIPTION
    You probably don't want to mess with the raw security descriptor.  Try `Get-CServicePermission` instead.  Much more useful.
    
    .OUTPUTS
    System.Security.AccessControl.RawSecurityDescriptor.
    
    .LINK
    Get-CServicePermission
    
    .LINK
    Grant-ServicePermissions
    
    .LINK
    Revoke-ServicePermissions
    
    .EXAMPLE
    Get-CServiceSecurityDescriptor -Name 'Hyperdrive'
    
    Gets the hyperdrive service's raw security descriptor.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service whose permissions to return.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sdBytes = [Carbon.Service.ServiceSecurity]::GetServiceSecurityDescriptor($Name)
    New-Object Security.AccessControl.RawSecurityDescriptor $sdBytes,0
}

