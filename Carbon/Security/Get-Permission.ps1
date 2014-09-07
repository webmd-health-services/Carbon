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

function Get-Permission
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a file, directory, registry key, or certificate's private key/key container.
    
    .DESCRIPTION
    Permissions for a specific identity can also be returned.  Access control entries are for a path's discretionary access control list.
    
    To return inherited permissions, use the `Inherited` switch.  Otherwise, only non-inherited (i.e. explicit) permissions are returned.

    Certificate permissions are only returned if a certificate has a private key/key container. If a certificate doesn't have a private key, `$null` is returned. 
    
    .OUTPUTS
    System.Security.AccessControl.AccessRule.
    
    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Protect-Acl

    .LINK
    Revoke-Permission

    .LINK
    Test-Permission

    .EXAMPLE
    Get-Permission -Path 'C:\Windows'
    
    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on `C:\windows`.
    
    .EXAMPLE
    Get-Permission -Path 'hklm:\Software' -Inherited
    
    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on `hklm:\software`.
    
    .EXAMPLE
    Get-Permission -Path 'C:\Windows' -Idenity Administrators
    
    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on `C:\windows`.

    .EXAMPLE
    Get-Permission -Path 'Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678'

    Returns `System.Security.AccessControl.CryptoKeyAccesRule` objects for certificate's `Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678` private key/key container. If it doesn't have a private key, `$null` is returned.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.AccessRule])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path whose permissions (i.e. access control rules) to return. File system, registry, or certificate paths supported. Wildcards supported.
        $Path,
        
        [string]
        # The identity whose permissiosn (i.e. access control rules) to return.
        $Identity,
        
        [Switch]
        # Return inherited permissions in addition to explicit permissions.
        $Inherited
    )
   
    Set-StrictMode -Version 'Latest'

    $account = $null
    if( $Identity  )
    {
        if( Test-Identity -Name $Identity )
        {
            $Identity = Resolve-IdentityName -Name $Identity
        }
    }

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $Path)
        return
    }
    
    Invoke-Command -ScriptBlock {
        Get-Item -Path $Path -Force |
            ForEach-Object { 
                if( $_.PSProvider.Name -eq 'Certificate' )
                {
                    if( $_.HasPrivateKey -and $_.PrivateKey )
                    {
                        $_.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity
                    }
                }
                else
                {
                    $_.GetAccessControl([Security.AccessControl.AccessControlSections]::Access)
                }
            }
        } |
        Select-Object -ExpandProperty Access |
        Where-Object { 
            if( $Inherited )
            {
                return $true 
            }
            return (-not $_.IsInherited)
        } |
        Where-Object {
            if( $Identity )
            {
                return ($_.IdentityReference.Value -eq $Identity)
            }
            
            return $true
        }    
}

Set-Alias -Name 'Get-Permissions' -Value 'Get-Permission'
