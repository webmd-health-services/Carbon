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

function Assert-AdminPrivileges
{
    <#
    .SYNOPSIS
    Checks that you're running as an administrator, and throws an error if you aren't.
    #>
    [CmdletBinding()]
    param(
    )
    
    if( -not (Test-AdminPrivileges) )
    {
        throw "You are not currently running with administrative privileges.  Please re-start PowerShell as an administrator (right-click the PowerShell application, and choose ""Run as Administrator"")."
    }
}

function Convert-SecureStringToString
{
    <#
    .SYNOPSIS
    Converts a secure string into a plaintext string.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [Security.SecureString]
        # The secure string to convert.
        $SecureString
    )
    
    $stringPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto($stringPtr)
}

function New-Credential
{
    <#
    .SYNOPSIS
    Creates a new PsCredential object from a given username and password.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The username.
        $User, 
        [Parameter(Mandatory=$true)]
        [string]
        # The password.
        $Password
    )

    return New-Object Management.Automation.PsCredential $User,(ConvertTo-SecureString -AsPlainText -Force $Password)    
}

function Test-AdminPrivileges
{
    <#
    .SYNOPSIS
    Checks that you're running as an administrator, and returns $true if you are, $false otherwise.
    #>
    [CmdletBinding()]
    param(
    )
    
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Verbose "Checking if current user '$($identity.Name)' has administrative privileges."

    $hasElevatedPermissions = $false
    foreach ( $group in $identity.Groups )
    {
        if ( $group.IsValidTargetType([Security.Principal.SecurityIdentifier]) )
        {
            $groupSid = $group.Translate([Security.Principal.SecurityIdentifier])
            if ( $groupSid.IsWellKnown("AccountAdministratorSid") -or $groupSid.IsWellKnown("BuiltinAdministratorsSid"))
            {
                return $true
            }
        }
    }

    return $false
}


