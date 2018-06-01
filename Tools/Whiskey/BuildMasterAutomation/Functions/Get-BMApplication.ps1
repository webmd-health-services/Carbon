
function Get-BMApplication
{
    <#
    .SYNOPSIS
    Gets BuildMaster applications.
    
    .DESCRIPTION
    The `Get-BMApplication` function gets all active applications from an instance of BuildMaster. Use the `Force` switch to include inactive applications. To get a specific application, pass the name to the `Name` parameter. Active and inactive applications are returned. If an application with the name doesn't exist, you'll get nothing back.
    
    Uses the BuildMaster native API, which can change without notice between releases. By default, this function returns *all* applications. 
    
    .EXAMPLE
    Get-BMApplication -Session $session

    Demonstrates how to get all active BuildMaster applications

    .EXAMPLE
    Get-BMApplication -Session $session -Force

    Demonstrates how to get all active *and* inactive/disabled BuildMaster applications.

    .EXAMPLE
    Get-BMApplication -Session $session -Name 'MyApplication'

    Demonstrates how to get a specific application.
    #>
    [CmdletBinding(DefaultParameterSetName='AllApplications')]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The session to use when connecting to BuildMaster. Use `New-BMSession` to create session objects.
        $Session,

        [Parameter(ParameterSetName='SpecificApplication',Mandatory=$true)]
        [string]
        # The name of the application to get. By default, all applications are returned.
        $Name,

        [Parameter(ParameterSetName='AllApplications')]
        [Switch]
        # Force `Get-BMApplication` to return inactive/disabled applications.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    $parameters = @{
                        Application_Count = 0;
                        IncludeInactive_Indicator = ($Force.IsPresent -or $PSCmdlet.ParameterSetName -eq 'SpecificApplication');
                   } 

    Invoke-BMNativeApiMethod -Session $Session -Name 'Applications_GetApplications' -Parameter $parameters |
        Where-Object { 
            if( $Name )
            {
                return $_.Application_Name -eq $Name
            }
            return $true
        }
}
