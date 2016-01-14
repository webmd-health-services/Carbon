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
    The `Uninstall-Certificate` function uses .NET's certificates API to remove a certificate from a given store for the machine or current user. Use the thumbprint to identify which certificate to remove. The thumbprint is unique to each certificate. The user performing the removal must have read and write permission on the store where the certificate is located.

    If the certificate isn't in the store, nothing happens, not even an error.

    To uninstall a certificate from a remote computer, use the `Session`parameter, which was added in Carbon 2.1.0. You can create a new session with the `New-PSSession` cmdlet.

    .EXAMPLE
    > Uninstall-Certificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation CurrentUser -StoreName My
    
    Removes the 570895470234023dsaaefdbcgbefa certificate from the current user's Personal certificate store.
    
    .EXAMPLE
    > $cert = Get-Certificate -FriendlyName 'Carbon Testing Certificate' -StoreLocation LocalMachine -StoreName Root
    > Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName Root
    
    Removes the certificate with friendly name 'Carbon Testing Certificate' from the local machine's Trusted Root Certification Authorities store.

    .EXAMPLE
    Uninstall-Certificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation LocalMachine -StoreName 'SharePoint'

    Demonstrates how to uninstall a certificate from a custom, non-standard store.

    .EXAMPLE
    > Uninstall-Certificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation CurrentUser -StoreName My -Session (New-PSSession -ComputerName remote1,remote2)
    
    Demonstrates how to uninstall a certificate from a remote computer.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndCustomStoreName')]
        [string]
        # The thumbprint of the certificate to remove.
        $Thumbprint,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndCustomStoreName')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        # The certificate to remove
        $Certificate,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.
        $StoreLocation,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndStoreName')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndCustomStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndCustomStoreName')]
        [string]
        # The name of the non-standard, custom store where the certificate should be un-installed.
        $CustomStoreName,

        [Management.Automation.Runspaces.PSSession[]]
        # Use the `Session` parameter to uninstall a certificate on remote computer(s) using PowerShell remoting. Use `New-PSSession` to create a session.
        #
        # This parameter was added in Carbon 2.1.0.
        $Session
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -like 'ByCertificate*' )
    {
        $Thumbprint = $Certificate.Thumbprint
    }
    
    $invokeCommandParameters = @{}
    if( $Session )
    {
        $invokeCommandParameters['Session'] = $Session
    }

    Invoke-Command @invokeCommandParameters -ScriptBlock {
        [CmdletBinding()]
        param(
            [string]
            # The thumbprint of the certificate to remove.
            $Thumbprint,
        
            [Security.Cryptography.X509Certificates.StoreLocation]
            # The location of the certificate's store.
            $StoreLocation,
        
            # The name of the certificate's store.
            $StoreName,

            [string]
            # The name of the non-standard, custom store where the certificate should be un-installed.
            $CustomStoreName
        )

        Set-StrictMode -Version 'Latest'

        if( $CustomStoreName )
        {
            $storeNamePath = $CustomStoreName
        }
        else
        {
            $storeNamePath = $StoreName
            if( $StoreName -eq [Security.Cryptography.X509Certificates.StoreName]::CertificateAuthority )
            {
                $storeNamePath = 'CA'
            }
        }

        $certPath = Join-Path -Path 'Cert:\' -ChildPath $StoreLocation
        $certPath = Join-Path -Path $certPath -ChildPath $storeNamePath
        $certPath = Join-Path -Path $certPath -ChildPath $Thumbprint

        if( -not (Test-Path -Path $certPath -PathType Leaf) )
        {
            Write-Debug -Message ('Certificate {0} not found.' -f $certPath)
            return
        }

        $cert = Get-Item -Path $certPath

        if( $CustomStoreName )
        {
            $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' $CustomStoreName,$StoreLocation
        }
        else
        {
            $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' ([Security.Cryptography.X509Certificates.StoreName]$StoreName),$StoreLocation
        }

        $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )

        try
        {
            $target = $cert.FriendlyName
            if( -not $target )
            {
                $target = $cert.Subject
            }

            if( $PSCmdlet.ShouldProcess( ("certificate {0} ({1})" -f $certPath,$target), "remove" ) )
            {
                $store.Remove( $cert )
            }
        }
        finally
        {
            $store.Close()
        }
    } -ArgumentList $Thumbprint,$StoreLocation,$StoreName,$CustomStoreName
}

Set-Alias -Name 'Remove-Certificate' -Value 'Uninstall-Certificate'

