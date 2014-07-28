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
        
        [Parameter()]
        [string]
        # A description of the user.
        $Description,
        
        [Parameter()]
        [string]
        # The full name of the user.
        $FullName
    )
    
    $userExists = Test-User -Username $username
    $operation = 'update'
    $logAction = 'Updating'
    $addArg = ''
    if( -not $userExists )
    {
        $addArg = '/ADD'
        $operation = 'create'
        $logAction = 'Creating'
    }
    
    if( $pscmdlet.ShouldProcess( $Username, "$operation local user" ) )
    {
        & (Resolve-NetPath) user $Username $Password $addArg /Comment:$Description /Fullname:$FullName /Y
        
        if( -not $userExists )
        {
            $user = Get-WmiLocalUserAccount -Username $Username
            $user.PasswordExpires = $false
            $user.Put()
        }
    }
}
