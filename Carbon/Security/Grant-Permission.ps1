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

function Grant-Permission
{
    <#
    .SYNOPSIS
    Grants permission on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Granting access to a file system entry, registry key, or certificate's private key/key container requires a lot of steps.  This method reduces it to one call.  Very helpful.

    It has the advantage that it will set permissions on a file system object, a registry key, or a certificate's private key/key container.  If `Path` is absolute, the correct provider (file system or registry) is used.  If `Path` is relative, the provider of the current location will be used.

    The `Permissions` attribute can be a list of [FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx), [RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx), [CryptoKeyRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx).

    This command will show you the values for the `FileSystemRights`:

        [Enum]::GetValues([Security.AccessControl.FileSystemRights])

    This command will show you the values for the `RegistryRights`:

        [Enum]::GetValues([Security.AccessControl.RegistryRights])
        
    This command will show you the values for the `CryptoKeyRights`:

        [Enum]::GetValues([Security.AccessControl.CryptoKeyRights])

    ## Directories and Registry Keys

    When setting permissions on a container (directory/registry key) you can control inheritance and propagation flags using the `ApplyTo` parameter.  There are 13 possible combinations.  Examples work best.  Here is a simple hierarchy:

            C
           / \
          CC CL
         /  \
        GC  GL
    
    C is the **C**ontainer permissions are getting set on  
    CC is a **C**hild **C**ontainer  
    CL is a **C**hild **L**eaf  
    GC is a **G**randchild **C**ontainer and includes all sub-containers below it  
    GL is a **G**randchild **L**eaf  
    
    The `ApplyTo` parameter takes one of the following 13 values and applies permissions to:
    
     * **Container** - The container itself and nothing below it.
     * **SubContainers** - All sub-containers under the container, e.g. CC and GC. 
     * **Leaves** - All leaves under the container, e.g. CL and GL.
     * **ChildContainers** - Just the container's child containers, e.g. CC.
     * **ChildLeaves** - Just the container's child leaves, e.g. CL.
     * **ContainerAndSubContainers** - The container and all its sub-containers, e.g. C, CC, and GC.
     * **ContainerAndLeaves** - The container and all leaves under it, e.g. C and CL.
     * **SubContainerAndLeaves** - All sub-containers and leaves, but not the container itself, e.g. CC, CL, GC, and GL.
     * **ContainerAndChildContainers** - The container and all just its child containers, e.g. C and CC.
     * **ContainerAndChildLeaves** - The container and just its child leaves, e.g. C and CL.
     * **ContainerAndChildContainersAndChildLeaves** - The container and just its child containers/leaves, e.g. C, CC, and CL.
     * **ContainerAndSubContainersAndLeaves** - Everything, full inheritance/propogation, e.g. C, CC, GC, GL.  **This is the default.**
     * **ChildContainersAndChildLeaves**  - Just the container's child containers/leaves, e.g. CC and CL.

    The following table maps `ContainerInheritanceFlags` values to the actual `InheritanceFlags` and `PropagationFlags` values used:
         
        ContainerInheritanceFlags                   InheritanceFlags                 PropagationFlags
        -------------------------                   ----------------                 ----------------
        Container                                   None                             None
        SubContainers                               ContainerInherit                 InheritOnly
        Leaves                                      ObjectInherit                    InheritOnly
        ChildContainers                             ContainerInherit                 InheritOnly,
                                                                                     NoPropagateInherit
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

    If you prefer to speak in `InheritanceFlags` or `PropagationFlags`, you can use the `ConvertTo-ContainerInheritaceFlags` function to convert your flags into Carbon's flags.

    ## Certificate Private Keys/Key Containers

    When setting permissions on a certificate's private key/key container, if a certificate doesn't have a private key, it is ignored and no permissions are set. Since certificate's are always leaves, the `ApplyTo` parameter is ignored.

    When using the `-Clear` switch, note that the local `Administrators` account will always remain. In testing on Windows 2012 R2, we noticed that when `Administrators` access was removed, you couldn't read the key anymore. 

    .LINK
    ConvertTo-ContainerInheritanceFlags

    .LINK
    Get-Permission

    .LINK
    Protect-Acl

    .LINK
    Revoke-Permission

    .LINK
    Test-Permission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3    
    
    .EXAMPLE
    Grant-Permission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom

    Grants the Enterprise's engineering group full control on the engine room.  Very important if you want to get anywhere.

    .EXAMPLE
    Grant-Permission -Identity ENTERPRISE\Interns -Permission ReadKey,QueryValues,EnumerateSubKeys -Path rklm:\system\WarpDrive

    Grants the Enterprise's interns access to read about the warp drive.  They need to learn someday, but at least they can't change anything.
    
    .EXAMPLE
    Grant-Permission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom -Clear
    
    Grants the Enterprise's engineering group full control on the engine room.  Any non-inherited, existing access rules are removed from `C:\EngineRoom`.
    
    .EXAMPLE
    Grant-Permission -Identity ENTERPRISE\Engineers -Permission FullControl -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'
    
    Grants the Enterprise's engineering group full control on the `1234567890ABCDEF1234567890ABCDEF12345678` certificate's private key/key container.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system, registry, or certificate path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
		[Alias('Permissions')]
        $Permission,
        
        [Carbon.Security.ContainerInheritanceFlags]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo = ([Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainersAndLeaves),
        
        [Switch]
        # Removes all non-inherited permissions on the item.
        $Clear
    )
    
    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-PathProvider -Path $Path | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
    }

    if( $providerName -ne 'Registry' -and $providerName -ne 'FileSystem' -and $providerName -ne 'CryptoKey' )
    {
        Write-Error "Unsupported path: '$Path' belongs to the '$providerName' provider.  Only file system, registry, and certificate paths are supported."
        return
    }

    $rights = $Permission | ConvertTo-ProviderAccessControlRights -ProviderName $providerName
    if( -not $rights )
    {
        Write-Error ('Unable to grant {0} {1} permissions on {2}: received an unknown permission.' -f $Identity,($Permission -join ','),$Path)
        return
    }

    if( -not (Test-Identity -Name $Identity ) )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $Identity)
        return
    }

    $Identity = Resolve-IdentityName -Name $Identity
    
    Write-Verbose "Granting $Identity $Permission on $Path."
    if( $providerName -eq 'CryptoKey' )
    {
        Get-Item -Path $Path |
            Where-Object { $_.HasPrivateKey -and $_.PrivateKey } |
            ForEach-Object {
                $certificate = $_
                [Security.AccessControl.CryptoKeySecurity]$keySecurity = $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity

                $rulesToRemove = @()
                if( $Clear )
                {
                    $rulesToRemove = $keySecurity.Access | 
                                        Where-Object { $_.IdentityReference.Value -ne $Identity } |
                                        # Don't remove Administrators access. 
                                        Where-Object { $_.IdentityReference.Value -ne 'BUILTIN\Administrators' }
                    if( $rulesToRemove )
                    {
                        $rulesToRemove | ForEach-Object { 
                            Write-Verbose ('Removing {0}''s {1} permissions.' -f $_.IdentityReference,$_.CryptoKeyRights)
                            if( -not $keySecurity.RemoveAccessRule( $_ ) )
                            {
                                Write-Error ('Failed to remove {0}''s {1} permissions on ''{2}'' (3) certificate''s private key.' -f $_.IdentityReference,$_.CryptoKeyRights,$Certificate.Subject,$Certificate.Thumbprint)
                            }
                        }
                    }
                }
                
                $accessRule = New-Object 'Security.AccessControl.CryptoKeyAccessRule' ($Identity,$rights,'Allow')
                $keySecurity.SetAccessRule( $accessRule )

                Set-CryptoKeySecurity -Certificate $certificate `
                                      -CryptoKeySecurity $keySecurity `
                                      -Action ('grant {0} {1} permission(s)' -f $Identity,($Permission -join ',')) `
                                      -PSPath $certificate.PSPath
            }
    }
    else
    {
        # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
        # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security descriptor.
        # See http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
        $currentAcl = (Get-Item $Path -Force).GetAccessControl("Access")
    
        $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
        $propagationFlags = [Security.AccessControl.PropagationFlags]::None
        if( Test-Path $Path -PathType Container )
        {
            $inheritanceFlags = ConvertTo-InheritanceFlag -ContainerInheritanceFlag $ApplyTo
            $propagationFlags = ConvertTo-PropagationFlag -ContainerInheritanceFlag $ApplyTo
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
                    ForEach-Object { [void] $currentAcl.RemoveAccessRule( $_ ) }
            }
        }
        $currentAcl.SetAccessRule( $accessRule )
        Set-Acl $Path $currentAcl
    }
}

Set-Alias -Name 'Grant-Permissions' -Value 'Grant-Permission'
