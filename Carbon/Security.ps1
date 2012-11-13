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
    Throws an exception if the user doesn't have administrator privileges.

    .DESCRIPTION
    Many scripts and functions require the user to be running as an administrator.  This function checks if the user is running as an administrator or with administrator privileges and **throws an exception** if the user doesn't.  

    .LINK
    Test-AdminPrivileges

    .EXAMPLE
    Assert-AdminPrivileges

    Throws an exception if the user doesn't have administrator privileges.
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
    Converts a secure string into a plain text string.

    .DESCRIPTION
    Sometimes you just need to convert a secure string into a plain text string.  This function does it for you.  Yay!  Once you do, however, the cat is out of the bag and your password will be *all over memory* and, perhaps, the file system.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Convert-SecureStringToString -SecureString $mySuperSecretPasswordIAmAboutToExposeToEveryone

    Returns the plain text/decrypted value of the secure string.
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

function ConvertTo-InheritanceFlags
{
    <#
    .SYNOPSIS
    Converts a `Carbon.Security.ContainerInheritanceFlags` value to a `System.Security.AccessControl.InheritanceFlags` value.
    
    .DESCRIPTION
    The `Carbon.Security.ContainerInheritanceFlags` enumeration encapsulates oth `System.Security.AccessControl.InheritanceFlags` and `System.Security.AccessControl.PropagationFlags`.  Make sure you also call `ConvertTo-PropagationFlags` to get the propagation value.
    
    .OUTPUTS
    System.Security.AccessControl.InheritanceFlags.
    
    .LINK
    ConvertTo-PropagationFlags
    
    .LINK
    Grant-Permissions
    
    .EXAMPLE
    ConvertTo-InheritanceFlags -ContainerInheritanceFlags ContainerAndSubContainersAndLeaves
    
    Returns `InheritanceFlags.ContainerInherit|InheritanceFlags.ObjectInherit`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Security.ContainerInheritanceFlags]
        # The value to convert to an `InheritanceFlags` value.
        $ContainerInheritanceFlags
    )

    $Flags = [Security.AccessControl.InheritanceFlags]
    $map = @{
        'Container' =                                  $Flags::None;
        'SubContainers' =                              $Flags::ContainerInherit;
        'Leaves' =                                     $Flags::ObjectInherit;
        'ChildContainers' =                            $Flags::ContainerInherit;
        'ChildLeaves' =                                $Flags::ObjectInherit;
        'ContainerAndSubContainers' =                  $Flags::ContainerInherit;
        'ContainerAndLeaves' =                         $Flags::ObjectInherit;
        'SubContainersAndLeaves' =                    ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ContainerAndChildContainers' =                $Flags::ContainerInherit;
        'ContainerAndChildLeaves' =                    $Flags::ObjectInherit;
        'ContainerAndChildContainersAndChildLeaves' = ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ContainerAndSubContainersAndLeaves' =        ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ChildContainersAndChildLeaves' =             ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
    }
    $key = $ContainerInheritanceFlags.ToString()
    if( $map.ContainsKey( $key) )
    {
        return $map[$key]
    }
    
    Write-Error ('Unknown Carbon.Security.ContainerInheritanceFlags enumeration value {0}.' -f $ContainerInheritanceFlags) 
}

