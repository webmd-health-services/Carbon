
function Get-CGroup
{
    <#
    .SYNOPSIS
    Gets *local* groups.

    .DESCRIPTION
    `Get-CGroup` gets all *local* groups or a specific group by its name.

    The objects returned, `DirectoryServices.AccountManagement.GroupPrincipal`, use external resources, which means they don't clean up propertly when garbage collected, resulting in memory leaks. You should call `Dispose()` on the objects you receieve from this function when you're done using them so these external resources can be cleaned up correctly.

    `Get-CGroup` is new in Carbon 2.0.

    .OUTPUTS
    System.DirectoryServices.AccountManagement.GroupPrincipal.

    .LINK
    Get-CUser

    .EXAMPLE
    Get-CGroup

    Demonstrates how to get all local groups.

    .EXAMPLE
    Get-CGroup -Name RebelAlliance

    Demonstrates how to get a specific group.
    #>
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        # The name of the group to return.
        [string]$Name 
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # Tee-Object won't set its variable if WhatIfPreference is $true.
    $WhatIfPreference = $false
    
    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $query = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
    $searcher = New-Object 'DirectoryServices.AccountManagement.PrincipalSearcher' $query
    try
    {
        $groups = @()
        $searcher.FindAll()  |
            Where-Object { 
                if( $Name )
                {
                    return $_.Name -eq $Name
                }
                return $true
            } |
            Tee-Object -Variable 'groups'

        if( $Name )
        {
            $groupCount = $groups | Measure-Object | Select-Object -ExpandProperty 'Count'
            if( $groupCount -gt 1 )
            {
                Write-Error -Message ('Found {0} groups named "{1}".' -f $groupCount,$Name) -ErrorAction:$ErrorActionPreference
                return
            }

            if( $groupCount -eq 0 )
            {
                Write-Error ('Local group "{0}" not found.' -f $Name) -ErrorAction:$ErrorActionPreference
                return
            }
        }
    }
    finally
    {
        $searcher.Dispose()
        $query.Dispose()
    }
}
