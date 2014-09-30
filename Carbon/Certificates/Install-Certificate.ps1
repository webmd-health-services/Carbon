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

function Install-Certificate
{
    <#
    .SYNOPSIS
    Installs a certificate in a given store.
    
    .DESCRIPTION
    Uses the .NET certificates API to add a certificate to a store for the machine or current user.  The user performing the action must have permission to modify the store or the installation will fail.
    
    .OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2. An X509Certificate2 object representing the newly installed certificate.
    
    .EXAMPLE
    > Install-Certificate -Path C:\Users\me\certificate.cer -StoreLocation LocalMachine -StoreName My -Exportable -Password My5up3r53cur3P@55w0rd
    
    Installs the certificate (which is protected by a password) at C:\Users\me\certificate.cer into the local machine's Personal store.  The certificate is marked exportable.
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

        [Switch]
        # Mark the private key as exportable. Only valid if loading the certificate from a file.
        $Exportable,
        
        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        # The password for the certificate.  Can be a string or a `System.Security.SecureString`.
        $Password
    )
    
    Set-StrictMode -Version 'Latest'

    if( $PSCmdlet.ParameterSetName -like 'FromFile*' )
    {    
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
    }
    
    $getCertificateStoreParams = @{ }
    if( $PSCmdlet.ParameterSetName -like '*InWindowsStore' )
    {
        $getCertificateStoreParams.StoreName = $StoreName
    }
    else
    {
        $getCertificateStoreParams.CustomStoreName = $CustomStoreName
    }
    
    $store = Get-CertificateStore -StoreLocation $StoreLocation @getCertificateStoreParams
    $store.Add( $Certificate )
    $store.Close()
    return $Certificate
}
