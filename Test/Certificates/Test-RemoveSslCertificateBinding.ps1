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
$ipAddress = '1.2.3.4'
$ipV6Address = '::1234'
$port = '8483'
$ipPort = '{0}:{1}' -f $ipAddress,$port
$ipv6Port = '[{0}]:{1}' -f $ipV6Address,$port
$appID = '454f19a6-3ea8-434c-874f-3a860778e4af'
$ipV6AppID = 'b01fa31e-d255-48df-983e-c5c6dd0ccd03'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $cert = Install-Certificate (Join-Path $TestDir CarbonTestCertificate.cer -Resolve) -StoreLocation LocalMachine -StoreName My -NoWarn
    netsh http add sslcert ipport=$ipPort "certhash=$($cert.Thumbprint)" "appid={$appID}"
    netsh http add sslcert ipport=$ipV6Port "certhash=$($cert.Thumbprint)" "appid={$ipV6AppID}"
}

function Stop-Test
{
    netsh http delete sslcert ipport=$ipPort
    netsh http delete sslcerrt ipport=$ipV6Port

    Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My -NoWarn
}

function Test-ShouldRemoveNonExistentBinding
{
    $bindings = @( Get-SslCertificateBinding )
    Remove-SslCertificateBinding -IPAddress '1.2.3.4' -Port '8332'
    $newBindings = @( Get-SslCertificateBinding )
    Assert-Equal $bindings.Length $newBindings.Length
}

function Test-ShouldNotRemoveCertificateWhatIf
{
    Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port -WhatIf
    Assert-True (Test-SslCertificateBinding -IPAddress $ipAddress -Port $port)
}

function Test-ShouldRemoveBinding
{
    Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    Assert-False (Test-SslCertificateBinding -IPAddress $ipAddress -Port $port)
}

function Test-ShouldRemoveIPv6Binding
{
    Remove-SslCertificateBinding -IPAddress $ipV6Address -Port $port
    Assert-False (Test-SslCertificateBinding -IPAddress $ipV6Address -Port $port)
}
