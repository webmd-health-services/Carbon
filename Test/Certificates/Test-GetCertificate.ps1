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
    Uninstall-Certificate -Certificate $TestCert -storeLocation CurrentUser -StoreName My
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
