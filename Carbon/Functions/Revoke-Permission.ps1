
function Revoke-CPermission
{
    <#
    .SYNOPSIS
    Revokes *explicit* permissions on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Revokes all of an identity's *explicit* permissions on a file, directory, registry key, or certificate's private key/key container. Only explicit permissions are considered; inherited permissions are ignored.

    If the identity doesn't have permission, nothing happens, not even errors written out.

    .LINK
    Carbon_Permission

    .LINK
    Disable-CAclInheritance

    .LINK
    Enable-CAclInheritance

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Engineers -Path 'C:\EngineRoom'

    Demonstrates how to revoke all of the 'Engineers' permissions on the `C:\EngineRoom` directory.

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Interns -Path 'hklm:\system\WarpDrive'

    Demonstrates how to revoke permission on a registry key.

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Officers -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'

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

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-CPathProvider -Path $Path | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
        if( -not (Test-CCryptoKeyAvailable) )
        {
            $providerName = 'FileSystem'
        }
    }

    $rulesToRemove = Get-CPermission -Path $Path -Identity $Identity
    if( $rulesToRemove )
    {
        $Identity = Resolve-CIdentityName -Name $Identity
        $rulesToRemove | ForEach-Object { Write-Verbose ('[{0}] [{1}]  {2} -> ' -f $Path,$Identity,$_."$($providerName)Rights") }

        Get-Item $Path -Force |
            ForEach-Object {
                if( $_.PSProvider.Name -eq 'Certificate' )
                {
                    if( -not ($_.PrivateKey | Get-Member 'CspKeyContainerInfo') )
                    {
                        $privateKeyFileName = $_.PrivateKey.Key.UniqueName
                        # See https://docs.microsoft.com/en-us/windows/win32/seccng/key-storage-and-retrieval
                        $keyStoragePaths =         @(
                            "$($env:AppDATA)\Microsoft\Crypto", 
                            "$($env:ALLUSERSPROFILE)\Application Data\Microsoft\Crypto\SystemKeys", 
                            "$($env:WINDIR)\ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Crypto\Keys", 
                            "$($env:WINDIR)\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Crypto\Keys", 
                            "$($env:ALLUSERSPROFILE)\Application Data\Microsoft\Crypto",
                            "$($env:ALLUSERSPROFILE)\Microsoft\Crypto"
                        )
                        $privateKeyFiles = $keyStoragePaths | Get-ChildItem -Recurse -Force -Filter $privateKeyFileName -ErrorAction Ignore
                        if( -not $privateKeyFiles )
                        {
                            $msg = "Failed to find the private key file for certificate ""$($Path)"" (subject: $($_.Subject); " +
                                    "thumbprint: $($_.Thumbprint); expected file name: $($privateKeyFileName)). This is most " +
                                    "likely because you don't have permission to read private keys, or we''re not looking in the right " +
                                    "places. According to [Microsoft docs](https://docs.microsoft.com/en-us/windows/win32/seccng/key-storage-and-retrieval), " +
                                    "private keys are stored under one of these directories:" + [Environment]::NewLine +
                                    " * $($keyStoragePaths -join "$([Environment]::NewLine) * ")" + [Environment]::NewLine +
                                    "If there are other locations we should be looking, please " +
                                    "[submit an issue/bug report](https://github.com/webmd-health-services/Carbon/issues)."
                            Write-Error -Message $msg
                            return
                        }
                    
                        $revokePermissionParams = New-Object -TypeName 'Collections.Generic.Dictionary[[string], [object]]' `
                                                            -ArgumentList $PSBoundParameters
                        $revokePermissionParams.Remove('Path')
                        foreach( $privateKeyFile in $privateKeyFiles )
                        {
                            Revoke-CPermission -Path $privateKeyFile.FullName @revokePermissionParams
                        }
                        return
                    }

                    [Security.Cryptography.X509Certificates.X509Certificate2]$certificate = $_

                    [Security.AccessControl.CryptoKeySecurity]$keySecurity = $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity

                    $rulesToRemove | ForEach-Object { [void] $keySecurity.RemoveAccessRule($_) }

                    Set-CryptoKeySecurity -Certificate $certificate -CryptoKeySecurity $keySecurity -Action ('revoke {0}''s permissions' -f $Identity)
                }
                else
                {
                    # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
                    # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security descriptor.
                    # See http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
                    $currentAcl = $_.GetAccessControl('Access')

                    $rulesToRemove | ForEach-Object { [void]$currentAcl.RemoveAccessRule($_) }
                    if( $PSCmdlet.ShouldProcess( $Path, ('revoke {0}''s permissions' -f $Identity)) )
                    {
                        Set-Acl -Path $Path -AclObject $currentAcl
                    }
                }
            }

    }
    
}

