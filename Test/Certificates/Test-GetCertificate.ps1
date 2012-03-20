
$TestCertPath = JOin-Path $TestDir CarbonTestCertificate.cer -Resolve
$TestCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $TestCertPath

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

    if( -not (Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My) ) 
    {
        Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    }
}

function TearDown
{
    Remove-Certificate -Certificate $TestCert -storeLocation CurrentUser -StoreName My
    Remove-Module Carbon
}

function Test-ShouldFindCertificatesByFriendlyName
{
    $cert = Get-Certificate -FriendlyName $TestCert.friendlyName -StoreLocation CurrentUser -StoreName My
    Assert-TestCert $cert
}


function Test-ShouldFindCertificateByPath
{
    $cert = Get-Certificate -Path $TestCertPath
    Assert-TestCert $cert
}

function Test-ShouldFindCertificateByThumbprint
{
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-TestCert $cert
}

function Assert-TestCert($actualCert)
{
    
    Assert-NotNull $actualCert
    Assert-Equal $TestCert.Thumbprint $actualCert.Thumbprint
}
