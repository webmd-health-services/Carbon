
function Get-CIisWebsite
{
    <#
    .SYNOPSIS
    Returns all the websites installed on the local computer, or a specific website.
    
    .DESCRIPTION
    Returns a Microsoft.Web.Administration.Site object.

    Each object will have a `CommitChanges` script method added which will allow you to commit/persist any changes to the website's configuration.
     
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.Site.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.site.aspx

    .EXAMPLE
    Get-CIisWebsite

    Returns all installed websites.
     
    .EXAMPLE
    Get-CIisWebsite -SiteName 'WebsiteName'
     
    Returns the details for the site named `WebsiteName`.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        [string]
        [Alias('SiteName')]
        # The name of the site to get.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Name -and -not (Test-CIisWebsite -Name $Name) )
    {
        return $null
    }
    
    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $mgr.Sites | 
        Where-Object {
            if( $Name )
            {
                $_.Name -eq $Name
            }
            else
            {
                $true
            }
        } | Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

