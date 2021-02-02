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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-SslCertificateBinding.when getting all bindings' {
    It 'should match netsh output' {
        $output = netsh http show sslcert 
        $output | 
            ForEach-Object {
            
                if( $_ -notmatch '^    (.*)\s+: (.*)$' )
                {
                    return
                }
                
                Write-Debug -Message $_
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
                    if( $value -notmatch '^(.*):(\d+)$' )
                    {
                        Write-Error ('Invalid IP address/port: {0}' -f $value)
                    }
                    else
                    {
                        $ipAddress = $matches[1]
                        $port = $matches[2]
                        $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
                        $binding.IPAddress | Should -Be ([IPAddress]$ipAddress)
                        $binding.Port | Should -Be $port
                    }
                }
                elseif( $name -eq 'Certificate Hash' )
                {
                    $binding.CertificateHash | Should -Be $value
                }
                elseif( $name -eq 'Application ID' )
                {
                    $binding.ApplicationID | Should -Be ([Guid]$value)
                }
                elseif( $name -eq 'Certificate Store Name' )
                {
                    if( $value -eq '' )
                    {
                        $value = $null
                    }
                    $binding.CertificateStoreName | Should -Be $value
                }
                elseif( $name -eq 'Verify Client Certificate Revocation' )
                {
                    $binding.VerifyClientCertificateRevocation | Should -Be $value
                }
                elseif( $name -eq 'Verify Revocation Using Cached Client Certificate Only' )
                {
                    $binding.VerifyRevocationUsingCachedClientCertificatesOnly | Should -Be $value
                }
                elseif( $name -eq 'Revocation Freshness Time' )
                {
                    $binding.RevocationFreshnessTime | Should -Be $value
                }
                elseif( $name -eq 'URL Retrieval Timeout' )
                {
                    $binding.UrlRetrievalTimeout | Should -Be $value
                }
                elseif( $name -eq 'Ctl Identifier' )
                {
                    $binding.CtlIdentifier | Should -Be $value
                }
                elseif( $name -eq 'Ctl Store Name' )
                {
                    $binding.CtlStoreName | Should -Be $value
                }
                elseif( $name -eq 'DS Mapper Usage' )
                {
                    $binding.DSMapperUsageEnabled | Should -Be $value
                }
                elseif( $name -eq 'Negotiate Client Certificate' )
                {
                    $binding.NegotiateClientCertificate | Should -Be $value
                }
            }
    }
}

Describe 'Get-SslCertificateBinding' {
    
    It 'should get all bindings' {
        $numBindings = netsh http show sslcert |
             Where-Object { $_ -match '^[ \t]+IP:port[ \t]+: (.*)$' } |
             Measure-Object |
             Select-Object -ExpandProperty Count
    
        $bindings = @( Get-SslCertificateBinding )
        $bindings.Length | Should -Be $numBindings
    }
    
    It 'should filter by IP address and port' {
        $foundOne = $false
        $output = netsh http show sslcert 
        $output |
            Where-Object {  $_ -match '^    IP:port\s+: (.*)$' } |
            ForEach-Object {

                if( $foundOne )
                {
                    return
                }
    
                $ipPort = $matches[1].Trim()
                if( $ipPort -notmatch '^(.*):(\d+)$' )
                {
                    Write-Error ('Invalid IP address/port in netsh output: ''{0}''' -f $ipPort )
                    return
                }        
                $ipAddress = $matches[1]
                $port = $matches[2]
                
                $foundOne = $false
                Get-SslCertificateBinding -IPAddress $ipAddress | 
                    ForEach-Object {
                        $_ | Should -Not -BeNullOrEmpty
                        $_.IPAddress | Should -Be ([IPAddress]$ipAddress)
                        $foundOne = $true
                    }
                $foundOne | Should -Be $true
    
                $foundOne = $false                        
                Get-SslCertificateBinding -Port $port |
                    ForEach-Object {
                        $_ | Should -Not -BeNullOrEmpty
                        $_.Port | Should -Be $port.Trim()
                        $foundOne = $true
                    }
                $foundOne | Should -Be $true
            }
    }
    
    It 'should get IPv6 binding' {
        $certPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificate.cer' -Resolve
        $cert = Install-Certificate $certPath -StoreLocation LocalMachine -StoreName My -NoWarn
        $appID = '12ec3276-0689-42b0-ad39-c1fe23d25721'
        Set-SslCertificateBinding -IPAddress '[::]' -Port 443 -ApplicationID $appID -Thumbprint $cert.Thumbprint
    
        try
        {
            $binding = Get-SslCertificateBinding -IPAddress '[::]' | Where-Object { $_.ApplicationID -eq $appID }
            $binding | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Remove-SslCertificateBinding -IPAddress '[::]' -Port 443
        }
    }
    
}
