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

$TestCertPath = JOin-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificate.cer' -Resolve
$TestCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $TestCertPath
$testCertificateThumbprint = '7D5CE4A8A5EC059B829ED135E9AD8607977691CC'
$testCertFriendlyName = 'Pup Test Certificate'
$testCertCertProviderPath = 'cert:\CurrentUser\My\{0}' -f $testCertificateThumbprint

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-TestCert
{
    param(
        $actualCert
    )
        
    $actualCert | Should Not BeNullOrEmpty
    $actualCert.Thumbprint | Should Be $TestCert.Thumbprint
}

function Init
{
    $Global:Error.Clear()
    if( -not (Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My) ) 
    {
        Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    }
}

Describe 'Get-Certificate.when getting certificate from a file' {
    Init
    $cert = Get-CCertificate -Path $TestCertPath
    It ('should have Path property') {
        $cert.Path | Should -Be $TestCertPath
    }
}

Describe 'Get-Certificate.when getting certificate by path from certificate store' {
    Init
    $cert = Get-CCertificate -Path $testCertCertProviderPath
    It ('should have Path property') {
        $cert.Path | Should -Be $testCertCertProviderPath
    }
}

Describe 'Get-Certificate.when getting certificate by thumbprint' {
    Init
    $cert = Get-CCertificate -Thumbprint $testCertificateThumbprint -StoreLocation CurrentUser -StoreName My
    It ('should have Path property') {
        $cert.Path | Should -Be $testCertCertProviderPath
    }
}

Describe 'Get-Certificate.when getting certificate by friendly name' {
    Init
    $cert = Get-CCertificate -FriendlyName $testCertFriendlyName -StoreLocation CurrentUser -StoreName My
    It ('should have Path property') {
        $cert.Path | Should -Be $testCertCertProviderPath
    }
}

Describe 'Get-Certificate' {
    It 'should find certificates by friendly name' {
        Init
        $cert = Get-Certificate -FriendlyName $TestCert.friendlyName -StoreLocation CurrentUser -StoreName My
        Assert-TestCert $cert
    }
    
    
    It 'should find certificate by path' {
        Init
        $cert = Get-Certificate -Path $TestCertPath
        Assert-TestCert $cert
    }
    
    It 'should find certificate by relative path' {
        Init
        Push-Location -Path $PSScriptRoot
        try
        {
            $cert = Get-Certificate -Path ('.\Certificates\{0}' -f (Split-Path -Leaf -Path $TestCertPath))
            Assert-TestCert $cert
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should find certificate by thumbprint' {
        Init
        $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
        Assert-TestCert $cert
    }
    
    It 'should not throw error when certificate does not exist' {
        Init
        $cert = Get-Certificate -Thumbprint '1234567890abcdef1234567890abcdef12345678' -StoreLocation CurrentUser -StoreName My -ErrorAction SilentlyContinue
        $Global:Error.Count | Should Be 0
        $cert | Should BeNullOrEmpty
    }
    
    It 'should find certificate in custom store by thumbprint' {
        Init
        $expectedCert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'Carbon'
        try
        {
            $cert = Get-Certificate -Thumbprint $expectedCert.Thumbprint -StoreLocation CurrentUser -CustomStoreName 'Carbon'
            $cert | Should Not BeNullOrEmpty
            $cert.Thumbprint | Should Be $expectedCert.Thumbprint
        }
        finally
        {
            Uninstall-Certificate -Certificate $expectedCert -StoreLocation CurrentUser -CustomStoreName 'Carbon'
        }
    }
    
    It 'should find certificate in custom store by friendly name' {
        Init
        $expectedCert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'Carbon'
        try
        {
            $cert = Get-Certificate -FriendlyName $expectedCert.FriendlyName -StoreLocation CurrentUser -CustomStoreName 'Carbon'
            $cert | Should Not BeNullOrEmpty
            $cert.Thumbprint | Should Be $expectedCert.Thumbprint
        }
        finally
        {
            Uninstall-Certificate -Certificate $expectedCert -StoreLocation CurrentUser -CustomStoreName 'Carbon'
        }
    }
    
    It 'should get password protected certificate' {
        Init
        [Security.Cryptography.X509Certificates.X509Certificate2]$cert = Get-Certificate -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificateWithPassword.cer') -Password 'password'
        $Global:Error.Count | Should Be 0
        $cert | Should Not BeNullOrEmpty
        $cert.Thumbprint | Should Be 'DE32D78122C2B5136221DE51B33A2F65A98351D2'
        $cert.FriendlyName | Should Be 'Carbon Test Certificate - Password Protected'
    }
    
    It 'should include exception when failing to load certificate' {
        Init
        $cert = Get-Certificate -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificateWithPassword.cer') -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'password'
        $cert | Should BeNullOrEmpty
        $Error[1].Exception | Should Not BeNullOrEmpty
        $Error[1].Exception | Should BeOfType ([Management.Automation.MethodInvocationException])
    }
    
    It 'should get certificates in CA store' {
        Init
        $foundACert = $false
        dir Cert:\CurrentUser\CA | ForEach-Object {
            $cert = Get-Certificate -Thumbprint $_.Thumbprint -StoreLocation CurrentUser -StoreName CertificateAuthority
            $cert | Should Not BeNullOrEmpty
            $foundACert = $true
        }
    }    
}

Uninstall-Certificate -Certificate $TestCert -storeLocation CurrentUser -StoreName My
