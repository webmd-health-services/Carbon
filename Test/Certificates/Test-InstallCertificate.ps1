
$TestCertPath = JOin-Path $TestDir CarbonTestCertificate.cer -Resolve
$TestCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $TestCertPath

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

    if( (Get-Certificate -Thumbprint $TestCert.Thumbprint -SToreLocation CurrentUser -StoreName My) )
    {
        Remove-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    }
}

function TearDown
{
    Remove-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    Remove-Module Carbon
}

function Test-ShouldInstallCertificateToLocalMachine
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    Assert-Equal $TestCert.Thumpbring $cert.Thumpprint
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

function Test-ShouldInstallCertificateToLocalMachineAsExportable
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My -Exportable
    Assert-Equal $TestCert.Thumpbring $cert.Thumpprint
    $cert = Assert-CertificateInstalled -StoreLocation LocalMachine -StoreName My 
    $bytes = $cert.Export( [Security.Cryptography.X509Certificates.X509ContentType]::Pfx )
    Assert-NotNull $bytes
    Assert-NotEqual 0 $bytes.Length
}

function Assert-CertificateInstalled($StoreLocation, $StoreName)
{
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-NotNull $cert
    Assert-Equal $TestCert.Thumbprint $cert.Thumbprint
    return $cert
}