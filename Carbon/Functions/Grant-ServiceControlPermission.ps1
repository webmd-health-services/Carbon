
function Grant-CServiceControlPermission
{
    <#
    .SYNOPSIS
    Grants a user/group permission to start/stop (i.e. use PowerShell's `*-Service` cmdlets) a service.

    .DESCRIPTION
    By default, only Administrators are allowed to control a service. You may notice that when running the `Stop-Service`, `Start-Service`, or `Restart-Service` cmdlets as a non-Administrator, you get permissions errors. That's because you need to correct permissions.  This function grants just the permissions needed to use PowerShell's `Stop-Service`, `Start-Service`, and `Restart-Service` cmdlets to control a service.

    .LINK
    Get-CServicePermission
    
    .LINK
    Grant-CServicePermission
    
    .LINK
    Revoke-CServicePermission
    
    .EXAMPLE
    Grant-CServiceControlPermission -ServiceName CCService -Identity INITRODE\Builders

    Grants the INITRODE\Builders group permission to control the CruiseControl.NET service.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $ServiceName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user/group name being given access.
        $Identity
    )
   
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $pscmdlet.ShouldProcess( $ServiceName, "grant control service permissions to '$Identity'" ) )
    {
        Grant-CServicePermission -Name $ServiceName -Identity $Identity -QueryStatus -EnumerateDependents -Start -Stop
    }
}