function ConvertTo-PropagationFlags
{
    <#
    .SYNOPSIS
    Converts a `Carbon.Security.ContainerInheritanceFlags` value to a `System.Security.AccessControl.PropagationFlags` value.
    
    .DESCRIPTION
    The `Carbon.Security.ContainerInheritanceFlags` enumeration encapsulates oth `System.Security.AccessControl.PropagationFlags` and `System.Security.AccessControl.InheritanceFlags`.  Make sure you also call `ConvertTo-InheritancewFlags` to get the inheritance value.
    
    .OUTPUTS
    System.Security.AccessControl.PropagationFlags.
    
    .LINK
    ConvertTo-InheritanceFlags
    
    .LINK
    Grant-Permissions
    
    .EXAMPLE
    ConvertTo-PropagationFlags -ContainerInheritanceFlags ContainerAndSubContainersAndLeaves
    
    Returns `PropagationFlags.None`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Security.ContainerInheritanceFlags]
        # The value to convert to an `PropagationFlags` value.
        $ContainerInheritanceFlags
    )

    $Flags = [Security.AccessControl.PropagationFlags]
    $map = @{
        'Container' =                                  $Flags::None;
        'SubContainers' =                              $Flags::InheritOnly;
        'Leaves' =                                     $Flags::InheritOnly;
        'ChildContainers' =                           ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
        'ChildLeaves' =                               ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
        'ContainerAndSubContainers' =                  $Flags::None;
        'ContainerAndLeaves' =                         $Flags::None;
        'SubContainersAndLeaves' =                     $Flags::InheritOnly;
        'ContainerAndChildContainers' =                $Flags::NoPropagateInherit;
        'ContainerAndChildLeaves' =                    $Flags::NoPropagateInherit;
        'ContainerAndChildContainersAndChildLeaves' =  $Flags::NoPropagateInherit;
        'ContainerAndSubContainersAndLeaves' =         $Flags::None;
        'ChildContainersAndChildLeaves' =             ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
    }
    $key = $ContainerInheritanceFlags.ToString()
    if( $map.ContainsKey( $key ) )
    {
        return $map[$key]
    }
    
    Write-Error ('Unknown Carbon.Security.ContainerInheritanceFlags enumeration value {0}.' -f $ContainerInheritanceFlags) 
}

function Get-Permissions
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a path.
    
    .DESCRIPTION
    Permissions for a specific identity can also be returned.  Access control entries are for a path's discretionary access control list.
    
    To return inherited permissions, use the `Inherited` switch.  Otherwise, only non-inherited (i.e. explicit) permissions are returned.
    
    .OUTPUTS
    System.Security.AccessControl.AccessRule.
    
    .EXAMPLE
    Get-Permissions -Path C:\Windows
    
    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on `C:\windows`.
    
    .EXAMPLE
    Get-Permissions -Path hklm:\Software -Inherited
    
    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on `hklm:\software`.
    
    .EXAMPLE
    Get-Permissions -Path C:\Windows -Idenity Administrators
    
    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on `C:\windows`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path whose permissions (i.e. access control rules) to return.
        $Path,
        
        [string]
        # The identity whose permissiosn (i.e. access control rules) to return.
        $Identity,
        
        [Switch]
        # Return inherited permissions in addition to explicit permissions.
        $Inherited
    )
   
    $rIdentity = $Identity
    if( $Identity )
    {
        $rIdentity = Resolve-IdentityName -Name $Identity
        if( -not $rIdentity )
        {
            return
        }
    }
    
    Get-Acl -Path $Path |
        Select-Object -ExpandProperty Access |
        Where-Object { 
            if( $Inherited )
            {
                return $true 
            }
            return (-not $_.IsInherited)
        }
        Where-Object {
            if( $rIdentity )
            {
                return ($_.IdentityReference.Value -eq $rIdentity)
            }
            
            return $true
        }    
}


