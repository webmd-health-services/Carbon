# Copyright 2012 Aaron Jensen
# 
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
    Creates a new *local* user account, or, if the account already exists, updates its password and description.  In both cases, the users password is set to never expire.  This should probably be a parameter.  Send us a patch! 

    .EXAMPLE
    Install-User -Username LSkywalker -Password "whydidn'tyoutellme" -Description "Luke Skywalker's account."

    Creates a new `LSkywalker` user account with the given password and description.  Luke's password is set ot never expire.  
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username for the user.
        $Username,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user's password.
        $Password,
        
        [string]
        # A description of the user.
        $Description,
        
        [string]
        # The full name of the user.
        $FullName,

        [Switch]
        # Set to true if the user's password should expire.
        $PasswordExpires
    )

    # http://msdn.microsoft.com/en-us/library/windows/desktop/aa772300.aspx
    $ADS_UF_ACCOUNTDISABLE     = 0x00002
    $ADS_UF_LOCKOUT            = 0x00010
    $ADS_UF_PASSWD_NOTREQD     = 0x00020
    $ADS_UF_PASSWD_CANT_CHANGE = 0x00040
    $ADS_UF_DONT_EXPIRE_PASSWD = 0x10000
    
    $userExists = Test-User -Username $username

    $computerEntry = [adsi]('WinNT://{0}' -f $env:COMPUTERNAME)
    if( $userExists )
    {
        $logAction = 'Updating'
        $user = $computerEntry.Children | 
                    Where-Object { $_.Name -eq $Username }
        if( -not $user )
        {
            Write-Error ('User ''{0}'' not found.' -f $Username)
            return
        }
    }
    else
    {
        $logAction = 'Creating'
        $user = $computerEntry.Create( 'User', $Username )
    }

    $user.SetPassword( $Password )
    $user.Put( 'Description', $Description )
    $user.Put( 'FullName', $FullName )

    $userFlags = $user.UserFlags.Value
    if( $PasswordExpires )
    {
        $userFlags = $userFlags -band -bnot $ADS_UF_DONT_EXPIRE_PASSWD
    }
    else
    {
        $userFlags = $userFlags -bor $ADS_UF_DONT_EXPIRE_PASSWD
    }
    $user.Put( 'UserFlags', $userFlags )

    if( $pscmdlet.ShouldProcess( $Username, "$operation local user" ) )
    {
        Write-Host "$logAction local user $Username."
        $user.CommitChanges()
    }
}
