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

$TestCertPath = JOin-Path -Path $PSScriptRoot -ChildPath 'CarbonTestCertificate.cer' -Resolve
$TestCert = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2' $TestCertPath
$TestCertProtectedPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestCertificateWithPassword.cer' -Resolve
$TestCertProtected = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2' $TestCertProtectedPath,'password'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    if( (Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My) )
    {
        Uninstall-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    }

    if( (Get-Certificate -Thumbprint $TestCertProtected.Thumbprint -StoreLocation CurrentUser -StoreName My) )
    {
        Uninstall-Certificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My
    }
}

function Stop-Test
{
    Uninstall-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    Uninstall-Certificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My
}

function Test-ShouldInstallCertificateToLocalMachine
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    Assert-Equal $TestCert.Thumbprint $cert.Thumbprint
    $cert = Assert-CertificateInstalled -StoreLocation LocalMachine -StoreName My 
    $exportFailed = $false
    try
    {
        $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
    }
    catch
    {
        $exportFailed = $true
    }
    Assert-True $exportFailed
}

function Test-ShouldInstallCertificateToLocalMachineWithRelativePath
{
    Push-Location -Path $PSScriptRoot
    try
    {
        $path = '.\{0}' -f (Split-Path -Leaf -Path $TestCertPath)
        $cert = Install-Certificate -Path $path -StoreLocation CurrentUser -StoreName My
        Assert-Equal $TestCert.Thumbprint $cert.Thumbprint
        $cert = Assert-CertificateInstalled -StoreLocation LocalMachine -StoreName My 
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldInstallCertificateToLocalMachineAsExportable
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My -Exportable
    Assert-Equal $TestCert.Thumbprint $cert.Thumbprint
    $cert = Assert-CertificateInstalled -StoreLocation LocalMachine -StoreName My 
    $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
    Assert-NotNull $bytes
    Assert-NotEqual 0 $bytes.Length
}

function Test-ShouldInstallCertificateInCustomStore
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'SharePoint' 
    Assert-NotNull $cert
    Assert-True (Test-Path -Path 'cert:\CurrentUser\SharePoint' -PathType Container)
    Assert-True (Test-Path -Path ('cert:\CurrentUser\SharePoint\{0}' -f $cert.Thumbprint) -PathType Leaf)
}

function Test-ShouldInstallCertificateIdempotently
{
    Install-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    Assert-NoError
    Install-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    Assert-NoError
    Assert-CertificateInstalled CurrentUser My
}

function Test-ShouldInstallCertificate
{
    $cert = Install-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    Assert-NotNull $cert
    Assert-CertificateInstalled CurrentUser My
}

function Test-ShouldInstallPasswordProtectedCertificate
{
    $cert = Install-Certificate -Certificate $TestCertProtected -StoreLocation CurrentUser -StoreName My
    Assert-NotNull $cert
    Assert-CertificateInstalled CurrentUser My $TestCertProtected
}

function Assert-CertificateInstalled
{
    param(
        $StoreLocation, 
        $StoreName,
        $ExpectedCertificate = $TestCert
    )
    $cert = Get-Certificate -Thumbprint $ExpectedCertificate.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-NotNull $cert
    Assert-Equal $ExpectedCertificate.Thumbprint $cert.Thumbprint
    return $cert
}

