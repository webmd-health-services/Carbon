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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username for the user.
        $UserName,
        
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
        # Prevent the user from changing his password.
        $UserCannotChangePassword,

        [Switch]
        # Set to true if the user's password should expire.
        $PasswordNeverExpires,

        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $resource = @{
                    UserName = $UserName;
                    Password = $Password;
                    Description = $Description;
                    FullName = $FullName;
                    UserCannotChangePassword = $UserCannotChangePassword;
                    PasswordNeverExpires = $PasswordNeverExpires;
                    Ensure = 'Absent';
                }
    
    $user = Get-User -UserName $UserName -ErrorAction Ignore
    if( $user )
    {
        $resource.Ensure = 'Present'
        $resource.Password = $null
        $resource.Description = $user.Description
        $resource.FullName = $user.DisplayName
        $resource.UserCannotChangePassword = $user.UserCannotChangePassword
        $resource.PasswordNeverExpires = $user.PasswordNeverExpires
    }
    return $resource
}


function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username for the user.
        $UserName,
        
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
        # Prevent the user from changing his password.
        $UserCannotChangePassword,

        [Switch]
        # Set to true if the user's password should expire.
        $PasswordNeverExpires,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    if( $Ensure -eq 'Absent' )
    {
        Write-Verbose ('Deleting user ''{0}''' -f $UserName)
        Uninstall-User -UserName $UserName
        return
    }

    if( $Ensure -eq 'Present' )
    {
        if( -not $Password )
        {
            Write-Error ('Password required when configuring a user account. Please supply a value for the Password property.')
            return
        }

        if( $PSBoundParameters.ContainsKey('Ensure') )
        {
            [void]$PSBoundParameters.Remove('Ensure')
        }
        Write-Verbose ('Creating user ''{0}''' -f $UserName)
        Install-User @PSBoundParameters
    }
}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username for the user.
        $UserName,
        
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
        # Prevent the user from changing his password.
        $UserCannotChangePassword,

        [Switch]
        # Set to true if the user's password should expire.
        $PasswordNeverExpires,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -UserName $UserName
    $userExists = ($resource.Ensure -eq 'Present')
    if( $Ensure -eq 'Absent' )
    {
        if( $userExists )
        {
            Write-Verbose ('User ''{0}'' found' -f $UserName)
            return $false
        }

        Write-Verbose ('User ''{0}'' not found' -f $UserName)
        return $true
    }

    if( $userExists )
    {
        [void]$resource.Remove('Password')
        return Test-DscTargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('User ''{0}''' -f $UserName)
    }
    else
    {
        Write-Verbose ('User ''{0}'' not found' -f $UserName)
        return $false
    }
}