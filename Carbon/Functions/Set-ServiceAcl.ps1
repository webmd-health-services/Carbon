
function Set-CServiceAcl
{
    <#
    .SYNOPSIS
    Sets a service's discretionary access control list (i.e. DACL).
    
    .DESCRIPTION
    The existing DACL is replaced with the new DACL.  No previous permissions are preserved.  That's your job.  You're warned!
    
    You probably want `Grant-CServicePermission` or `Revoke-CServicePermission` instead.
    
    .LINK
    Get-CServicePermission
    
    .LINK
    Grant-CServicePermission
    
    .LINK
    Revoke-CServicePermission
    
    .EXAMPLE
    Set-ServiceDacl -Name 'Hyperdrive' -Dacl $dacl
    
    Replaces the DACL on the `Hyperdrive` service.  Yikes!  Sounds like something the Empire would do, though. 
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service whose DACL to replace.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [Security.AccessControl.DiscretionaryAcl]
        # The service's new DACL.
        $Dacl
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rawSD = Get-CServiceSecurityDescriptor -Name $Name
    $daclBytes = New-Object byte[] $Dacl.BinaryLength 
    $Dacl.GetBinaryForm($daclBytes, 0);
    $rawSD.DiscretionaryAcl = New-Object Security.AccessControl.RawAcl $daclBytes,0
    $sdBytes = New-Object byte[] $rawSD.BinaryLength   
    $rawSD.GetBinaryForm($sdBytes, 0);
    
    if( $pscmdlet.ShouldProcess( ("{0} service DACL" -f $Name), "set" ) )
    {
        [Carbon.Service.ServiceSecurity]::SetServiceSecurityDescriptor( $Name, $sdBytes )
    }
}

