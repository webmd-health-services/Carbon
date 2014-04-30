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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    if( -not (Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My) ) 
    {
        Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
    }
}

function Stop-Test
{
    Uninstall-Certificate -Certificate $TestCert -storeLocation CurrentUser -StoreName My
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

function Test-ShouldFindCertificateByRelativePath
{
    Push-Location -Path $PSScriptRoot
    try
    {
        $cert = Get-Certificate -Path ('.\{0}' -f (Split-Path -Leaf -Path $TestCertPath))
        Assert-TestCert $cert
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldFindCertificateByThumbprint
{
    $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
    Assert-TestCert $cert
}

function Test-ShouldNotThrowErrorWhenCertificateDoesNotExist
{
    $cert = Get-Certificate -Thumbprint '1234567890abcdef1234567890abcdef12345678' -StoreLocation CurrentUser -StoreName My -ErrorAction SilentlyContinue
    Assert-NoError
    Assert-Null $cert
}

function Test-ShouldFindCertificateInCustomStore
{
    $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'Carbon'
    try
    {
        #$cert = 
    }
    finally
    {
        Uninstall-Certificate -Certificate $cert -StoreLocation CurrentUser -CustomStoreName 'Carbon'
    }
}

function Assert-TestCert($actualCert)
{
    
    Assert-NotNull $actualCert
    Assert-Equal $TestCert.Thumbprint $actualCert.Thumbprint
}
