
$cert = $null
$ipPort = '1.2.3.4:8483'
$appID = '454f19a6-3ea8-434c-874f-3a860778e4af'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $cert = Install-Certificate (Join-Path $TestDir CarbonTestCertificate.cer -Resolve) -StoreLocation LocalMachine -StoreName My
    netsh http add sslcert ipport=$ipPort "certhash=$($cert.Thumbprint)" "appid={$appID}"
}

function TearDown
{
    netsh http delete sslcert ipport=$ipPort
    Remove-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My
    Remove-Module Carbon
}

function Test-ShouldRemoveNonExistentBinding
{
    $bindings = @( Get-SslCertificateBindings )
    Remove-SslCertificateBinding -IPPort '1.2.3.4:8332'
    $newBindings = @( Get-SslCertificateBindings )
    Assert-Equal $bindings.Length $newBindings.Length
}

function Test-ShouldNotRemoveCertificateWhatIf
{
    Remove-SslCertificateBinding -IPPort $ipPort -WhatIf
    Assert-True (Test-SslCertificateBinding -IPPort $ipPort)
}

function Test-ShouldRemoveBinding
{
    Remove-SslCertificateBinding -IPPort $ipPort 
    Assert-False (Test-SslCertificateBinding -IPPort $ipPort)
}