function Grant-Permissions
{
    <#
    .SYNOPSIS
    Grants permission on a file, directory or registry key.

    .DESCRIPTION
    Granting access to a file system entry or registry key requires a lot of steps.  This method reduces it to one call.  Very helpful.

    It has the advantage that it will set permissions on a file system object or a registry.  If `Path` is absolute, the correct provider (file system or registry) is used.  If `Path` is relative, the provider of the current location will be used.

    The `Permissions` attribute can be a list of [FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx) or [RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).

    This command will show you the values for the `FileSystemRights`:

        [Enum]::GetValues([Security.AccessControl.FileSystemRights])

    This command will show you the values for the `RegistryRights`:

        [Enum]::GetValues([Security.AccessControl.RegistryRights])
        
    When setting permissions on a container (directory/registry key) You can control inheritance and propagation flags using the `ApplyTo` parameter.  There are 13 possible combinations.  Examples work best.  Here is a simple hierarchy:

            C
           / \
          CC CL
         /  \
        GC  GL
    
    C is the **C**ontainer permissions are getting set on
    CC is a **C**hild **C**ontainer.
    CL is a **C**hild ** **L**eaf
    GC is a **G**randchild **C**ontainer and includes all sub-containers below it.
    GL is a **G**randchild **L**eaf.
    
    The `ApplyTo` parameter takes one of the following 13 values and applies permissions to:
    
     * **Container** - The container itself and nothing below it.  (No inheritance or propagation flags.)
     * **SubContainers** - All sub-containers under the container, e.g. CC and GC. (`InheritanceFlags.ContainerInherit` and `PropagationFlags.InheritOnly`)
     * **Leaves** - All leaves under the container, e.g. CL and GL. (`InheritanceFlags.ObjectInherit` and `PropagationFlags.InheritOnly`)
     * **ChildContainers** - Just the container's child containers, e.g. CC. (`InheritanceFlags.ContainerInherit` and `PropagationFlags.InheritOnly|PropagationFlags.NoPropagateInherit`)
     * **ChildLeaves** - Just the container's child leaves, e.g. CL. (`InheritanceFlags.ObjectInherit` and `PropagationFlags.InheritOnly`)
     * **ContainerAndSubContainers** - The container and all its sub-containers, e.g. C, CC, and GC. (`InheritanceFlags.ContainerInherit`)
     * **ContainerAndLeaves** - The container and all leaves under it, e.g. C and CL. (`InheritanceFlags.ObjectInherit`)
     * **SubContainerAndLeaves** - All sub-containers and leaves, but not the container itself, e.g. CC, CL, GC, and GL. (`InheritanceFlags.ContainerInherit|InheritanceFlags.ObjectInherit` and `PropagationFlags.InheritOnly`)
     * **ContainerAndChildContainers** - The container and all just its child containers, e.g. C and CC. (`InheritanceFlags.ContainerInherit` and `PropagationFlags.
     * **ContainerAndChildLeaves** - The container and just its child leaves, e.g. C and CL.
     * **ContainerAndChildContainersAndChildLeaves** - The container and just its child containers/leaves, e.g. C, CC, and CL.
     * **ContainerAndSubContainersAndLeaves** - Everything, full inheritance/propogation, e.g. C, CC, GC, GL.  **This is the default.**
     * **ChildContainersAndChildLeaves**  - Just the container's child containers/leaves, e.g. CC and CL.

     The following table maps `ContainerInheritanceFlags` values to the actual `InheritanceFlags` and `PropagationFlags` values used:
         
		 **ContainerInheritanceFlags**               **InheritanceFlags**             **PropagationFlags**
         Container 	                                 None                             None
         SubContainers                               ContainerInherit                 InheritOnly
         Leaves                                      ObjectInherit                    InheritOnly
         ChildContainers                             ContainerInherit                 InheritOnly,NoPropagateInherit
         ChildLeaves                                 ObjectInherit                    InheritOnly
         ContainerAndSubContainers                   ContainerInherit                 None
         ContainerAndLeaves                          ObjectInherit                    None
         SubContainerAndLeaves                       ContainerInherit,ObjectInherit   InheritOnly
         ContainerAndChildContainers                 ContainerInherit                 None
         ContainerAndChildLeaves                     ObjectInherit                    None
         ContainerAndChildContainersAndChildLeaves   ContainerInherit,ObjectInherit   NoPropagateInherit
         ContainerAndSubContainersAndLeaves          ContainerInherit,ObjectInherit   None
         ChildContainersAndChildLeaves               ContainerInherit,ObjectInherit   InheritOnly
    
    The above information adpated from [Manage Access to Windows Objects with ACLs and the .NET Framework](http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3), published in the November 2004 copy of *MSDN Magazine*.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3    
    
    .LINK
    Unprotect-AclAccessRules

    .EXAMPLE
    Grant-Permissions -Identity ENTERPRISE\Engineers -Permissions FullControl -Path C:\EngineRoom

    Grants the Enterprise's engineering group full control on the engine room.  Very important if you want to get anywhere.

    .EXAMPLE
    Grant-Permissions -Identity ENTERPRISE\Interns -Permissions ReadKey,QueryValues,EnumerateSubKeys -Path rklm:\system\WarpDrive

    Grants the Enterprise's interns access to read about the warp drive.  They need to learn someday, but at least they can't change anything.
    
    .EXAMPLE
    Grant-Permissions -Identity ENTERPRISE\Engineers -Permissions FullControl -Path C:\EngineRoom -Clear
    
    Grants the Enterprise's engineering group full control on the engine room.  Any non-inherited, existing access rules are removed from `C:\EngineRoom`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permissions,
        
        [Carbon.Security.ContainerInheritanceFlags]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo = ([Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainersAndLeaves),
        
        [Switch]
        # Removes all non-inherited permissions on the item.
        $Clear
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
    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    if( Test-Path $Path -PathType Container )
    {
        $inheritanceFlags = ConvertTo-InheritanceFlags -ContainerInheritanceFlags $ApplyTo
        $propagationFlags = ConvertTo-PropagationFlags -ContainerInheritanceFlags $ApplyTo
    }
    else
    {
        if( $PSBoundParameters.ContainsKey( 'ApplyTo' ) )
        {
            Write-Warning "Can't apply inheritance rules to a leaf. Please omit `ApplyTo` parameter when `Path` is a leaf."
        }
    }
    
    $accessRule = New-Object "Security.AccessControl.$($providerName)AccessRule" $identity,$rights,$inheritanceFlags,$propagationFlags,"Allow"
    if( $Clear )
    {
        $rules = $currentAcl.Access |
                    Where-Object { -not $_.IsInherited }
        
        if( $rules )
        {
            $rules | 
                ForEach-Object { $currentAcl.RemoveAccessRule( $_ ) }
        }
    }
    $currentAcl.SetAccessRule( $accessRule )
    Set-Acl $Path $currentAcl
}

function New-Credential
{
    <#
    .SYNOPSIS
    Creates a new `PSCredential` object from a given username and password.

    .DESCRIPTION
    Many PowerShell commands require a `PSCredential` object instead of username/password.  This function will create one for you.

    .OUTPUTS
    System.Management.Automation.PSCredential.

    .EXAMPLE
    New-Credential -User ENTERPRISE\picard -Password 'earlgrey'

    Creates a new credential object for Captain Picard.
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
    Checks if the current user is an administrator or has administrative privileges.

    .DESCRIPTION
    Many tools, cmdlets, and APIs require administative privileges.  Use this function to check.  Returns `True` if the current user has administrative privileges, or `False` if he doesn't.  Or she.  Or it.  

    This function handles UAC and computers where UAC is disabled.

    .EXAMPLE
    Test-AdminPrivileges

    Returns `True` if the current user has administrative privileges, or `False` if the user doesn't.
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

function Unprotect-AclAccessRules
{
    <#
    .SYNOPSIS
    Removes access rule protection on a file or registry path.
    
    .DESCRIPTION
    New items in the registry or file system will usually inherit ACLs from its parent.  This function stops an item from inheriting rules from its, and will optionally preserve the existing inherited rules.  Any existing, non-inherited access rules are left in place.
    
    .LINK
    Grant-Permissions
    
    .EXAMPLE
    Unprotect-AclAccessRules -Path C:\Projects\Carbon
    
    Removes all inherited access rules from the `C:\Projects\Carbon` directory.  Non-inherited rules are preserved.
    
    .EXAMPLE
    Unprotect-AclAccessRules -Path hklm:\Software\Carbon -Preserve
    
    Stops `HKLM:\Software\Carbon` from inheriting acces rules from its parent, but preserves the existing, inheritied access rules.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]
        # The file system or registry path whose 
        $Path,
        
        [Switch]
        # Keep the inherited access rules on this item.
        $Preserve
    )
    
    Write-Host "Removing access rule inheritance on '$Path'."
    $acl = Get-Acl -Path $Path
    $acl.SetAccessRuleProtection( $true, $Preserve )
    $acl | Set-Acl -Path $Path
}

