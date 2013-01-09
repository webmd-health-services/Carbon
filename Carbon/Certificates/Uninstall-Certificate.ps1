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

function Uninstall-Certificate
{
    <#
    .SYNOPSIS
    Removes a certificate from a store for the user or machine account.
    
    .DESCRIPTION
    Uses .NET's certificates API to remove a certificate from a given store for the machine or current user.  Use the thumbprint or friendly name to identify which certificate to remove.  The thumbprint is unique to each certificate.  Friendly names are not guaranteed to be unique.  The user performing the removal must have permission on the store where the certificate is located.

    .EXAMPLE
    > Uninstall-Certificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation CurrentUser -StoreName My
    
    Removes the 570895470234023dsaaefdbcgbefa certificate from the current user's Personal certificate store.
    
    .EXAMPLE
    > $cert = Get-Certificate -FriendlyName 'Carbon Testing Certificate' -StoreLocation LocalMachine -StoreName Root
    > Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName Root
    
    Removes the certificate with friendly name 'Carbon Testing Certificate' from the local machine's Trusted Root Certification Authorities store.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [string]
        # The thumbprint of the certificate to remove.
        $Thumbprint,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificate')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        # The certificate to remove
        $Certificate,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.
        $StoreLocation,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.
        $StoreName
    )
    
    if( $pscmdlet.ParameterSetName -eq 'ByThumbprint' )
    {
        $Certificate = Get-Certificate -Thumbprint $Thumbprint -StoreLocation $StoreLocation -StoreName $StoreName
        if( $Certificate -eq $null )
        {
            return
        }
    }
    $store = Get-CertificateStore -StoreLocation $StoreLocation -StoreName $StoreName
    if( $pscmdlet.ShouldProcess(  "certificate $StoreLocation\$StoreName\$($Certificate.Thumbprint) ($($Certificate.FriendlyName))", "remove" ) )
    {
        $store.Remove( $Certificate )
    }
    $store.Close()
}

Set-Alias -Name 'Remove-Certificate' -Value 'Uninstall-Certificate'
