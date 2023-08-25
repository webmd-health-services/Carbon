
function Revoke-CPermission
{
    <#
    .SYNOPSIS
    Revokes *explicit* permissions on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Revokes all of an identity's *explicit* permissions on a file, directory, registry key, or certificate's private
    key/key container. Only explicit permissions are considered; inherited permissions are ignored.

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

    Demonstrates how to revoke the Officers' permission to the
    `cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678` certificate's private key/key container.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path on which the permissions should be revoked.  Can be a file system, registry, or certificate path.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity losing permissions.
        [Parameter(Mandatory)]
        [String] $Identity,

        # ***Internal.*** Do not use.
        [String] $Description
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-CPathProvider -Path $Path -NoWarn | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
        if( -not (Test-CCryptoKeyAvailable) )
        {
            $providerName = 'FileSystem'
        }
    }

    $rulesToRemove = Get-CPermission -Path $Path -Identity $Identity
    if (-not $rulesToRemove)
    {
        return
    }

    $Identity = Resolve-CIdentityName -Name $Identity

    foreach ($item in (Get-Item $Path -Force))
    {
        if( $item.PSProvider.Name -ne 'Certificate' )
        {
            if (-not $Description)
            {
                $Description = $item.ToString()
            }

            # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
            # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security
            # descriptor. See
            # http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
            $currentAcl = $item.GetAccessControl('Access')

            foreach ($ruleToRemove in $rulesToRemove)
            {
                $rmIdentity = $ruleToRemove.IdentityReference
                $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                $rmRights = $ruleToRemove."${providerName}Rights"
                Write-Information "${Description}  ${rmIdentity}  - ${rmType} ${rmRights}"
                [void]$currentAcl.RemoveAccessRule($ruleToRemove)
            }
            if( $PSCmdlet.ShouldProcess( $Path, ('revoke {0}''s permissions' -f $Identity)) )
            {
                Set-Acl -Path $Path -AclObject $currentAcl
            }
            continue
        }

        $certMsg = """$($item.Subject)"" (thumbprint: $($item.Thumbprint); path: " +
                   "cert:\$($item.PSPath | Split-Path -NoQualifier)) "
        if (-not $item.HasPrivateKey)
        {
            Write-Verbose -Message "Skipping certificate ${certMsg}because it doesn't have a private key."
            continue
        }

        if (-not $Description)
        {
            $Description = "cert:\$($item.PSPath | Split-Path -NoQualifier) ($($item.Thumbprint))"
        }

        $privateKey = $item.PrivateKey
        if ($privateKey -and ($item.PrivateKey | Get-Member 'CspKeyContainerInfo'))
        {
            [Security.Cryptography.X509Certificates.X509Certificate2]$certificate = $item

            [Security.AccessControl.CryptoKeySecurity]$keySecurity =
                $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity

            foreach ($ruleToRemove in $rulesToRemove)
            {
                $rmIdentity = $ruleToRemove.IdentityReference
                $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                $rmRights = $ruleToRemove."${providerName}Rights"
                Write-Information "${Description}  ${rmIdentity}  - ${rmType} ${rmRights}"
                [void] $keySecurity.RemoveAccessRule($ruleToRemove)
            }

            $action = "revoke ${Identity}'s permissions"
            Set-CryptoKeySecurity -Certificate $certificate -CryptoKeySecurity $keySecurity -Action $action
            return
        }

        $privateKeyFilesPaths = $item | Resolve-CPrivateKeyPath
        if (-not $privateKeyFilesPaths)
        {
            # Resolve-CPrivateKeyPath writes an appropriately detailed error message.
            continue
        }

        $revokePermissionParams = New-Object -TypeName 'Collections.Generic.Dictionary[[string], [object]]' `
                                             -ArgumentList $PSBoundParameters
        [void]$revokePermissionParams.Remove('Path')
        foreach( $privateKeyFilePath in $privateKeyFilesPaths )
        {
            Revoke-CPermission -Path $privateKeyFilePath @revokePermissionParams -Description $Description
        }
    }
}

