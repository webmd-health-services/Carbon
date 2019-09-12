
function Get-CIisHttpRedirect
{
    <#
    .SYNOPSIS
    Gets the HTTP redirect settings for a website or virtual directory/application under a website.
    
    .DESCRIPTION
    Returns a `Carbon.Iis.HttpRedirectConfigurationSection` object for the given HTTP redirect settings.  The object contains the following properties:
    
     * Enabled - `True` if the redirect is enabled, `False` otherwise.
     * Destination - The URL where requests are directed to.
     * HttpResponseCode - The HTTP status code sent to the browser for the redirect.
     * ExactDestination - `True` if redirects are to destination, regardless of the request path.  This will send all requests to `Destination`.
     * ChildOnly - `True` if redirects are only to content in the destination directory (not subdirectories).
	 
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect
     
    .OUTPUTS
    Carbon.Iis.HttpRedirectConfigurationSection.
     
    .EXAMPLE
    Get-CIisHttpRedirect -SiteName ExampleWebsite 
    
    Gets the redirect settings for ExampleWebsite.
    
    .EXAMPLE
    Get-CIisHttpRedirect -SiteName ExampleWebsite -Path MyVirtualDirectory
    
    Gets the redirect settings for the MyVirtualDirectory virtual directory under ExampleWebsite.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site's whose HTTP redirect settings will be retrieved.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path to a sub-directory under `SiteName` whose settings to return.
        $VirtualPath = ''
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-CIisConfigurationSection -SiteName $SiteName `
                                -VirtualPath $VirtualPath `
                                -SectionPath 'system.webServer/httpRedirect' `
                                -Type ([Carbon.Iis.HttpRedirectConfigurationSection])
}

