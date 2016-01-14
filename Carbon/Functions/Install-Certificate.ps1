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

function Install-Certificate
{
    <#
    .SYNOPSIS
    Installs a certificate in a given store.
    
    .DESCRIPTION
    Uses the .NET certificates API to add a certificate to a store for the machine or current user.  The user performing the action must have permission to modify the store or the installation will fail.

    To install a certificate on a remote computer, create a remoting session with the `New-PSSession` cmdlet, and pass the session object to this function's `Session` parameter. When installing to a remote computer, the certificate's binary data is converted to a base-64 encoded string and sent to the remote computer, where it is converted back into a certificate. If installing a certificate from a file, the file's bytes are converted to base-64, sent to the remote computer, saved as a temporary file, installed, and the temporary file is removed.

    The ability to install a certificate on a remote computer was added in Carbon 2.1.0.
    
    .OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2. An X509Certificate2 object representing the newly installed certificate.
    
    .EXAMPLE
    > Install-Certificate -Path C:\Users\me\certificate.cer -StoreLocation LocalMachine -StoreName My -Exportable -Password My5up3r53cur3P@55w0rd
    
    Installs the certificate (which is protected by a password) at C:\Users\me\certificate.cer into the local machine's Personal store.  The certificate is marked exportable.
    
    .EXAMPLE
    Install-Certificate -Path C:\Users\me\certificate.cer -StoreLocation LocalMachine -StoreName My -ComputerName remote1,remote2
    
    Demonstrates how to install a certificate from a file on the local computer into the local machine's personal store on two remote cmoputers, remote1 and remote2. Use the `Credential` parameter to connect as a specific principal.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='FromFileInWindowsStore')]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromFileInWindowsStore')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromFileInCustomStore')]
        [string]
        # The path to the certificate file.
        $Path,
        
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromCertificateInWindowsStore')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromCertificateInCustomStore')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        # The certificate to install.
        $Certificate,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.  To see a list of acceptable values, run:
        #
        #   > [Enum]::GetValues([Security.Cryptography.X509Certificates.StoreLocation])
        $StoreLocation,
        
        [Parameter(Mandatory=$true,ParameterSetName='FromFileInWindowsStore')]
        [Parameter(Mandatory=$true,ParameterSetName='FromCertificateInWindowsStore')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.  To see a list of acceptable values run:
        #
        #  > [Enum]::GetValues([Security.Cryptography.X509Certificates.StoreName])
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='FromFileInCustomStore')]
        [Parameter(Mandatory=$true,ParameterSetName='FromCertificateInCustomStore')]
        [string]
        # The name of the non-standard, custom store where the certificate should be installed.
        $CustomStoreName,

        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        [Switch]
        # Mark the private key as exportable. Only valid if loading the certificate from a file.
        $Exportable,
        
        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        # The password for the certificate.  Should be a `System.Security.SecureString`.
        $Password,

        [Management.Automation.Runspaces.PSSession[]]
        # Use the `Session` parameter to install a certificate on remote computer(s) using PowerShell remoting. Use `New-PSSession` to create a session.
        #
        # This parameter was added in Carbon 2.1.0.
        $Session
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Password -and $Password -isnot [securestring] )
    {
        Write-Warning -Message ('You passed a plain text password to `Install-Certificate`. A future version of Carbon will remove support for plain-text passwords. Please pass a `SecureString` instead.')
        $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
    }
    
    if( $PSCmdlet.ParameterSetName -like 'FromFile*' )
    {   
        $Path = Resolve-Path -Path $Path
        if( -not $Path )
        {
            return
        }

        $fileBytes = [IO.File]::ReadAllBytes($Path)
        $encodedCert = [Convert]::ToBase64String( $fileBytes )

        $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet
        if( $StoreLocation -eq [Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser )
        {
            $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet
        }
        $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    
        if( $Exportable )
        {
            $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
        }

        $Certificate = Get-Certificate -Path $Path -Password $Password -KeyStorageFlags $keyFlags
        $fromFile = $true
    }
    else
    {
        $encodedCert = [Convert]::ToBase64String( $Certificate.RawData )
        $keyFlags = 0
        $fromFile = $false
    }

    $invokeCommandArgs = @{ }
    if( $Session )
    {
        $invokeCommandArgs['Session'] = $Session
    }


    Invoke-Command @invokeCommandArgs -ScriptBlock {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The base-64 encoded certificate to install.
            $EncodedCertificate,

            # The password for the certificate.
            [securestring]
            $Password,

            [Parameter(Mandatory=$true)]
            [Security.Cryptography.X509Certificates.StoreLocation]
            $StoreLocation,
        
            $StoreName,

            [string]
            $CustomStoreName,

            [Security.Cryptography.X509Certificates.X509KeyStorageFlags]
            $KeyStorageFlags,

            [bool]
            $WhatIf,

            [Management.Automation.ActionPreference]
            $Verbosity
        )

        Set-StrictMode -Version 'Latest'

        $WhatIfPreference = $WhatIf
        $VerbosePreference = $Verbosity

        $tempDir = 'Carbon+Install-Certificate+{0}' -f [IO.Path]::GetRandomFileName()
        $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
        New-Item -Path $tempDir -ItemType 'Directory' -WhatIf:$false | Out-Null

        try
        {
            $certBytes = [Convert]::FromBase64String( $EncodedCertificate )
            $certFilePath = Join-Path -Path $tempDir -ChildPath ([IO.Path]::GetRandomFileName())
            [IO.File]::WriteAllBytes( $certFilePath, $certBytes )

            $cert = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2'
            $cert.Import( $certFilePath, $Password, $KeyStorageFlags )

            if( $CustomStoreName )
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' $CustomStoreName,$StoreLocation
            }
            else
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store'  ([Security.Cryptography.X509Certificates.StoreName]$StoreName),$StoreLocation
            }

            $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )

            $description = $cert.FriendlyName
            if( -not $description )
            {
                $description = $cert.Subject
            }

            if( $PSCmdlet.ShouldProcess( ('install into {0}''s {1} store' -f $StoreLocation,$StoreName), ('{0} ({1})' -f $description,$cert.Thumbprint) ) )
            {
                Write-Verbose ('Installing certificate ''{0}'' ({1}) into {2}''s {3} store.' -f $description,$cert.Thumbprint,$StoreLocation,$StoreName)
                $store.Add( $cert )
            }
            $store.Close()
        }
        finally
        {
            Remove-Item -Path $tempDir -Recurse -ErrorAction Ignore -WhatIf:$false -Force
        }

    } -ArgumentList $encodedCert,$Password,$StoreLocation,$StoreName,$CustomStoreName,$keyFlags,$WhatIfPreference,$VerbosePreference

    return $Certificate
}

