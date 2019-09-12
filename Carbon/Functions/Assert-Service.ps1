
function Assert-CService
{
    <#
    .SYNOPSIS
    Checks if a service exists, and writes an error if it doesn't.
    
    .DESCRIPTION
    Also returns `True` if the service exists, `False` if it doesn't.
    
    .OUTPUTS
    System.Boolean.
    
    .LINK
    Test-CService
    
    .EXAMPLE
    Assert-CService -Name 'Drivetrain'
    
    Writes an error if the `Drivetrain` service doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CService $Name) )
    {
        Write-Error ('Service {0} not found.' -f $Name)
        return $false
    }
    
    return $true
}

