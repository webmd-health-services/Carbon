
function Get-CHttpUrlAcl
{
    <#
    .SYNOPSIS
    Gets HTTP URL security information.

    .DESCRIPTION
    The `Get-CHttpUrlAcl` functions uses the HTTP Server API to get HTTP URL ACL information. With no parameters, it returns `Carbon.Security.HttpUrlSecurity` objects for all the HTTP URL ACLs. To get a specific HTTP URL ACL, use the `Name` parameter (wildcards supported).

    [The HTTP Server API](https://msdn.microsoft.com/en-us/library/aa364510.aspx)

    > enables applications to communicate over HTTP without using Microsoft Internet Information Server (IIS). Applications can register to receive HTTP requests for particular URLs, receive HTTP requests, and send HTTP responses.

    An application that uses the HTTP Server API must register all URLs it listens (i.e. binds, registers) to. When registering, the user who will listen to the URL must also be provided. Typically, this is done with the `netsh http (show|add|remove) urlacl` command(s). This function replaces the `netsh http show urlacl` command.

    `Get-CHttpUrlAcl` was introduced in Carbon 2.1.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa364510.aspx

    .LINK
    Grant-CHttpUrlPermission

    .LINK
    Revoke-CHttpUrlPermission

    .OUTPUTS
    Carbon.Security.HttpUrlSecurity.

    .EXAMPLE
    Get-CHttpUrlAcl

    Demonstrates how to get security information for all HTTP URLs configured on the current computer.

    .EXAMPLE
    Get-CHttpUrlAcl -Url 'http://+:8594/'

    Demonstrates how to get security information for a specific HTTP URL.

    .EXAMPLE
    Get-CHttpUrlAcl -Url 'htt://*:8599/'

    Demonstrates how to use wildcards to find security information. In this case, all URLs that use port 8599 will be returned.
    
    When using wildcards, it is important that your URL end with a slash! The HTTP Server API adds a forward slash to the end of all its URLs.

    .EXAMPLE
    Get-CHttpUrlAcl -LiteralUrl 'http://*:8599/'

    Demonstrates how to use a literal URL to find security information. Will only return the ACL for the URL `http://*:8599/`.
    #>
    [CmdletBinding(DefaultParameterSetName='AllUrls')]
    [OutputType([Carbon.Security.HttpUrlSecurity])]
    param(
        [Parameter(ParameterSetName='ByWildcardUrl')]
        [string]
        # The URL whose security information to get. Wildcards supported.
        #
        # Make sure your URL ends with a forward slash.
        $Url,

        [Parameter(ParameterSetName='ByLiteralUrl')]
        [string]
        # The literal URL whose security information to get.
        #
        # Make sure your URL ends with a forward slash.
        $LiteralUrl
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $errorActionParam = @{ 'ErrorAction' = $ErrorActionPreference }
    if( $ErrorActionPreference -eq 'Ignore' )
    {
        $ErrorActionPreference = 'SilentlyContinue'
    }

    $acls = @()
    [Carbon.Security.HttpUrlSecurity]::GetHttpUrlSecurity() |
        Where-Object {
            if( $PSCmdlet.ParameterSetName -eq 'AllUrls' )
            {
                return $true
            }

            if( $PSCmdlet.ParameterSetName -eq 'ByWildcardUrl' )
            {
                Write-Debug -Message ('{0} -like {1}' -f $_.Url,$Url)
                return $_.Url -like $Url
            }

            Write-Debug -Message ('{0} -eq {1}' -f $_.Url,$LiteralUrl)
            return $_.Url -eq $LiteralUrl
        } |
        Tee-Object -Variable 'acls'

    if( -not $acls )
    {
        if( $PSCmdlet.ParameterSetName -eq 'ByLiteralUrl' )
        {
            Write-Error ('HTTP ACL for URL {0} not found. The HTTP API adds a trailing forward slash (/) to the end of all URLs. Make sure your URL ends with a trailing slash.' -f $LiteralUrl) @errorActionParam
        }
        elseif( -not [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Url) )
        {
            Write-Error ('HTTP ACL for URL {0} not found. The HTTP API adds a trailing forward slash (/) to the end of all URLs. Make sure your URL ends with a trailing slash.' -f $Url) @errorActionParam
        }
    }
}
