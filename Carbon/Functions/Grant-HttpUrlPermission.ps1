
function Grant-HttpUrlPermission
{
    <#
    .SYNOPSIS
    Grant a principal permission to bind to an HTTP URL.

    .DESCRIPTION
    The `Grant-HttpUrlAclPermission` functions uses the HTTP Server API to grant a user permission to bind to an HTTP URL.

    [The HTTP Server API](https://msdn.microsoft.com/en-us/library/aa364510.aspx)

    > enables applications to communicate over HTTP without using Microsoft Internet Information Server (IIS). Applications can register to receive HTTP requests for particular URLs, receive HTTP requests, and send HTTP responses.

    An application that uses the HTTP Server API must register all URLs it binds to. A user can have two permissions: 
    
     * `Register`, which allows the user to bind to the `$Url` url
     * `Delegate`, which allows the user to "reserve (delegate) a subtree of this URL for another user" (whatever that means)

    If the user already has the desired permissions, nothing happens. If the user has any permissions not specified by the `Permission` parameter, they are removed (i.e. if the user currently has delegate permission, but you don't pass that permission in, it will be removed).

    This command replaces the `netsh http (add|delete) urlacl` command.

    `Grant-HttpUrlAclPermission` was introduced in Carbon 2.1.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa364653.aspx

    .LINK
    Get-HttpUrlAcl

    .EXAMPLE
    Grant-HttpUrlAclPermission -Url 'http://+:4833' -Principal 'FALCON\HSolo' -Permission [Carbon.Security.HttpUrlAccessRights]::Register

    Demonstrates how to grant a user permission to bind to (i.e. "register") an HTTP URL. IN this case user `FALCON\HSolo` can use `http://+:4833`.

    .EXAMPLE
    Grant-HttpUrlAclPermission -Url 'http://+:4833' -Principal 'FALCON\HSolo' -Permission [Carbon.Security.HttpUrlAccessRights]::Delegate

    Demonstrates how to grant a user permission to delegate an HTTP URL, but not the ability to bind to that URL. In this case user `FALCON\HSolo` can delegate `http://+:4833`, but can't bind to it.

    .EXAMPLE
    Grant-HttpUrlAclPermission -Url 'http://+:4833' -Principal 'FALCON\HSolo' -Permission [Carbon.Security.HttpUrlAccessRights]::RegisterAndDelegate

    Demonstrates how to grant a user permission to regisgter *and* delegate an HTTP URL. In this case user `FALCON\HSolo` can bind to and delegate `http://+:4833`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The URL.
        $Url,

        [Parameter(Mandatory=$true)]
        [Alias('Identity')]
        [string]
        # The user receiving the permission.
        $Principal,

        [Parameter(Mandatory=$true)]
        [Carbon.Security.HttpUrlAccessRights]
        # The permission(s) to grant the user. There are two permissions:
        #
        #  * `Register`, which allows the user to bind to the `$Url` url
        #  * `Delegate`, which allows the user to "reserve (delegate) a subtree of this URL for another user" (whatever that means)
        #  * `RegisterAndDelegate`, which grants both `Register` and `Delegate` permissions
        $Permission
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $acl = Get-HttpUrlAcl -Url $Url -ErrorAction Ignore
    if( -not $acl )
    {
        $acl = New-Object 'Carbon.Security.HttpUrlSecurity' $Url
    }

    $id = Resolve-Identity -Name $Principal
    if( -not $id )
    {
        return
    }

    $currentRule = $acl.Access | Where-Object { $_.IdentityReference -eq $id.FullName }
    $currentRights = ''
    if( $currentRule )
    {
        if( $currentRule.HttpUrlAccessRights -eq $Permission )
        {
            return
        }
        $currentRights = $currentRule.HttpUrlAccessRights
    }

    Write-Verbose -Message ('[{0}]  [{1}]  {2} -> {3}' -f $Url,$id.FullName,$currentRights,$Permission) -Verbose
    $rule = New-Object 'Carbon.Security.HttpUrlAccessRule' $id.Sid,$Permission
    $modifiedRule = $null
    $acl.ModifyAccessRule( ([Security.AccessControl.AccessControlModification]::RemoveAll), $rule, [ref]$modifiedRule )
    $acl.SetAccessRule( $rule )
}