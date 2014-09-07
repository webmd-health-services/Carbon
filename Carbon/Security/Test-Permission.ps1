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

function Test-Permission
{
    <#
    .SYNOPSIS
    Tests if permissions are set on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Sometimes, you don't want to use `Grant-Permission` on a big tree.  In these situations, use `Test-Permission` to see if permissions are set on a given path.

    This function supports file system, registry, and certificate private key/key container permissions.  You can also test the inheritance and propogation flags on containers, in addition to the permissions, with the `ApplyTo` parameter.  See [Grant-Permission](Grant-Permission.html) documentation for an explanation of the `ApplyTo` parameter.

    Inherited permissions on *not* checked by default.  To check inherited permission, use the `-Inherited` switch.

    By default, the permission check is not exact, i.e. the user may have additional permissions to what you're checking.  If you want to make sure the user has *exactly* the permission you want, use the `-Exact` switch.  Please note that by default, NTFS will automatically add/grant `Synchronize` permission on an item, which is handled by this function.

    When checking for permissions on certificate private keys/key containers, if a certificate doesn't have a private key, `$true` is returned.

    .OUTPUTS
    System.Boolean.

    .LINK
    ConvertTo-ContainerInheritanceFlags

    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Protect-Acl

    .LINK
    Revoke-Permission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx
    
    .EXAMPLE
    Test-Permission -Identity 'STARFLEET\JLPicard' -Permission 'FullControl' -Path 'C:\Enterprise\Bridge'

    Demonstrates how to check that Jean-Luc Picard has `FullControl` permission on the `C:\Enterprise\Bridge`.  

    .EXAMPLE
    Test-Permission -Identity 'STARFLEET\GLaForge' -Permission 'WriteKey' -Path 'HKLM:\Software\Enterprise\Engineering'

    Demonstrates how to check that Geordi LaForge can write registry keys at `HKLM:\Software\Enterprise\Engineering`.

    .EXAMPLE
    Test-Permission -Identity 'STARFLEET\Worf' -Permission 'Write' -ApplyTo 'Container' -Path 'C:\Enterprise\Brig'

    Demonstrates how to test for inheritance/propogation flags, in addition to permissions.

    .EXAMPLE
    Test-Permission -Identity 'STARFLEET\Data' -Permission 'GenericWrite' -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'

    Demonstrates how to test for permissions on a certificate's private key/key container. If the certificate doesn't have a private key, returns `$true`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be checked.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group whose permissions to check.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission to test for: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,
        
        [Carbon.Security.ContainerInheritanceFlags]
        # The container and inheritance flags to check. Ignored if `Path` is a file. These are ignored if not supplied. See `Grant-Permission` for detailed explanation of this parameter. This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo,

        [Switch]
        # Include inherited permissions in the check.
        $Inherited,

        [Switch]
        # Check for the exact permissions, inheritance flags, and propagation flags, i.e. make sure the identity has *only* the permissions you specify.
        $Exact
    )

    Set-StrictMode -Version 'Latest'

    $originalPath = $Path
    $Path = Resolve-Path -Path $Path -ErrorAction 'SilentlyContinue'
    if( -not $Path -or -not (Test-Path -Path $Path) )
    {
        if( -not $Path )
        {
            $Path = $originalPath
        }
        Write-Error ('Unable to test {0}''s {1} permissions: path ''{2}'' not found.' -f $Identity,($Permission -join ','),$Path)
        return
    }

    $providerName = Get-PathProvider -Path $Path | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
    }

    if( ($providerName -eq 'FileSystem' -or $providerName -eq 'CryptoKey') -and $Exact )
    {
        # Synchronize is always on and can't be turned off.
        $Permission += 'Synchronize'
    }
    $rights = $Permission | ConvertTo-ProviderAccessControlRights -ProviderName $providerName
    if( -not $rights )
    {
        Write-Error ('Unable to test {0}''s {1} permissions on {2}: received an unknown permission.' -f $Identity,$Permission,$Path)
        return
    }

    $originalIdentity = $Identity
    $Identity = Resolve-IdentityName -Name $Identity
    if( -not $Identity )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $originalIdentity)
        return
    }

    $rightsPropertyName = '{0}Rights' -f $providerName
    $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    $testApplyTo = $false
    if( $PSBoundParameters.ContainsKey('ApplyTo') )
    {
        if( (Test-Path -Path $Path -PathType Leaf ) )
        {
            Write-Warning "Can't test inheritance/propagation rules on a leaf. Please omit `ApplyTo` parameter when `Path` is a leaf."
        }
        else
        {
            $testApplyTo = $true
            $inheritanceFlags = ConvertTo-InheritanceFlag -ContainerInheritanceFlag $ApplyTo
            $propagationFlags = ConvertTo-PropagationFlag -ContainerInheritanceFlag $ApplyTo
        }
    }

    if( $providerName -eq 'CryptoKey' )
    {
        # If the certificate doesn't have a private key, return $true.
        if( (Get-Item -Path $Path | Where-Object { -not $_.HasPrivateKey } ) )
        {
            return $true
        }
    }

    $acl = Get-Permission -Path $Path -Identity $Identity -Inherited:$Inherited | 
                Where-Object { $_.AccessControlType -eq 'Allow' } |
                Where-Object { $_.IsInherited -eq $Inherited } |
                Where-Object { 
                    if( $Exact )
                    {
                        return ($_.$rightsPropertyName -eq $rights)
                    }
                    else
                    {
                        return ($_.$rightsPropertyName -band $rights) -eq $rights
                    }
                } |
                Where-Object {
                    if( -not $testApplyTo )
                    {
                        return $true
                    }

                    if( $Exact )
                    {
                        return ($_.InheritanceFlags -eq $inheritanceFlags) -and ($_.PropagationFlags -eq $propagationFlags)
                    }
                    else
                    {
                        return (($_.InheritanceFlags -band $inheritanceFlags) -eq $inheritanceFlags) -and `
                               (($_.PropagationFlags -and $propagationFlags) -eq $propagationFlags)
                    }
                }
    if( $acl )
    {
        return $true
    }
    else
    {
        return $false
    }
}
