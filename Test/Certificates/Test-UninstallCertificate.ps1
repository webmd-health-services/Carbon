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

$TestCertPath = JOin-Path $TestDir CarbonTestCertificate.cer -Resolve
$TestCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $TestCertPath

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    if( -not (Test-Path Cert:\CurrentUser\My\$TestCert.Thumbprint -PathType Leaf) )
    {
        Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    }
}

function Test-ShouldRemoveCertificateByCertificate
{
    Uninstall-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-Null $cert
}

function Test-ShouldRemoveCertificateByThumbprint
{
    Uninstall-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    $maxTries = 10
    $tryNum = 0
    do
    {
        $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
        if( -not $cert )
        {
            break
        }
        Start-Sleep -Milliseconds 100
    }
    while( $tryNum++ -lt $maxTries )
    Assert-Null $cert
}

function Test-ShouldSupportWhatIf
{
    Uninstall-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My -WhatIf
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-NotNull $cert
}

function Test-ShouldUninstallCertificateFromCustomStore
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'Carbon'
    Assert-NotNull $cert
    $certPath = 'Cert:\CurrentUser\Carbon\{0}' -f $cert.Thumbprint
    Assert-True (Test-Path -Path $certPath -PathType Leaf)
    Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -CustomStoreName 'Carbon'
}
