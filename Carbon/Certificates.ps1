
function Get-Certificate
{
    <#
    .SYNOPSIS
    Finds a certificate.
    .RETURN
    The X509Certificate2 certificates that were found, or $null.
    #>
    [CmdletBinding(DefaultParameterSetName='ByFriendlyName')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        # The path to the certificate.
        $Path,
        
        [Parameter(ParameterSetName='ByPath')]
        [string]
        # The password to the certificate.  Can be plaintext or a SecureString.
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
   Gets an SSL certificate binding.
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
    Gets all the SSL certificate bindings.
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
    .RETURNS
    An X509Certificate2 object representing the newly installed certificate.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the certificate file.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.
        $StoreLocation,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.
        $StoreName,
        
        [Switch]
        # Mark the private key as exportable.
        $Exportable,
        
        [Parameter()]
        [string]
        # The password for the certificate.  Can be a string or a SecureString.
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