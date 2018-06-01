
function Get-BMApplicationGroup
{
    <#
    .SYNOPSIS
    Gets BuildMaster application groups.
    
    .DESCRIPTION
    The `Get-BMApplicationGroup` function gets all application groups from an instance of BuildMaster. To get a specific application group, pass the name to the `Name` parameter. Wildcards '*' are supported. If an application group with the name doesn't exist, you'll get nothing back.
    
    Uses the BuildMaster native API, which can change without notice between releases. By default, this function returns *all* application groups.
    
    .EXAMPLE
    Get-BMApplicationGroup -Session $session

    Demonstrates how to get all BuildMaster application groups.
    
    .EXAMPLE
    Get-BMApplicationGroup -Session $session -Name 'My Application Group'

    Demonstrates how to get a specific application group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The session to use when connecting to BuildMaster. Use `New-BMSession` to create session objects.
        $Session,
        
        [string]
        # The name of the application group to get. By default, all groups are returned.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'
    
    $parameters = @{}
    
    Invoke-BMNativeApiMethod -Session $Session -Name 'ApplicationGroups_GetApplicationGroups' -Parameter $parameters |
        Where-Object {
            if( $Name )
            {
                return $_.ApplicationGroup_Name -like $Name
            }
            return $true
        }
}
