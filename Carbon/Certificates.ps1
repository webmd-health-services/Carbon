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

function Get-Certificate
{
    <#
    .SYNOPSIS
    Gets a certificate from a file on the file system or from a Windows 
    certificate store by thumbprint or friendly name.
    
    .EXAMPLE
    > Get-Certificate -Path C:\Certificates\certificate.cer -Password MySuperSecurePassword
    
    Gets an X509Certificate2 object representing the certificate.cer file.
    
    .EXAMPLE
    > Get-Certificate -Thumbprint a909502dd82ae41433e6f83886b00d4277a32a7b -StoreName My -StoreLocation LocalMachine
    
    Gets an X509Certificate2 object for the certificate in the Personal store 
    with a specific thumbprint under the Local Machine.
    
    .EXAMPLE
    > Get-Certificate -FriendlyName 'Development Certificate' -StoreLocation CurrentUser -StoreName TrustedPeople
    
    Gets the X509Certificate2 whose friendly name is Development Certificate 
    from the Current User's Trusted People certificate store.
    
    .OUTPUTS
    System.Security.Cryptography.x509Certificates.X509Certificate2. The 
    X509Certificate2 certificates that were found, or `$null`.
    #>
    [CmdletBinding(DefaultParameterSetName='ByFriendlyName')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        # The path to the certificate.
        $Path,
        
        [Parameter(ParameterSetName='ByPath')]
        # The password to the certificate.  Can be plaintext or a [SecureString](http://msdn.microsoft.com/en-us/library/system.securestring.aspx).
        $Password,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [string]
        # The certificate's thumbprint.
        $Thumbprint,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyName')]
        [string]
        # The friendly name of the certificate.
        $FriendlyName,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.
        $StoreLocation,
        
        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.
        $StoreName
    )
    
    if( $pscmdlet.ParameterSetName -eq 'ByPath' )
    {
        return New-Object Security.Cryptography.X509Certificates.X509Certificate2 $Path,$Password
    }
    else
    {
        $storeLocationPath = $StoreLocation
        if( -not $StoreLocation )
        {
            $storeLocationPath = '*'
        }
        
        $storeNamePath = $StoreName
        if( -not $StoreName )
        {
            $storeNamePath = '*'
        }
        
        if( $pscmdlet.ParameterSetName -eq 'ByThumbprint' )
        {
            return Get-ChildItem cert:\$storeLocationPath\$storeNamePath\$Thumbprint -ErrorAction SilentlyContinue
        }
        elseif( $pscmdlet.ParameterSetName -eq 'ByFriendlyName' )
        {
            return Get-ChildItem cert:\$storeLocationPath\$storeNamePath\* | Where-Object { $_.FriendlyName -eq $FriendlyName }
        }
        Write-Error "Unknown parameter set '$($pscmdlet.ParameterSetName)'."
    }
}

function Get-CertificateStore
{
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

function Get-SslCertificateBinding
{
    <#
   .SYNOPSIS
   Gets the SSL certificate binding for an IP/port combination.
   
   .DESCRIPTION
   Windows binds SSL certificates to an IP addresses/port combination.  This function gets the binding for a specific IP/port, or $null if one doesn't exist.
   
   .EXAMPLE
   > Get-SslCertificateBinding -IPPort 42.37.80.47:443
   
   Gets the SSL certificate bound to 42.37.80.47, port 443.
   
   .EXAMPLE
   > Get-SslCertificateBinding -IPPort 0.0.0.0:443
   
   Gets the default SSL certificate bound to ALL the computer's IP addresses on port 443.  The object returns will have the following properties:

     * IPPort - the IP address/port the SSL certificate is bound to
     * ApplicationID - the user-generated GUID representing the application using the SSL certificate
     * CertificateHash - the certificate's thumbprint
   
   #>
   [CmdletBinding()]
   param(
        [Parameter(Mandatory=$true)]
        [string]
        # The IP address and port to bind the SSL certificate to.  Should be in the form IP:port.
        # Use 0.0.0.0 for all IP addresses.  For example formats, run
        # 
        #    >  netsh http delete sslcert /?
        $IPPort
   )
   
   Get-SslCertificateBindings | Where-Object { $_.IPPort -eq $IPPort }
}

function Get-SslCertificateBindings
{
    <#
    .SYNOPSIS
    Gets all the SSL certificate bindings on this computer.
    
    .DESCRIPTION
    Parses the output of
       
        > netsh http show sslcert
       
    and returns an object for each binding with the following properties:
    
     * IPPort - the IP address/port the SSL certificate is bound to
     * ApplicationID - the user-generated GUID representing the application using the SSL certificate
     * CertificateHash - the certificate's thumbprint

    .EXAMPLE
    > Get-SslCertificateBindings 
    
    #>
    [CmdletBinding()]
    param(
    )
    
    $binding = $null
    netsh http show sslcert | Where-Object { $_ -match '^    ' } | ForEach-Object {
        if( $_ -notmatch '^    (.*)\s+: (.*)$' )
        {
            Write-Error "Unable to parse line '$_' from netsh output."
            continue
        }
        
        $name = $matches[1].Trim()
        $name = $name -replace ' ',''
        if( $name -eq 'IP:port' )
        {
            $name = "IPPort"
            if( $binding )
            {
                New-Object PsObject -Property $binding
            }
            $binding = @{ }
        }
        $value = $matches[2].Trim()
        if( $value -eq '(null)' )
        {
            $value = $null
        }
        
        if( $name -eq 'ApplicationID' )
        {
            $value = [Guid]$value
        }
        
        $binding[$name] = $value
    }
    
    if( $binding )
    {
        New-Object PsObject -Property $binding
    }
}


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
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the certificate file.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.  To see a list of acceptable values, run:
        #
        #   > [Enum]::GetValues([Security.Cryptography.X509Certificates.StoreLocation])
        $StoreLocation,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.  To see a list of acceptable values run:
        #
        #  > [Enum]::GetValues([Security.Cryptography.X509Certificates.StoreName])
        $StoreName,
        
        [Switch]
        # Mark the private key as exportable.
        $Exportable,
        
        [Parameter()]
        # The password for the certificate.  Can be a string or a System.Security.SecureString.
        $Password
    )
    
    $cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2
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
    
    $cert.Import( $Path, $Password, $keyFlags )
    
    $store = Get-CertificateStore -StoreLocation $StoreLocation -StoreName $StoreName
    $store.Add( $cert )
    $store.Close()
    return $cert
}

