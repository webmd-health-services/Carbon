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

function Get-User
{
    <#
    .SYNOPSIS
    Gets *local* users.

    .DESCRIPTION
    `Get-User` gets all *local* users. Use the `UserName` parameter to get  a specific user by its username.

    The objects returned by `Get-User` are instances of `System.DirectoryServices.AccountManagement.UserPrincipal`. These objects use external resources, which, if they are disposed of correctly, will cause memory leaks. When you're done using the objects returne by `Get-User`, call `Dispose()` on each one to clean up its external resources.

    `Get-User` is new in Carbon 2.0.

    .OUTPUTS
    System.DirectoryServices.AccountManagement.UserPrincipal.

    .LINK
    Install-User

    .LINK
    Test-User

    .LINK
    Uninstall-User

    .EXAMPLE
    Get-User

    Demonstrates how to get all local users.

    .EXAMPLE
    Get-User -Username LSkywalker 

    Demonstrates how to get a specific user.
    #>
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.AccountManagement.UserPrincipal])]
    param(
        [ValidateLength(1,20)]
        [string]
        # The username for the user.
        $UserName 
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    if( $Username )
    {
        $user = [DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity( $ctx, $Username )
        if( -not $user )
        {
            try
            {
                Write-Error ('Local user ''{0}'' not found.' -f $Username) -ErrorAction:$ErrorActionPreference
                return
            }
            finally
            {
                $ctx.Dispose()
            }
        }
        return $user
    }
    else
    {
        $query = New-Object 'DirectoryServices.AccountManagement.UserPrincipal' $ctx
        $searcher = New-Object 'DirectoryServices.AccountManagement.PrincipalSearcher' $query
        try
        {
            $searcher.FindAll() 
        }
        finally
        {
            $searcher.Dispose()
            $query.Dispose()
        }
    }
}

