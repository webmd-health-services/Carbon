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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$TestCertPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificate.cer' -Resolve
$TestCert = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2' $TestCertPath
$TestCertProtectedPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificateWithPassword.cer' -Resolve
$TestCertProtected = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2' $TestCertProtectedPath,'password'

function Measure-MachineKey
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Security.Cryptography.X509Certificates.StoreLocation]$Location
    )

    $path = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Crypto\RSA\*\*'
    if( $Location -eq [Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine )
    {
        $path = Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Crypto\RSA\MachineKeys'
    }
    Get-ChildItem -Path $path | Measure-Object | Select-Object -ExpandProperty 'Count'
}

function Reset
{
    Uninstall-CCertificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My -NoWarn
    Uninstall-CCertificate -Certificate $TestCert -StoreLocation LocalMachine -StoreName My -NoWarn
    Uninstall-CCertificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My -NoWarn
    Uninstall-CCertificate -Certificate $TestCertProtected -StoreLocation LocalMachine -StoreName My -NoWarn
}

Describe "Install-Certificate" {

    foreach( $location in @('CurrentUser', 'LocalMachine') )
    {
        Context "for $($location)" {
            function Assert-CertificateInstalled
            {
                param(
                    $StoreLocation = 'CurrentUser', 
                    $StoreName = 'My',
                    $ExpectedCertificate = $TestCert
                )

                $duration = [Diagnostics.Stopwatch]::StartNew()
                $timeout = [TimeSpan]::New(0, 0, 10)
                do
                {
                    $cert = Get-CCertificate -Thumbprint $ExpectedCertificate.Thumbprint `
                                             -StoreLocation $StoreLocation `
                                             -StoreName $StoreName `
                                             -NoWarn
                    if( $cert )
                    {
                        break
                    }

                    Write-Verbose "Couldn't find $($StoreLocation)\$($StoreName)\$($ExpectedCertificate.Thumbprint). Trying again in 100ms." -Verbose
                    Start-Sleep -Milliseconds 100
                }
                while( $duration.Elapsed -lt $timeout )
                $duration.Stop()
                $duration = $null

                $cert | Should -Not -BeNullOrEmpty | Out-Null
                $cert.Thumbprint | Should -Be $ExpectedCertificate.Thumbprint | Out-Null
                if( $cert.HasPrivateKey )
                {
                    $cert.PrivateKey | Should -Not -BeNullOrEmpty
                }
                return $cert
            }

            BeforeEach {
                $Global:Error.Clear()
                Reset
            }

            AfterEach {
                Reset
            }

            It 'should install certificate' {
                $cert = Install-CCertificate -Path $TestCertPath -StoreLocation $location -StoreName My
                $cert.Thumbprint | Should -Be $TestCert.Thumbprint
                $cert = Assert-CertificateInstalled -StoreLocation $location -StoreName My 
                {
                    $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
                } | Should -Throw
            }

            It 'should install certificate with relative path' {
                $DebugPreference = 'Continue'
                Push-Location -Path $PSScriptRoot
                try
                {
                    $path = '.\Certificates\{0}' -f (Split-Path -Leaf -Path $TestCertPath)
                    $cert = Install-CCertificate -Path $path -StoreLocation $location -StoreName My -Verbose -NoWarn
                    $cert.Thumbprint | Should -Be $TestCert.Thumbprint
                    $cert = Assert-CertificateInstalled -StoreLocation $location -StoreName My 
                }
                finally
                {
                    Pop-Location
                }
            }

            It 'should install certificate as exportable' {
                $cert = Install-CCertificate -Path $TestCertPath -StoreLocation $location -StoreName My -Exportable -NoWarn
                $cert.Thumbprint | Should -Be $TestCert.Thumbprint
                $cert = Assert-CertificateInstalled -StoreLocation $location -StoreName My 
                $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
                $bytes | Should -Not -BeNullOrEmpty
            }

            It 'should install certificate in custom store' {
                $cert = Install-CCertificate -Path $TestCertPath -StoreLocation $location -CustomStoreName 'SharePoint'  -NoWarn
                $cert | Should -Not -BeNullOrEmpty
                "cert:\$($location)\SharePoint" | Should -Exist
                "cert:\$($location)\SharePoint\$($cert.Thumbprint)" | Should -Exist
            }

            It 'should install certificate idempotently' {
                $countOfPrivateKeys = Measure-MachineKey $location
                Install-CCertificate -Path $TestCertProtectedPath `
                                    -Password 'password' `
                                    -StoreLocation $location `
                                    -StoreName My `
                                    -NoWarn
                $Global:Error | Should -BeNullOrEmpty
                Install-CCertificate -Path $TestCertProtectedPath `
                                    -Password 'password' `
                                    -StoreLocation $location `
                                    -StoreName My `
                                    -NoWarn
                $Global:Error | Should -BeNullOrEmpty
                Assert-CertificateInstalled $location My $TestCertProtected
                Measure-MachineKey $location | Should -Be ($countOfPrivateKeys + 1)
            }

            It 'should re-install certificate when forced' {
                $countOfPrivateKeys = Measure-MachineKey $location
                Install-CCertificate -Path $TestCertProtectedPath `
                                    -Password 'password' `
                                    -StoreLocation $location `
                                    -StoreName My `
                                    -NoWarn
                $Global:Error | Should -BeNullOrEmpty
                Install-CCertificate -Path $TestCertProtectedPath `
                                    -Password 'password' `
                                    -StoreLocation $location `
                                    -StoreName My `
                                    -NoWarn `
                                    -Force
                $Global:Error | Should -BeNullOrEmpty
                Assert-CertificateInstalled $location My $TestCertProtected
                Measure-MachineKey $location | Should -Be ($countOfPrivateKeys + 2)
            }

            It 'should install certificate' {
                $cert = Install-CCertificate -Certificate $TestCert -StoreLocation $location -StoreName My -NoWarn
                $cert | Should -Not -BeNullOrEmpty
                Assert-CertificateInstalled $location My
            }

            It 'should install password protected certificate' {
                $countOfPrivateKeys = Measure-MachineKey $location
                $cert = Install-CCertificate -Path $TestCertProtectedPath `
                                            -Password 'password' `
                                            -StoreLocation $location `
                                            -StoreName My `
                                            -NoWarn
                $cert | Should -Not -BeNullOrEmpty
                Assert-CertificateInstalled $location My $TestCertProtected
                # Regression: make sure importing the certificate doesn't leave behind an extra file in MachineKeys.
                Measure-MachineKey $location | Should -Be ($countOfPrivateKeys + 1)
            }

            It 'should install certificate in remote computer' -Skip:(Test-Path -Path 'env:APPVEYOR') {
                $session = New-PSSession -ComputerName $env:COMPUTERNAME
                try
                {
                    $cert = Install-CCertificate -Certificate $TestCert -StoreLocation $location -StoreName My -Session $session -NoWarn
                    $cert | Should -Not -BeNullOrEmpty
                    Assert-CertificateInstalled $location My
                }
                finally
                {
                    Remove-PSSession -Session $session
                }
            }
                
            It 'should support ShouldProcess' {
                $cert = Install-CCertificate -Path $TestCertPath -StoreLocation $location -StoreName My -WhatIf -NoWarn
                $cert.Thumbprint | Should -Be $TestCert.Thumbprint
                Join-Path -Path "cert:\$($location)\My" -ChildPath $TestCert.Thumbprint |
                    Should -Not -Exist
            }
        }
    }
}
