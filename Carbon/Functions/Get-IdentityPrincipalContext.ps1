
function Get-IdentityPrincipalContext
{
    <#
    .SYNOPSIS
    **INTERNAL.** Do not use.
    .DESCRIPTION
    **INTERNAL.** Do not use.
    .EXAMPLE
    **INTERNAL.** Do not use.
    #>
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.PrincipalContext])]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Identity]
        # The identity whose principal context to get.
        $Identity
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # First, check for a local match
    $machineCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' 'Machine',$env:COMPUTERNAME
    if( [DirectoryServices.AccountManagement.Principal]::FindByIdentity( $machineCtx, 'Sid', $Identity.Sid.Value ) )
    {
        return $machineCtx
    }

    $domainCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' 'Domain',$Identity.Domain
    if( [DirectoryServices.AccountManagement.PRincipal]::FindByIdentity( $domainCtx, 'Sid', $Identity.Sid.Value ) )
    {
        return $domainCtx
    }

    Write-Error -Message ('Unable to determine if principal ''{0}'' (SID: {1}; Type: {2}) is a machien or domain principal.' -f $Identity.FullName,$Identity.Sid.Value,$Identity.Type)
}
