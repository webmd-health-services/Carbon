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
