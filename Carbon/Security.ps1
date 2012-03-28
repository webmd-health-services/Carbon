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

function Grant-Permissions
{
    <#
    .SYNOPSIS
    Grants permission on a file/directory or registry key.
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from
        # System.Security.AccessControl.FileSystemRights.  For registry items, use values from
        # System.Security.AccessControl.RegistryRights.
        $Permissions,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path
    )
    
    $Path = Resolve-Path $Path
    
    $pathQualifier = Split-Path -Qualifier $Path
    if( -not $pathQualifier )
    {
        throw "Unable to get qualifier on path $Path."
    }
    $pathDrive = Get-PSDrive $pathQualifier.Trim(':')
    $pathProvider = $pathDrive.Provider
    $providerName = $pathProvider.Name
    if( $providerName -ne 'Registry' -and $providerName -ne 'FileSystem' )
    {
        throw "Unsupported path: '$Path' belongs to the '$providerName' provider."
    }

    $rights = 0
    foreach( $permission in $Permissions )
    {
        $right = ($permission -as "Security.AccessControl.$($providerName)Rights")
        if( -not $right )
        {
            throw "Invalid $($providerName)Rights: $permission.  Must be one of $([Enum]::GetNames("Security.AccessControl.$($providerName)Rights"))."
        }
        $rights = $rights -bor $right
    }
    
    Write-Host "Granting $Identity $Permissions on $Path."
    # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
    # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security descriptor.
    # See http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
    $currentAcl = (Get-Item $Path).GetAccessControl("Access")
    
    $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
    if( Test-Path $Path -PathType Container )
    {
        $inheritanceFlags = ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                             [Security.AccessControl.InheritanceFlags]::ObjectInherit)
    }
    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    $accessRule = New-Object "Security.AccessControl.$($providerName)AccessRule" $identity,$rights,$inheritanceFlags,$propagationFlags,"Allow"    
    $currentAcl.SetAccessRule( $accessRule )
    Set-Acl $Path $currentAcl
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


