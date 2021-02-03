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

Describe "Install-Certificate" {

    function Assert-CertificateInstalled
    {
        param(
            $StoreLocation = 'CurrentUser', 
            $StoreName = 'My',
            $ExpectedCertificate = $TestCert
        )
        $cert = Get-Certificate -Thumbprint $ExpectedCertificate.Thumbprint -StoreLocation $StoreLocation -StoreName $StoreName -NoWarn
        $cert | Should Not BeNullOrEmpty | Out-Null
        $cert.Thumbprint | Should Be $ExpectedCertificate.Thumbprint | Out-Null
        return $cert
    }

    BeforeEach {
        $Global:Error.Clear()

        if( (Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My -NoWarn) )
        {
            Uninstall-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My -NoWarn
        }

        if( (Get-Certificate -Thumbprint $TestCertProtected.Thumbprint -StoreLocation CurrentUser -StoreName My -NoWarn) )
        {
            Uninstall-Certificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My -NoWarn
        }
    }

    AfterEach {
        Uninstall-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My -NoWarn
        Uninstall-Certificate -Certificate $TestCert -StoreLocation LocalMachine -StoreName My -NoWarn
        Uninstall-Certificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My -NoWarn
        Uninstall-Certificate -Certificate $TestCertProtected -StoreLocation LocalMachine -StoreName My -NoWarn
    }

    It 'should install certificate to local machine' {
        $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
        $cert.Thumbprint | Should Be $TestCert.Thumbprint
        $cert = Assert-CertificateInstalled -StoreLocation CurrentUser -StoreName My 
        {
            $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
        } | Should Throw
    }

    It 'should install certificate to local machine with relative path' {
        $DebugPreference = 'Continue'
        Push-Location -Path $PSScriptRoot
        try
        {
            $path = '.\Certificates\{0}' -f (Split-Path -Leaf -Path $TestCertPath)
            $cert = Install-Certificate -Path $path -StoreLocation CurrentUser -StoreName My -Verbose -NoWarn
            $cert.Thumbprint | Should Be $TestCert.Thumbprint
            $cert = Assert-CertificateInstalled -StoreLocation CurrentUser -StoreName My 
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should install certificate to local machine as exportable' {
        $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My -Exportable -NoWarn
        $cert.Thumbprint | Should Be $TestCert.Thumbprint
        $cert = Assert-CertificateInstalled -StoreLocation CurrentUser -StoreName My 
        $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
        $bytes | Should Not BeNullOrEmpty
    }

    It 'should install certificate in custom store' {
        $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'SharePoint'  -NoWarn
        $cert | Should Not BeNullOrEmpty
        'cert:\CurrentUser\SharePoint' | Should Exist
        ('cert:\CurrentUser\SharePoint\{0}' -f $cert.Thumbprint) | Should Exist
    }

    It 'should install certificate idempotently' {
        Install-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My -NoWarn
        $Global:Error | Should BeNullOrEmpty
        Install-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My -NoWarn
        $Global:Error | Should BeNullOrEmpty
        Assert-CertificateInstalled CurrentUser My
    }

    It 'should install certificate' {
        $cert = Install-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My -NoWarn
        $cert | Should Not BeNullOrEmpty
        Assert-CertificateInstalled CurrentUser My
    }

    It 'should install password protected certificate' {
        $cert = Install-Certificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My -NoWarn
        $cert | Should Not BeNullOrEmpty
        Assert-CertificateInstalled CurrentUser My $TestCertProtected
    }

    It 'should install certificate in remote computer' -Skip:(Test-Path -Path 'env:APPVEYOR') {
        $session = New-PSSession -ComputerName $env:COMPUTERNAME
        try
        {
            $cert = Install-Certificate -Certificate $TestCert -StoreLocation LocalMachine -StoreName My -Session $session -NoWarn
            $cert | Should Not BeNullOrEmpty
            Assert-CertificateInstalled LocalMachine My
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }
        
    It 'should support ShouldProcess' {
        $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My -WhatIf -NoWarn
        $cert.Thumbprint | Should Be $TestCert.Thumbprint
        Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $TestCert.Thumbprint |
            Should Not Exist
    }
}
