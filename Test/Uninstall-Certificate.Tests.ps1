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

Set-StrictMode -Version 'Latest'

$TestCertPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificate.cer' -Resolve
$TestCert = New-Object Security.Cryptography.X509Certificates.X509Certificate2 $TestCertPath
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

Describe 'Uninstall-Certificate' {

    BeforeEach {
        if( -not (Test-Path Cert:\CurrentUser\My\$TestCert.Thumbprint -PathType Leaf) )
        {
            Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -StoreName My
        }
    }

    It 'should remove certificate by certificate' {
        Uninstall-Certificate -Certificate $TestCert -StoreLocation CurrentUser -StoreName My
        $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
        $cert | Should BeNullOrEmpty
    }

    It 'should remove certificate by thumbprint' {
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
        $cert | Should BeNullOrEmpty
    }

    It 'should support WhatIf' {
        Uninstall-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My -WhatIf
        $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
        $cert | Should Not BeNullOrEmpty
    }

    It 'should uninstall certificate from custom store' {
        $cert = Install-Certificate -Path $TestCertPath -StoreLocation CurrentUser -CustomStoreName 'Carbon'
        $cert | Should Not BeNullOrEmpty
        $certPath = 'Cert:\CurrentUser\Carbon\{0}' -f $cert.Thumbprint
        $certPath | Should Exist
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -CustomStoreName 'Carbon'
        $certPath | Should Not Exist   
    }

    It 'should uninstall certificate from remote computer' -Skip:(Test-Path -Path 'env:APPVEYOR') {
        $Global:Error.Clear()

        $session = New-PSSession -ComputerName $env:COMPUTERNAME
        try
        {
            Uninstall-Certificate -Thumbprint $TestCert.Thumbprint `
                                  -StoreLocation CurrentUser `
                                  -StoreName My `
                                  -Session $session
            $Global:Error.Count | Should Be 0

            $cert = Get-Certificate -Thumbprint $TestCert.Thumbprint -StoreLocation CurrentUser -StoreName My
            $cert | Should BeNullOrEmpty
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }
}

function GivenARemotingSession
{
    $script:session = New-PSSession -ComputerName $env:COMPUTERNAME
}

function GivenAnInstalledCertificate
{
    param(
        $StoreLocation = 'CurrentUser',
        $StoreName = 'My'
    )
    Install-Certificate -Path $TestCertPath -StoreLocation $StoreLocation -StoreName $StoreName
}

function WhenPipedMultipleThumbprints
{
    $TestCert.Thumbprint,$TestCert.Thumbprint | Uninstall-Certificate
}

function WhenUninstallingViaRemoting
{
    try
    {
        $TestCert | Uninstall-Certificate -Session $session
    }
    finally
    {
        $session | Remove-PSSession
    }
}

function WhenUninstallPipedCertificate
{
    $TestCert | Uninstall-Certificate
}

function WhenUninstallingByThumbprint
{
    Uninstall-Certificate -Thumbprint $TestCert.Thumbprint
}

function WhenUninstallPipedThumbprint
{
    $TestCert.Thumbprint | Uninstall-Certificate
}

function ThenCertificateUninstalled
{
    It 'should uninstall the certificate' {
        Join-Path -Path 'cert:\*\*' -ChildPath $TestCert.Thumbprint | Should Not Exist
    }   
}

Describe 'Uninstall-Certificate.when given just the certificate thumbprint' {
    GivenAnInstalledCertificate
    WhenUninstallingByThumbprint
    ThenCertificateUninstalled
}

Describe 'Uninstall-Certificate.when given just the certificate thumbprint and installed in multiple stores' {
    GivenAnInstalledCertificate
    GivenAnInstalledCertificate -StoreLocation 'CurrentUser' -StoreName 'My'
    GivenAnInstalledCertificate -StoreLocation 'LocalMachine' -StoreName 'My'
    GivenAnInstalledCertificate -StoreLocation 'LocalMachine' -StoreName 'Root'
    WhenUninstallingByThumbprint
    ThenCertificateUninstalled
}

Describe 'Uninstall-Certificate.when piped thumbprint' {
    GivenAnInstalledCertificate
    WhenUninstallPipedThumbprint
    ThenCertificateUninstalled
}

Describe 'Uninstall-Certificate.when piped certificate object' {
    GivenAnInstalledCertificate
    WhenUninstallPipedCertificate
    ThenCertificateUninstalled
}

Describe 'Uninstall-Certificate.when piped multiple thumbprints' {
    GivenAnInstalledCertificate
    WhenPipedMultipleThumbprints
    ThenCertificateUninstalled
}
