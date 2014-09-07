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

function Revoke-Permission
{
    <#
    .SYNOPSIS
    Revokes *explicit* permissions on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Revokes all of an identity's *explicit* permissions on a file, directory, registry key, or certificate's private key/key container. Only explicit permissions are considered; inherited permissions are ignored.

    If the identity doesn't have permission, nothing happens, not even errors written out.

    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Protect-Acl

    .LINK
    Test-Permission

    .EXAMPLE
    Revoke-Permission -Identity ENTERPRISE\Engineers -Path 'C:\EngineRoom'

    Demonstrates how to revoke all of the 'Engineers' permissions on the `C:\EngineRoom` directory.

    .EXAMPLE
    Revoke-Permission -Identity ENTERPRISE\Interns -Path 'hklm:\system\WarpDrive'

    Demonstrates how to revoke permission on a registry key.

    .EXAMPLE
    Revoke-Permission -Identity ENTERPRISE\Officers -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'

    Demonstrates how to revoke the Officers' permission to the `cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678` certificate's private key/key container.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be revoked.  Can be a file system, registry, or certificate path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The identity losing permissions.
        $Identity
    )

    Set-StrictMode -Version 'Latest'
    
    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $ruleToRemove = Get-Permission -Path $Path -Identity $Identity
    if( $ruleToRemove )
    {
        $Identity = Resolve-IdentityName -Name $Identity

        Get-Item $Path -Force |
            ForEach-Object {
                if( $_.PSProvider.Name -eq 'Certificate' )
                {
                    $certificate = $_

                    [Security.AccessControl.CryptoKeySecurity]$keySecurity = $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity

                    [void] $keySecurity.RemoveAccessRule( $ruleToRemove)

                    Set-CryptoKeySecurity -Certificate $certificate `
                                          -CryptoKeySecurity $keySecurity `
                                          -Action ('revoke {0}''s permissions' -f $Identity) `
                                          -PSPath $certificate.PSPath
                }
                else
                {
                    # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
                    # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security descriptor.
                    # See http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
                    $currentAcl = $_.GetAccessControl('Access')
                    [void]$currentAcl.RemoveAccessRule($ruleToRemove)
                    if( $PSCmdlet.ShouldProcess( $Path, ('revoke {0}''s permissions' -f $Identity)) )
                    {
                        Set-Acl -Path $Path -AclObject $currentAcl
                    }
                }
            }

    }
    
}
