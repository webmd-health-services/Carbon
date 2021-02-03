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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $cert = Install-Certificate (Join-Path $TestDir CarbonTestCertificate.cer -Resolve) -StoreLocation LocalMachine -StoreName My -NoWarn
}

function Stop-Test
{
    Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My -NoWarn
}

function Test-ShouldCreateNewSslCertificateBinding
{
    $appID = '0e8a659e-8034-4ab1-ab82-dcb0f5e90bfd'
    $ipAddress = '74.32.80.43'
    $port = '3847'
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $appID -Thumbprint $cert.Thumbprint
    try
    {
        Assert-Null $binding
        $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
        $ipPort = '{0}:{1}' -f $ipAddress,$port
        Assert-Equal $ipPort $binding.IPPort
        Assert-Equal $appID $binding.ApplicationID
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    }
}

function Test-ShouldReturnBinding
{
    $appID = '0e8a659e-8034-4ab1-ab82-dcb0f5e90bfd'
    $ipAddress = '74.32.80.43'
    $port = '3847'
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $appID -Thumbprint $cert.Thumbprint -PassThru
    $expectedBinding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
    try
    {
        Assert-NotNull $binding
        Assert-Equal $expectedBinding $binding
        $ipPort = '{0}:{1}' -f $ipAddress,$port
        Assert-Equal $ipPort $binding.IPPort
        Assert-Equal $appID $binding.ApplicationID
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    }
}

function Test-ShouldUpdateExistingSslCertificateBinding
{
    $appID = '40f5bb4b-569b-47a8-a0cb-39ed797ce8ea'
    $newAppID = '353364bb-1ca8-4d6c-a596-be7608d57771'
    $ipAddress = '74.38.209.47'
    $port = '8823'
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $appID -Thumbprint $cert.Thumbprint
    Assert-Null $binding
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $newAppID -Thumbprint $cert.Thumbprint
    Assert-Null $binding
    $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
    try
    {
        Assert-Equal $newAppID $binding.ApplicationID
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    }
}

function Test-ShouldSupportShouldProcess
{
    $appID = '411b1023-be42-458e-8fe7-a7ab6c908566'
    $ipAddress = '54.72.38.90'
    $port = '4782'
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $appID -Thumbprint $cert.Thumbprint -WhatIf
    Assert-Null $binding
    try
    {
        Assert-Null (Get-SslCertificateBinding -IPAddress $ipAddress -Port $port)
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    }
}

function Test-ShouldSupportShouldProcessOnBindingUpdate
{
    $appID = '411b1023-be42-458e-8fe7-a7ab6c908566'
    $newAppID = 'db48e0ec-6d8c-4b2c-9486-a2bb33c68b05'
    $ipAddress = '54.237.80.94'
    $port = '7821'
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $appID -Thumbprint $cert.Thumbprint
    Assert-Null $binding
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $newAppID -Thumbprint $cert.Thumbprint -WhatIf
    Assert-Null $binding
    $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
    try
    {
        Assert-Equal $appID $binding.ApplicationID
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    }
}


function Test-ShouldSupportIPv6Address
{
    $appID = '9aa262a9-dfb3-49db-b368-9f15bc12168c'
    $ipAddress = '[::]'
    $port = '7821'
    $binding = Set-SslCertificateBinding -IPAddress $ipAddress -Port $port -ApplicationID $appID -Thumbprint $cert.Thumbprint
    try
    {
        Assert-Null $binding
        $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
        Assert-Equal $appID $binding.ApplicationID
    }
    finally
    {
        Remove-SslCertificateBinding -IPAddress $ipAddress -Port $port
    }    
}
