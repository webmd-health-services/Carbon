
function Resolve-CPrivateKeyPath
{
    <#
    .SYNOPSIS
    Finds the path to a certificate's private key.

    .DESCRIPTION
    The `Resolve-CPrivateKeyPath` function finds the path to a certificate's private key. Pipe the certificate object to
    the function (or pass one or more to the `Certificate` parameter). The function searches all the directories where
    keys are stored, [which are documented by
    Microsoft](https://learn.microsoft.com/en-us/windows/win32/seccng/key-storage-and-retrieval).

    If the certificate doesn't have a private key, have access to the private key, or no private key file exists, the
    function writes an error and returns nothing for that certificate.

    Returns the path to the private key as a string.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/seccng/key-storage-and-retrieval

    .EXAMPLE
    $cert | Resolve-CPrivateKeyPath

    Demonstrates that you can pipe X509Certificate2 objects to this function.

    .EXAMPLE
    Resolve-CPrivateKeyPath -Certificate $cert

    Demonstrates that you pass an X509Certificate2 object to the `Certificate` parameter.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        # The certificate whose private key path to get. Must have a private key and that private key must be accessible
        # by the current user.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Security.Cryptography.X509Certificates.X509Certificate2[]] $Certificate
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $searchPaths =
            & {
                $appData = [Environment]::GetFolderPath('ApplicationData')
                if ($appData)
                {
                    if ($IsWindows)
                    {
                        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
                        $sidString = $sid.ToString()

                        # CSP user private
                        Join-Path -Path $appData -ChildPath "Microsoft\Crypto\RSA\${sidString}"
                        Join-Path -Path $appData -ChildPath "Microsoft\Crypto\DSS\${sidString}"
                    }

                    # CNG user private
                    Join-Path -Path $appData -ChildPath "Microsoft\Crypto\Keys"
                }

                $commonAppDataPath = [Environment]::GetFolderPath('CommonApplicationData')
                if ($commonAppDataPath)
                {
                    # CSP local system private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\S-1-5-18'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\S-1-5-18'

                    # CNG local system private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\SystemKeys'

                    # CSP local service private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\S-1-5-19'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\S-1-5-19'

                    # CSP network service private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\S-1-5-20'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\S-1-5-20'

                    # CSP shared private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\MachineKeys'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\MachineKeys'

                    # CNG shared private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\Keys'
                }

                $windowsPath = [Environment]::GetFolderPath('Windows')
                if ($windowsPath)
                {
                    # CNG local service private
                    Join-Path -Path $windowsPath -ChildPath 'ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Crypto\Keys'

                    # CNG network service private
                    Join-Path -Path $windowsPath -ChildPath 'ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Crypto\Keys'
                }
            } |
            Where-Object { $_ }

        $accessibleSearchPaths = $searchPaths | Where-Object { Test-Path -Path $_ -ErrorAction Ignore }
    }

    process
    {
        $foundOne = $false
        foreach ($cert in $Certificate)
        {
            $certErrMsg = "Failed to find the path to the ""$($certificate.Subject)"" ($($certificate.Thumbprint)) " +
                          'certificate''s private key because '
            if (-not $cert.HasPrivateKey)
            {
                $msg = "${certErrMsg}it does not have a private key."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            $privateKey = $cert.PrivateKey
            if (-not $privateKey)
            {
                try
                {
                    $privateKey =
                        [Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
                }
                catch
                {
                    $msg = "$($certErrMsg -replace ' because ', ': ') ${_}."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    continue
                }

                if (-not $privateKey)
                {
                    $msg = "${certErrMsg}the current user doesn't have permission to the private key."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    continue
                }
            }

            $fileName = ''
            if ($privateKey | Get-Member -Name 'CspKeyContainerInfo')
            {
                $fileName = $privateKey.CspKeyContainerInfo.UniqueKeyContainerName
            }
            elseif ($privateKey | Get-Member -Name 'Key')
            {
                $fileName = $privateKey.Key.UniqueName
            }

            if (-not $fileName)
            {
                $msg = "${certErrMsg}is of type [$($privateKey.GetType().FullName)], which is not currently " +
                       'supported by Carbon. [Please request support by submitting an issue on the project''s ' +
                       'GitHub issues page.](https://github.com/webmd-health-services/Carbon.Cryptography/issues/new)'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            $foundOne = $false
            $uniqueNameIsPath = $false
            if ($fileName | Split-Path)
            {
                $uniqueNameIsPath = $true
                if ((Test-Path -Path $fileName -PathType Leaf -ErrorAction Ignore))
                {
                    $foundOne = $true
                    $fileName | Write-Output
                }
            }
            else
            {
                foreach ($path in $accessibleSearchPaths)
                {
                    $fullPath = Join-Path -Path $path -ChildPath $fileName
                    if (-not (Test-Path -Path $fullPath -PathType Leaf -ErrorAction Ignore))
                    {
                        continue
                    }
                    $foundOne = $true
                    $fullPath | Write-Output
                }
            }

            if (-not $foundOne)
            {
                if ($uniqueNameIsPath)
                {
                    $msg = "${certErrMsg} its file, ""${fileName}"", doesn't exist."
                }
                else
                {
                    $msg = "${certErrMsg}its file, ""${fileName}"", doesn't exist in any of these " +
                           "directories:" + [Environment]::NewLine +
                           " " + [Environment]::NewLine +
                           "* $($searchPaths -join "$([Environment]::NewLine)* ")"
                }
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }
        }
    }
}