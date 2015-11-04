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

function Install-User
{
    <#
    .SYNOPSIS
    Installs a *local* user account.

    .DESCRIPTION
    `Install-User` creates a new *local* user account, or updates an existing *local* user account. 
    
    Returns the user if `-PassThru` switch is used. The object returned, an instance of `System.DirectoryServices.AccountManagement.UserPrincipal`, uses external resources, which means it can leak memory when garbage collected. When you're done using the user object you get, call its `Dispose()` method so its external resources are cleaned up properly.

    The `UserCannotChangePassword` and `PasswordExpires` switches were added in Carbon 2.0.

    .OUTPUTS
    System.DirectoryServices.AccountManagement.UserPrincipal.

    .LINK
    Get-User

    .LINK
    New-Credential

    .LINK
    Test-User

    .LINK
    Uninstall-User

    .EXAMPLE
    Install-User -Credential $lukeCredentials -Description "Luke Skywalker's account."

    Creates a new `LSkywalker` user account with the given password and description.  Luke's password is set to never expire.  

    .EXAMPLE
    Install-User -Credential $lukeCredentials -UserCannotChangePassword -PasswordExpires

    Demonstrates how to create an account for a user who cannot change his password and whose password will expire.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='WithUserNameAndPassword')]
    [OutputType([System.DirectoryServices.AccountManagement.UserPrincipal])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithUserNameAndPassword',DontShow=$true)]
        [ValidateLength(1,20)]
        [string]
        # OBSOLETE. The `UserName` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
        $UserName,
        
        [Parameter(Mandatory=$true,ParameterSetName='WithUserNameAndPassword',DontShow=$true)]
        [string]
        # OBSOLETE. The `Password` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
        $Password,

        [Parameter(Mandatory=$true,ParameterSetName='WithCredential')]
        [pscredential]
        # The user's credentials.
        #
        # The `Credential` parameter was added in Carbon 2.0.
        $Credential,
        
        [string]
        # A description of the user.
        $Description,
        
        [string]
        # The full name of the user.
        $FullName,

        [Switch]
        # Prevent the user from changing his password. New in Carbon 2.0.
        $UserCannotChangePassword,

        [Switch]
        # Set to true if the user's password should expire. New in Carbon 2.0.
        $PasswordExpires,

        [Switch]
        # Return the user. New in Carbon 2.0.
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -eq 'WithCredential' )
    {
        $UserName = $Credential.UserName
    }

    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $user = [DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity( $ctx, $UserName )
    try
    {
        $operation = 'update'
        if( -not $user )
        {
            $operation = 'create'
            $user = New-Object 'DirectoryServices.AccountManagement.UserPrincipal' $ctx
            $creating = $true
        }

        $user.SamAccountName = $UserName
        $user.DisplayName = $FullName
        $user.Description = $Description
        $user.UserCannotChangePassword = $UserCannotChangePassword
        $user.PasswordNeverExpires = -not $PasswordExpires

        if( $PSCmdlet.ParameterSetName -eq 'WithUserNameAndPassword' )
        {
            Write-Warning ('Install-User function''s `UserName` and `Password` parameters are obsolete and will be removed in a future version of Carbon. Please use the `Credential` parameter instead.')
            $user.SetPassword( $Password )
        }
        else
        {
            $user.SetPassword( $Credential.GetNetworkCredential().Password )
        }


        if( $PSCmdlet.ShouldProcess( $Username, "$operation local user" ) )
        {
            $user.Save()
        }

        if( $PassThru )
        {
            return $user
        }
    }
    finally
    {
        if( -not $PassThru )
        {
            $user.Dispose()
            $ctx.Dispose()
        }
    }
}

