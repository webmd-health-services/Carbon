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
