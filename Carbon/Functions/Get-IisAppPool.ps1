
function Get-CIisAppPool
{
    <#
    .SYNOPSIS
    Gets a `Microsoft.Web.Administration.ApplicationPool` object for an application pool.
    
    .DESCRIPTION
    The `Get-CIisAppPool` function returns an IIS application pools as a `Microsoft.Web.Administration.ApplicationPool` object. Use the `Name` parameter to return the application pool. If that application pool isn't found, `$null` is returned.

    Carbon adds a `CommitChanges` method on each object returned that you can use to save configuration changes.

    Beginning in Carbon 2.0, `Get-CIisAppPool` will return all application pools installed on the current computer.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.applicationpool(v=vs.90).aspx
    
    .OUTPUTS
    Microsoft.Web.Administration.ApplicationPool.

    .EXAMPLE
    Get-CIisAppPool

    Demonstrates how to get *all* application pools.
    
    .EXAMPLE
    Get-CIisAppPool -Name 'Batcave'
    
    Gets the `Batcave` application pool.
    
    .EXAMPLE
    Get-CIisAppPool -Name 'Missing!'
    
    Returns `null` since, for purposes of this example, there is no `Missing~` application pool.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        [string]
        # The name of the application pool to return. If not supplied, all application pools are returned.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object Microsoft.Web.Administration.ServerManager
    $mgr.ApplicationPools |
        Where-Object { 
            if( -not $PSBoundParameters.ContainsKey('Name') )
            {
                return $true
            }
            return $_.Name -eq $Name 
        } |
        Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

