
# Leave these here so that when Get-CPermission moves to its own module, these go with it.
Add-CTypeData -Type IO.DirectoryInfo `
              -MemberName 'GetAccessControl' `
              -MemberType ScriptMethod `
              -Value {
                    [CmdletBinding()]
                    param(
                        [Security.AccessControl.AccessControlSections] $IncludeSections =
                            [Security.AccessControl.AccessControlSections]::All
                    )

                    return [IO.FileSystemAclExtensions]::GetAccessControl($this, $IncludeSections)
                }

Add-CTypeData -Type IO.FileInfo `
              -MemberName 'GetAccessControl' `
              -MemberType ScriptMethod `
              -Value {
                    [CmdletBinding()]
                    param(
                        [Security.AccessControl.AccessControlSections]$IncludeSections =
                            [Security.AccessControl.AccessControlSections]::All
                    )

                    return [IO.FileSystemAclExtensions]::GetAccessControl($this, $IncludeSections)
                }

function Get-CPermission
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a file, directory, registry key, or certificate's private key/key
    container.

    .DESCRIPTION
    Permissions for a specific identity can also be returned.  Access control entries are for a path's discretionary
    access control list.

    To return inherited permissions, use the `Inherited` switch.  Otherwise, only non-inherited (i.e. explicit)
    permissions are returned.

    Certificate permissions are only returned if a certificate has a private key/key container. If a certificate doesn't
    have a private key, `$null` is returned.

    .OUTPUTS
    System.Security.AccessControl.AccessRule.

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
    Revoke-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    Get-CPermission -Path 'C:\Windows'

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on
    `C:\windows`.

    .EXAMPLE
    Get-CPermission -Path 'hklm:\Software' -Inherited

    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on
    `hklm:\software`.

    .EXAMPLE
    Get-CPermission -Path 'C:\Windows' -Idenity Administrators

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on
    `C:\windows`.

    .EXAMPLE
    Get-CPermission -Path 'Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678'

    Returns `System.Security.AccessControl.CryptoKeyAccesRule` objects for certificate's
    `Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678` private key/key container. If it doesn't have a
    private key, `$null` is returned.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.AccessRule])]
    param(
        # The path whose permissions (i.e. access control rules) to return. File system, registry, or certificate paths
        # supported. Wildcards supported.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity whose permissiosn (i.e. access control rules) to return.
        [String] $Identity,

        # Return inherited permissions in addition to explicit permissions.
        [switch] $Inherited
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = $null
    if( $Identity )
    {
        $account = Test-CIdentity -Name $Identity -NoWarn -PassThru
        if( $account )
        {
            $Identity = $account.FullName
        }
    }

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $Path)
        return
    }

    & {
            foreach ($item in (Get-Item -Path $Path -Force))
            {
                if( $item.PSProvider.Name -ne 'Certificate' )
                {
                    $item.GetAccessControl([Security.AccessControl.AccessControlSections]::Access) | Write-Output
                    continue
                }

                if (-not $item.HasPrivateKey)
                {
                    continue
                }

                if ($item.PrivateKey -and ($item.PrivateKey | Get-Member 'CspKeyContainerInfo'))
                {
                    $item.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity | Write-Output
                    continue
                }

                $item | Resolve-CPrivateKeyPath | Get-Acl | Write-Output
            }
        } |
        Select-Object -ExpandProperty 'Access' |
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

Set-Alias -Name 'Get-Permissions' -Value 'Get-CPermission'
