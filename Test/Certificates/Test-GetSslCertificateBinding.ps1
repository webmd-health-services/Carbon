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

function Setup()
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown()
{
    Remove-Module Carbon
}

function Test-ShouldConvertNetshOutputToSslCertificateBindingObjects
{
    $output = netsh http show sslcert 
    $output | 
        ForEach-Object {
        
            if( $_ -notmatch '^    (.*)\s+: (.*)$' )
            {
                return
            }
            
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            if( $value -eq '(null)' )
            {
                $value = ''
            }
            elseif( $value -eq 'Enabled' )
            {
                $value = $true
            }
            elseif( $value -eq 'Disabled' )
            {
                $value = $false
            }
            
            if( $name -eq 'IP:port' )
            {
                $ipAddress,$port = $value -split ':'
                $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
                Assert-Equal $value $binding.IPPort
                Assert-Equal $ipAddress $binding.IPAddress
                Assert-Equal $port $binding.Port
            }
            elseif( $name -eq 'Certificate Hash' )
            {
                Assert-Equal $value $binding.CertificateHash 
            }
            elseif( $name -eq 'Application ID' )
            {
                Assert-Equal ([Guid]$value) $binding.ApplicationID
            }
            elseif( $name -eq 'Certificate Store Name' )
            {
                if( $value -eq '' )
                {
                    $value = $null
                }
                Assert-Equal $value $binding.CertificateStoreName
            }
            elseif( $name -eq 'Verify Client Certificate Revocation' )
            {
                Assert-Equal $value $binding.VerifyClientCertificateRevocation
            }
            elseif( $name -eq 'Verify Revocation Using Cached Client Certificate Only' )
            {
                Assert-Equal $value $binding.VerifyRevocationUsingCachedClientCertificatesOnly
            }
            elseif( $name -eq 'Usage Check' )
            {
                Assert-Equal $value $binding.UsageCheckEnabled
            }
            elseif( $name -eq 'Revocation Freshness Time' )
            {
                Assert-Equal $value $binding.RevocationFreshnessTime
            }
            elseif( $name -eq 'URL Retrieval Timeout' )
            {
                Assert-Equal $value $binding.UrlRetrievalTimeout
            }
            elseif( $name -eq 'Ctl Identifier' )
            {
                Assert-Equal $value $binding.CtlIdentifier
            }
            elseif( $name -eq 'Ctl Store Name' )
            {
                Assert-Equal $value $binding.CtlStoreName
            }
            elseif( $name -eq 'DS Mapper Usage' )
            {
                Assert-Equal $value $binding.DSMapperUsageEnabled
            }
            elseif( $name -eq 'Negotiate Client Certificate' )
            {
                Assert-Equal $value $binding.NegotiateClientCertificate
            }
            else
            {
                Fail ('Unknown field {0}.' -f $name)
            }
        }
}

function Test-ShouldGetAllBindings
{
    $numBindings = netsh http show sslcert |
         Where-Object { $_ -match '^[ \t]+IP:port[ \t]+: (.*)$' } |
         Measure-Object |
         Select-Object -ExpandProperty Count

    $bindings = @( Get-SslCertificateBinding )
    Assert-Equal $numBindings $bindings.Length
}

function Test-ShouldFilterByIPAddressAndPort
{
    $output = netsh http show sslcert 
    $output |
        Where-Object {  $_ -match '^    IP:port\s+: (.*)$' } |
        ForEach-Object {
        
            $ipAddress,$port = $matches[1] -split ':'
            
            $foundOne = $false
            Get-SslCertificateBinding -IPAddress $ipAddress | 
                ForEach-Object {
                    Assert-NotNull $_
                    Assert-Equal $ipAddress $_.IPAddress
                    $foundOne = $true
                }
            Assert-True $foundOne

            $foundOne = $false                        
            Get-SslCertificateBinding -Port $port |
                ForEach-Object {
                    Assert-NotNull $_
                    Assert-Equal $port.Trim() $_.Port
                    $foundOne = $true
                }
            Assert-True $foundOne
            
        }
}