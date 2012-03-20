
$TestCertPath = JOin-Path $TestDir CarbonTestCertificate.cer -Resolve
$TestCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $TestCertPath

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

    if( -not (Test-Path Cert:\CurrentUser\My\$TestCert.Thumbprint -PathType Leaf) )
    {
        Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    }
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldRemoveCertificateByCertificate
{
    Remove-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-Null $cert
}

function Test-ShouldRemoveCertificateByThumbprint
{
    Remove-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-Null $cert
}

function Test-ShouldSupportWhatIf
{
    Remove-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My -WhatIf
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-NotNull $cert
}
