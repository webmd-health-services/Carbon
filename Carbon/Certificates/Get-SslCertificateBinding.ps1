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
    Gets the SSL certificate bindings on this computer.
   
    .DESCRIPTION
    Windows binds SSL certificates to an IP addresses/port combination.  This function gets all the SSL bindings on this computer, or a binding for a specific IP/port, or $null if one doesn't exist.  The bindings are returned as `Carbon.Certificates.SslCertificateBinding` objects.
    
    .OUTPUTS
    Carbon.Certificates.SslCertificateBinding.

    .EXAMPLE
    > Get-SslCertificateBinding
    
    Gets all the SSL certificate bindings on the local computer.

    .EXAMPLE
    > Get-SslCertificateBinding -IPAddress 42.37.80.47 -Port 443
   
    Gets the SSL certificate bound to 42.37.80.47, port 443.
   
    .EXAMPLE
    > Get-SslCertificateBinding -Port 443
   
    Gets the default SSL certificate bound to ALL the computer's IP addresses on port 443.
    #>
    [CmdletBinding()]
    param(
        [IPAddress]
        # The IP address whose certificate(s) to get.  Should be in the form IP:port. Optional.
        $IPAddress,
        
        [UInt16]
        # The port whose certificate(s) to get. Optional.
        $Port
    )
   
    $binding = $null
    $lineNum = 0

    netsh http show sslcert | 
        ForEach-Object {
        
            $lineNum += 1
            
            if( -not ($_.Trim()) -and $binding )
            {
                $ctorArgs = @(
                                $binding.IPAddress,
                                $binding.Port,
                                $binding['Certificate Hash'],
                                $binding['Application ID'],
                                $binding['Certificate Store Name'],
                                $binding['Verify Client Certificate Revocation'],
                                $binding['Verify Revocation Using Cached Client Certificate Only'],
                                $binding['Usage Check'],
                                $binding['Revocation Freshness Time'],
                                $binding['URL Retrieval Timeout'],
                                $binding['Ctl Identifier'],
                                $binding['Ctl Store Name'],
                                $binding['DS Mapper Usage'],
                                $binding['Negotiate Client Certificate']
                             )
                New-Object Carbon.Certificates.SslCertificateBinding $ctorArgs
                $binding = $null
            }
            
            if( $_ -notmatch '^    (.*)\s+: (.*)$' )
            {
                return
            }

            $name = $matches[1].Trim()
            $value = $matches[2].Trim()

            if( $name -eq 'IP:port' )
            {
                $binding = @{}
                $name = "IPPort"
                if( $value -notmatch '^(.*):(\d+)$' )
                {
                    Write-Error ('Invalid IP address/port in netsh output: {0}.' -f $value)
                }
                else
                {
                    $binding['IPAddress'] = $matches[1]
                    $binding['Port'] = $matches[2]
                }                
            }
            if( $value -eq '(null)' )
            {
                $value = $null
            }
            elseif( $value -eq 'Enabled' )
            {
                $value = $true
            }
            elseif( $value -eq 'Disabled' )
            {
                $value = $false
            }
            
            $binding[$name] = $value
        } | 
    Where-Object {
        if( $IPAddress )
        {
            $_.IPAddress -eq $IPAddress
        }
        else
        {
            return $true
        }
    } |
    Where-Object {
        if( $Port )
        {
            $_.Port -eq $Port
        }
        else
        {
            return $true
        }
    }
    
}

Set-Alias -Name 'Get-SslCertificateBindings' -Value 'Get-SslCertificateBinding'