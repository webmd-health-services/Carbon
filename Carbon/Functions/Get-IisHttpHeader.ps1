
function Get-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Gets the HTTP headers for a website or directory under a website.
    
    .DESCRIPTION
    For each custom HTTP header defined under a website and/or a sub-directory under a website, returns a `Carbon.Iis.HttpHeader` object.  This object has two properties:
    
     * Name: the name of the HTTP header
     * Value: the value of the HTTP header
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Carbon.Iis.HttpHeader.
    
    .LINK
    Set-CIisHttpHeader
    
    .EXAMPLE
    Get-CIisHttpHeader -SiteName SopwithCamel
    
    Returns the HTTP headers for the `SopwithCamel` website.
    
    .EXAMPLE
    Get-CIisHttpHeader -SiteName SopwithCamel -Path Engine
    
    Returns the HTTP headers for the `Engine` directory under the `SopwithCamel` website.
    
    .EXAMPLE
    Get-CIisHttpHeader -SiteName SopwithCambel -Name 'X-*'
    
    Returns all HTTP headers which match the `X-*` wildcard.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose headers to return.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path under `SiteName` whose headers to return.
        $VirtualPath = '',
        
        [string]
        # The name of the HTTP header to return.  Optional.  If not given, all headers are returned.  Wildcards supported.
        $Name = '*'
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $httpProtocol = Get-CIisConfigurationSection -SiteName $SiteName `
                                                -VirtualPath $VirtualPath `
                                                -SectionPath 'system.webServer/httpProtocol'
    $httpProtocol.GetCollection('customHeaders') |
        Where-Object { $_['name'] -like $Name } |
        ForEach-Object { New-Object Carbon.Iis.HttpHeader $_['name'],$_['value'] }
}

