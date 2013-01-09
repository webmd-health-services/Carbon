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

function Test-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Tests if an SSL certificate binding exists.
	
	.DESCRIPTION
	SSL certificates are bound to IP addresses and ports.  This function tests if one exists on a given IP address/port.
	
	.EXAMPLE
	Test-SslCertificateBinding -Port 443
	
	Tests if there is a default SSL certificate bound to all a machine's IP addresses on port 443.
	
	.EXAMPLE
	Test-SslCertificateBinding -IPAddress 10.0.1.1 -Port 443
	
	Tests if there is an SSL certificate bound to IP address 10.0.1.1 on port 443.
	
	.EXAMPLE
	Test-SslCertificateBinding
	
	Tests if there are any SSL certificates bound to any IP address/port on the machine.
    #>
    param(
        [IPAddress]
        # The IP address to test for an SSL certificate.
        $IPAddress,
        
        [Uint16]
        # The port to test for an SSL certificate.
        $Port
    )
    
    $getArgs = @{ }
    if( $IPAddress )
    {
        $getArgs.IPAddress = $IPAddress
    }
    
    if( $Port )
    {
        $getArgs.Port = $Port
    }
    
    $binding = Get-SslCertificateBinding @getArgs
    if( $binding )
    {
        return $True
    }
    else
    {
        return $False
    }
}
