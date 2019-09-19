
function Test-CService
{
    <#
    .SYNOPSIS
    Tests if a service exists, without writing anything out to the error stream.
    
    .DESCRIPTION
    `Get-Service` writes an error when a service doesn't exist.  This function tests if a service exists without writing anyting to the output stream.
    
    .OUTPUTS
    System.Boolean.
    
    .LINK
    Carbon_Service

    .LINK
    Install-CService

    .LINK
    Uninstall-CService

    .EXAMPLE
    Test-CService -Name 'Drive'
    
    Returns `true` if the `Drive` service exists.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service to test.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $service = Get-Service -Name $Name -ErrorAction Ignore 
    if( $service )
    {
        return $true
    }
    else
    {
        return $false
    }
}
