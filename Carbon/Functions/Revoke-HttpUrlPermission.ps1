# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Revoke-HttpUrlPermission
{
    <#
    .SYNOPSIS
    Revokes all a principal's permission to an HTTP URL.

    .DESCRIPTION
    The `Revoke-HttpUrlAclPermission` functions uses the HTTP Server API to revoke user/groups permissions to an HTTP URL.

    [The HTTP Server API](https://msdn.microsoft.com/en-us/library/aa364510.aspx)

    > enables applications to communicate over HTTP without using Microsoft Internet Information Server (IIS). Applications can register to receive HTTP requests for particular URLs, receive HTTP requests, and send HTTP responses.

    An application that uses the HTTP Server API must register all URLs it listens (i.e. binds, registers) to. This function removes all permissions to a URL for a specific user or group. If a user or group doesn't have permission, this function does nothing.

    If you want to *change* a user's permissions, use `Grant-HttpUrlPermission` instead.

    This command replaces the `netsh http delete urlacl` command.

    `Revoke-HttpUrlAclPermission` was introduced in Carbon 2.1.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa364510.aspx

    .LINK
    Get-HttpUrlAcl

    .LINK
    Grant-HttpUrlPermission

    .EXAMPLE
    Revoke-HttpUrlAclPermission -Url 'http://+:4833' -Principal 'FALCON\HSolo'

    Demonstrates how to revoke all a user's permissions to an HTTP URL. In this case Captain Solo will no longer be able to listen to URL `http://+:4833`.
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
        $Principal
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $id = Resolve-Identity -Name $Principal
    if( -not $id )
    {
        return
    }

    if( -not $Url.EndsWith('/') )
    {
        $Url = '{0}/' -f $Url
    }

    $acl = Get-HttpUrlAcl -LiteralUrl $Url -ErrorAction Ignore
    if( -not $acl )
    {
        return
    }

    $currentAccess = $acl.Access | Where-Object { $_.IdentityReference -eq $id.FullName }
    if( $currentAccess )
    {
        Write-Verbose -Message ('[{0}]  [{1}]  {2} ->' -f $Url,$id.FullName,$currentAccess.HttpUrlAccessRights)
        $acl.RemoveAccessRule($currentAccess)
    }
}