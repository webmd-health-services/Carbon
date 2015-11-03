
function Get-HttpUrlAcl
{
    <#
    .SYNOPSIS
    Gets HTTP URL security information.

    .DESCRIPTION
    The `Get-HttpUrlAcl` functions used the HTTP Server API to get HTTP URL ACL information. With no parameters, it returns `Carbon.Security.HttpUrlSecurity` objects for all the HTTP URL ACLs. To get a specific HTTP URL ACL, use the `Name` parameter (wildcards supported).

    [The HTTP Server API](https://msdn.microsoft.com/en-us/library/aa364510.aspx)

    > enables applications to communicate over HTTP without using Microsoft Internet Information Server (IIS). Applications can register to receive HTTP requests for particular URLs, receive HTTP requests, and send HTTP responses.

    An application that uses the HTTP Server API must register all URLs it binds to. When registering, the user who will bind to the URL must also be provided. Typically, this is done with the `netsh http (show|add|remove) urlacl` command. This function replaces the `netsh http show urlacl` command.

    .EXAMPLE
    Get-HttpUrlAcl

    Demonstrates how to get security information for all HTTP URLs configured on the current computer.

    .EXAMPLE
    Get-HttpUrlAcl -Url 'http://+:8594/'

    Demonstrates how to get security information for a specific HTTP URL.

    .EXAMPLE
    Get-HttpUrlAcl -Urcl = 'htt://*:8599/'

    Demonstrates how to use wildcards to find security information. When using wildcards, it is important that your URL end with a slash! The HTTP Server API adds a forward slash to the end of all its URLs.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Security.HttpUrlSecurity])]
    param(
        [string]
        # The URL whose security information to get. Wildcards supported.
        #
        # Make sure your URL ends with a forward slash.
        $Url
    )

    Set-StrictMode -Version 'Latest'

    [Carbon.Security.HttpUrlSecurity]::GetHttpUrlSecurity()
}