function Remove-Certificate
{
    <#
    .SYNOPSIS
    Removes a certificate from a store for the user or machine account.
    
    .DESCRIPTION
    Uses .NET's certificates API to remove a certificate from a given store for the machine or current user.  Use the thumbprint or friendly name to identify which certificate to remove.  The thumbprint is unique to each certificate.  Friendly names are not guaranteed to be unique.  The user performing the removal must have permission on the store where the certificate is located.

    .EXAMPLE
    > Remove-Certificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation CurrentUser -StoreName My
    
    Removes the 570895470234023dsaaefdbcgbefa certificate from the current user's Personal certificate store.
    
    .EXAMPLE
    > $cert = Get-Certificate -FriendlyName 'Carbon Testing Certificate' -StoreLocation LocalMachine -StoreName Root
    > Remove-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName Root
    
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

function Remove-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Removes an SSL certificate binding.
    
    .DESCRIPTION
    Uses the netsh command line application to remove an SSL certificate binding for an IP/port combination.  If the binding doesn't exist, nothing is changed.
    
    .EXAMPLE
    > Remove-SslCertificateBinding -IPPort 45.72.89.57:443
    
    Removes the SSL certificate bound to IP 45.72.89.57 on port 443.
    
    .EXAMPLE
    > Remove-SslCertificateBinding -IPPort 0.0.0.0:443
    
    Removes the default SSL certificate from port 443.  The default certificate is bound to all IP addresses.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The IP address and port to bind the SSL certificate to.  Should be in the form IP:port.
        # Use 0.0.0.0 for all IP addresses.  For example formats, run
        # 
        #    >  netsh http delete sslcert /?
        $IPPort
    )
    
    if( -not (Test-SslCertificateBinding -IPPort $IPPort) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( $IPPort, "removing SSL certificate binding" ) )
    {
        Write-Host "Removing SSL certificate binding for $IPPort."
        netsh http delete sslcert ipport=$IPPort
    }
}

function Set-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Sets an SSL certificate binding for a given IP/port.
    
    .DESCRIPTION
    Uses the netsh command line application to set the certificate for an IP address and port.  If a binding already exists for the IP/port, it is removed, and the new binding is created.  No validation is performed on the thumbprint.
    
    .EXAMPLE
    > Set-SslCertificateBinding -IPPort 43.27.89.54:443 -ApplicationID 88d1f8da-aeb5-40a2-a5e5-0e6107825df7 -Thumbprint 478907345890734590743
    
    Configures the computer to use the 478907345890734590743 certificate on IP 43.27.89.54, port 443.
    
    .EXAMPLE
    
    > Set-SslCertificateBinding -IPPort 0.0.0.0:443 -ApplicationID 88d1f8da-aeb5-40a2-a5e5-0e6107825df7 -Thumbprint 478907345890734590743
    
    Configures the compute to use the 478907345890734590743 certificate as the default certificate on all IP addresses, port 443.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The IP address and port to bind the SSL certificate to.  Should be in the form IP:port.
        # Use 0.0.0.0 to bind to all IP addresses.   For example formats, run
        # 
        #    >  netsh http delete sslcert /?
        $IPPort,
        
        [Parameter(Mandatory=$true)]
        [Guid]
        # A unique ID representing the application using the binding.  Create your own.
        $ApplicationID,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The thumbprint of the certificate to use.  The certificate must be installed.
        $Thumbprint
    )
    
    $commonParams = @{ }
    
    if( $pscmdlet.BoundParameters.WhatIf )
    {
        $commonParams.WhatIf = $true
    }
    
    Remove-SslCertificateBinding -IPPort $IPPort @commonParams
    
    if( $pscmdlet.ShouldProcess( $IPPort, 'creating SSL certificate binding' ) )
    {
        Write-Host "Creating SSL certificate binding for $IPPort with certificate $Thumbprint."
        netsh http add sslcert ipport=$ipPort "certhash=$($Thumbprint)" "appid={$ApplicationID}"
    }
}

function Test-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Tests if an SSL certificate binding exists.
	
	.DESCRIPTION
	SSL certificates are bound to IP addresses and ports.  This function tests if one exists on a given IP/port.
	
	.EXAMPLE
	Test-SslCertificateBinding 0.0.0.0:443
	
	Tests if there is a default SSL certificate bound to all a machine's IP addresses on port 443.
	
	.EXAMPLE
	Test-SslCertificateBinding 10.0.1.1:443
	
	Tests if there is an SSL certificate bound to IP address 10.0.1.1 on port 443.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The IP address and port to bind the SSL certificate to.  Should be in the form IP:port.
        # Use 0.0.0.0 for all IP addresses.  For example formats, run
        # 
        #    >  netsh http delete sslcert /?
        $IPPort
    )
    
    $binding = Get-SslCertificateBinding -IPPort $IPPort
    if( $binding )
    {
        return $True
    }
    else
    {
        return $False
    }
}
