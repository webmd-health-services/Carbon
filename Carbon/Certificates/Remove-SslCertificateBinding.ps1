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

function Remove-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Removes an SSL certificate binding.
    
    .DESCRIPTION
    Uses the netsh command line application to remove an SSL certificate binding for an IP/port combination.  If the binding doesn't exist, nothing is changed.
    
    .EXAMPLE
    > Remove-SslCertificateBinding -IPAddress '45.72.89.57' -Port 443
    
    Removes the SSL certificate bound to IP 45.72.89.57 on port 443.
    
    .EXAMPLE
    > Remove-SslCertificateBinding 
    
    Removes the default SSL certificate from port 443.  The default certificate is bound to all IP addresses.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [IPAddress]
        # The IP address whose binding to remove.  Default is all IP addresses.
        $IPAddress = '0.0.0.0',
        
        [UInt16]
        # The port of the binding to remove.  Default is port 443.
        $Port = 443
    )

    Set-StrictMode -Version 'Latest'

    $commonParams = @{ 
                        Verbose = $VerbosePreference;
                        ErrorAction = $ErrorActionPreference;
                        WhatIf = $WhatIfPreference;
                    }
    
    if( -not (Test-SslCertificateBinding -IPAddress $IPAddress -Port $Port @commonParams) )
    {
        return
    }
    
    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    $action = "removing SSL certificate binding"
    Invoke-ConsoleCommand -Target $ipPort `
                            -Action $action `
                            -ScriptBlock { netsh http delete sslcert ipPort=$ipPort }
}
