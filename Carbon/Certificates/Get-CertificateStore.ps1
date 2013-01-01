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

function Get-CertificateStore
{
    <#
    .SYNOPSIS
    Gets an `X509CertificateStore` object for the given location and store name.

    .DESCRIPTION
    Returns an `X509Store` for a given store location and store name.  The store must exist.  Before being retured, it is opened for writing.  If you don't have permission to write to the store, you'll get an error.

    If you just want to read a store, we recommend using PowerShell's `cert:` drive.

    .OUTPUTS
    Security.Cryptography.X509Certificates.X509Store.

    .EXAMPLE
    Get-CertificateStore -StoreLocation LocalMachine -StoreName My

    Get the local computer's Personal certificate store.

    .EXAMPLE
    Get-CertificateStore -StoreLocation CurrentUser -StoreName Root

    Get the current user's Trusted Root Certification Authorities certificate store.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The certificate store location to get.
        $StoreLocation,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreName]
        # The certificate store name to get.
        $StoreName
    )
    $store = New-Object Security.Cryptography.X509Certificates.X509Store $StoreName,$StoreLocation
    $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly -bor [Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )
    return $store
}
