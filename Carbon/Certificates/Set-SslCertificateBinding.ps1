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

function Set-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Sets an SSL certificate binding for a given IP/port.
    
    .DESCRIPTION
    Uses the netsh command line application to set the certificate for an IP address and port.  If a binding already exists for the IP/port, it is removed, and the new binding is created.  No validation is performed on the thumbprint.
    
    .EXAMPLE
    Set-SslCertificateBinding -IPAddress 43.27.89.54 -Port 443 -ApplicationID 88d1f8da-aeb5-40a2-a5e5-0e6107825df7 -Thumbprint 478907345890734590743
    
    Configures the computer to use the 478907345890734590743 certificate on IP 43.27.89.54, port 443.
    
    .EXAMPLE
    Set-SslCertificateBinding -ApplicationID 88d1f8da-aeb5-40a2-a5e5-0e6107825df7 -Thumbprint 478907345890734590743
    
    Configures the compute to use the 478907345890734590743 certificate as the default certificate on all IP addresses, port 443.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [IPAddress]
        # The IP address for the binding.  Defaults to all IP addresses.
        $IPAddress = '0.0.0.0',
        
        [UInt16]
        # The port for the binding.  Defaults to 443.
        $Port = 443,
        
        [Parameter(Mandatory=$true)]
        [Guid]
        # A unique ID representing the application using the binding.  Create your own.
        $ApplicationID,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The thumbprint of the certificate to use.  The certificate must be installed.
        $Thumbprint
    )

    Set-StrictMode -Version 'Latest'
    
    $commonParams = @{
                        WhatIf = $WhatIfPreference;
                        Verbose = $VerbosePreference;
                        ErrorAction = $ErrorActionPreference;
         }
    
    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    Remove-SslCertificateBinding -IPAddress $IPAddress -Port $Port @commonParams
    
    $action = 'creating SSL certificate binding'
    if( $pscmdlet.ShouldProcess( $IPPort, $action ) )
    {
        $appID = $ApplicationID.ToString('B')
        Invoke-ConsoleCommand -Target $ipPort -Action $action @commonParams -ScriptBlock {
            netsh http add sslcert ipport=$ipPort certhash=$Thumbprint appid=$appID
        }
    }
}
