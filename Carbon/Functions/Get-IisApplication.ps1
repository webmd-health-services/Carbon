
function Get-CIisApplication
{
    <#
    .SYNOPSIS
    Gets an IIS application as an `Application` object.

    .DESCRIPTION
    Uses the `Microsoft.Web.Administration` API to get an IIS application object.  If the application doesn't exist, `$null` is returned.

    The objects returned have two dynamic properties and one dynamic methods added.

     * `ServerManager { get; }` - The `ServerManager` object which created the `Application` object.
     * `CommitChanges()` - Persists any configuration changes made to the object back into IIS's configuration files.
     * `PhysicalPath { get; }` - The physical path to the application.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.Application.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar`

    Gets all the applications running under the `DeathStar` website.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar' -VirtualPath '/'

    Demonstrates how to get the main application for a website: use `/` as the application name.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar' -VirtualPath 'MainPort/ExhaustPort'

    Demonstrates how to get a nested application, i.e. gets the application at `/MainPort/ExhaustPort` under the `DeathStar` website.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the application is running.
        $SiteName,
        
        [Parameter()]
        [Alias('Name')]
        [string]
        # The name of the application.  Default is to return all applications running under the website `$SiteName`.
        $VirtualPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if( -not $site )
    {
        return
    }

    $site.Applications |
        Where-Object {
            if( $VirtualPath )
            {
                return ($_.Path -eq "/$VirtualPath")
            }
            return $true
        } | 
        Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
}

