
function Get-IisHttpHeader
{
    <#
    .SYNOPSIS
    Gets the HTTP headers for a website or directory under a website.
    
    .DESCRIPTION
    For each custom HTTP header defined under a website and/or a sub-directory under a website, returns a `Carbon.Iis.HttpHeader` object.  This object has two properties:
    
     * Name: the name of the HTTP header
     * Value: the value of the HTTP header
    
    .OUTPUT
    Carbon.Iis.HttpHeader.
    
    .LINK
    Set-IisHttpHeader
    
    .EXAMPLE
    Get-IisHttpHeader -SiteName SopwithCamel
    
    Returns the HTTP headers for the `SopwithCamel` website.
    
    .EXAMPLE
    Get-IisHttpHeader -SiteName SopwithCamel -Path Engine
    
    Returns the HTTP headers for the `Engine` directory under the `SopwithCamel` website.
    
    .EXAMPLE
    Get-IisHttpHeader -SiteName SopwithCambel -Name 'X-*'
    
    Returns all HTTP headers which match the `X-*` wildcard.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose headers to return.
        $SiteName,
        
        [string]
        # The optional path under `SiteName` whose headers to return.
        $Path = '',
        
        [string]
        # The name of the HTTP header to return.  Optional.  If not given, all headers are returned.  Wildcards supported.
        $Name
    )

    $httpProtocol = Get-IisConfigurationSection -SiteName $SiteName `
                                                -Path $Path `
                                                -SectionPath 'system.webServer/httpProtocol'
    $httpProtocol.GetCollection('customHeaders') |
        Where-Object { $_['name'] -like $Name } |
        ForEach-Object { New-Object Carbon.Iis.HttpHeader $_['name'],$_['value'] }
}