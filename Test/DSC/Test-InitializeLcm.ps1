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

if( Test-Path -Path 'env:APPVEYOR' )
{
    Write-Warning -Message 'Can''t test Initialize-Lcm under AppVeyor.'
    return
}

$originalLcm = $null
$tempDir = $null
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\CarbonTestPrivateKey.pfx' -Resolve
$publicKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\CarbonTestPublicKey.cer' -Resolve
$publicKey = $null
$certPath = $null
$userName = $CarbonTestUser.UserName
$password = 'Aa1Bb2Cc3Dd4'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
}

function Stop-TestFixture
{
    Uninstall-Directory -Path $tempDir -Recurse
}

function Start-Test
{
    $originalLcm = Get-DscLocalConfigurationManager
    Uninstall-TestLcmCertificate
}

function Stop-Test
{
    configuration SetPullMode
    {
        Set-StrictMode -Off

        $customData = @{ }
        foreach( $item in $originalLcm.DownloadManagerCustomData )
        {
            $customData[$item.key] = $item.value
        }

        node 'localhost'
        {
            LocalConfigurationManager
            {
                AllowModuleOverwrite = $originalLcm.AllowModuleOverwrite;
                ConfigurationMode = $originalLcm.ConfigurationMode;
                ConfigurationID = $originalLcm.ConfigurationID;
                ConfigurationModeFrequencyMins = $originalLcm.ConfigurationModeFrequencyMins;
                CertificateID = $originalLcm.CertificateID;
                DownloadManagerName = $originalLcm.DownloadManagerName;
                DownloadManagerCustomData = $customData
                RefreshMode = $originalLcm.RefreshMode;
                RefreshFrequencyMins = $originalLcm.RefreshFrequencyMins;
                RebootNodeIfNeeded = $originalLcm.RebootNodeIfNeeded;
            }
        }
    }

    $outputPath = Join-Path -Path $tempDir -ChildPath 'originalLcm'
    & SetPullMode -OutputPath $outputPath
    Set-DscLocalConfigurationManager -Path $outputPath
    Uninstall-TestLcmCertificate
}

function Uninstall-TestLcmCertificate
{
    $script:publicKey = Get-Certificate -Path $publicKeyPath -NoWarn
    Assert-NotNull $publicKey
    $script:certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $publicKey.Thumbprint
    if( (Test-Path -Path $certPath -PathType Leaf) )
    {
        Uninstall-Certificate -Thumbprint $publicKey.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
    }
}

function Test-ShouldConfigurePushMode
{
    $lcm = Get-DscLocalConfigurationManager
    $rebootIfNeeded = -not $lcm.RebootNodeIfNeeded
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $privateKeyPath -RebootIfNeeded
    Assert-NoError
    Assert-NotNull $lcm
    Assert-Equal $lcm.CertificateID $publicKey.Thumbprint
    Assert-True $lcm.RebootNodeIfNeeded
    Assert-Equal 'Push' $lcm.RefreshMode
    Assert-True (Test-Path -Path $certPath -PathType Leaf)
}

function Test-ShouldPreserveCertificateIDWhenCertFileNotGiven
{
    $lcm = Get-DscLocalConfigurationManager
    $rebootIfNeeded = -not $lcm.RebootNodeIfNeeded
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertificateID 'fubar' -CertFile $privateKeyPath -RebootIfNeeded
    Assert-NoError
    Assert-Equal $publicKey.Thumbprint $lcm.CertificateID
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertificateID $publicKey.Thumbprint -RebootIfNeeded
    Assert-Equal $publicKey.Thumbprint $lcm.CertificateID
}

function Test-ShouldValidateCertFilePath
{
    $originalLcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $privateKeyPath
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile 'C:\jdskfjsdflkfjksdlf.pfx' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $lcm
    Assert-Equal $originalLcm.CertificateID (Get-DscLocalConfigurationManager).CertificateID
}

function Test-ShouldHandleFileThatIsNotACertificate
{
    $originalLcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $privateKeyPath
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $PSCommandPath  -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'Failed to create X509Certificate2 object'
    Assert-Null $lcm
    Assert-Equal $originalLcm.CertificateID (Get-DscLocalConfigurationManager).CertificateID
}

function Test-ShouldHandleRelativeCertFilePath
{
    Push-Location -Path $PSScriptRoot
    try
    {
        $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile (Resolve-Path -Path $privateKeyPath -Relative)
        Assert-NoError
        Assert-NotNull $lcm
        Assert-Equal $publicKey.Thumbprint $lcm.CertificateID
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldValidateCertHasPrivateKey
{
    $originalLcm = Get-DscLocalConfigurationManager
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $publicKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'does not have a private key'
    Assert-Null $lcm
    Assert-Equal $originalLcm.CertificateID (Get-DscLocalConfigurationManager).CertificateID
}

function Test-ShouldClearUnprovidedPushValues
{
    # Make sure if no cert file specified, the original is left alone.
    $originalLcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $privateKeyPath -RebootIfNeeded 
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost'
    Assert-NoError
    Assert-NotNull $lcm
    Assert-Null $lcm.CertificateID
    Assert-False $lcm.RebootNodeIfNeeded
}

function Test-ShouldValidateComputerName
{
    $lcm = Initialize-Lcm -Push -ComputerName 'fubar' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found or is unreachable'
    Assert-Null $lcm
}

function Test-ShouldUploadCertificateWithSecureStringAndPlaintextPasswords
{
    $securePrivateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\CarbonTestPrivateKey2.pfx'
    $securePrivateKeyPasswod = 'fubar'
    $securePrivateKeySecurePassword = ConvertTo-SecureString -String $securePrivateKeyPasswod -AsPlainText -Force
    $securePrivateKey = Get-Certificate -Path $securePrivateKeyPath -Password $securePrivateKeyPasswod -NoWarn
    Assert-NotNull $securePrivateKey

    Uninstall-Certificate -Thumbprint $securePrivateKey.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn

    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $securePrivateKeyPath -CertPassword $securePrivateKeyPasswod
    Assert-NoError $lcm
    $secureCertPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $securePrivateKey.Thumbprint
    Assert-True (Test-Path -Path $secureCertPath -PathType Leaf)
    Assert-Equal $securePrivateKey.Thumbprint $lcm.CertificateID

    Uninstall-Certificate -Thumbprint $securePrivateKey.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn

    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $securePrivateKeyPath -CertPassword $securePrivateKeySecurePassword
    Assert-NoError $lcm
    Assert-True (Test-Path -Path $secureCertPath -PathType Leaf)
    Assert-Equal $securePrivateKey.Thumbprint $lcm.CertificateID
}

function Test-ShouldSupportWhatIf
{
    $lcm = Initialize-Lcm -Push -ComputerName 'localhost'

    $lcm = Initialize-Lcm -Push -ComputerName 'localhost' -CertFile $privateKeyPath -WhatIf
    Assert-NotNull $lcm

    Assert-Null $lcm.CertificateID
    Assert-False (Test-Path -Path $certPath -PathType Leaf)
}

function Test-ShouldConfigureFileDownloadManager
{
    $Global:Error.Clear()

    $configID = [Guid]::NewGuid()
    $lcm = Initialize-Lcm -SourcePath $PSScriptRoot `
                          -ConfigurationID $configID `
                          -ComputerName 'localhost' `
                          -AllowModuleOverwrite `
                          -CertFile $privateKeyPath `
                          -ConfigurationMode ApplyOnly `
                          -RebootIfNeeded `
                          -RefreshIntervalMinutes 35 `
                          -ConfigurationFrequency 3 `
                          -LcmCredential $CarbonTestUser `
                          -ErrorAction SilentlyContinue

    if( [Environment]::OSVersion.Version.Major -ge 10 )
    {
        Assert-Error ('can''t configure\b.*\bmanager')
        return
    }

    Assert-NoError 
    Assert-NotNull $lcm
    Assert-Equal $configID $lcm.ConfigurationID
    Assert-True $lcm.AllowModuleOverwrite
    Assert-True $lcm.RebootNodeIfNeeded
    Assert-Equal 'ApplyOnly' $lcm.ConfigurationMode
    Assert-Equal 35 $lcm.RefreshFrequencyMins
    Assert-Equal 105 $lcm.ConfigurationModeFrequencyMins
    Assert-Equal 'DscFileDownloadManager' $lcm.DownloadManagerName
    Assert-Equal $PSScriptRoot $lcm.DownloadManagerCustomData[0].value
    Assert-Equal $username $lcm.Credential.UserName
    Assert-Equal $publicKey.Thumbprint $lcm.CertificateID
    Assert-Equal 'Pull' $lcm.RefreshMode

    $configID = [Guid]::NewGuid().ToString()
    $lcm = Initialize-Lcm -SourcePath $env:TEMP -ConfigurationID $configID -ConfigurationMode ApplyAndMonitor -ComputerName 'localhost'

    Assert-NoError 
    Assert-NotNull $lcm
    Assert-Equal $configID $lcm.ConfigurationID
    Assert-False $lcm.AllowModuleOverwrite
    Assert-False $lcm.RebootNodeIfNeeded
    Assert-Equal 'ApplyAndMonitor' $lcm.ConfigurationMode
    Assert-Equal 30 $lcm.RefreshFrequencyMins
    Assert-Equal 30 $lcm.ConfigurationModeFrequencyMins
    Assert-Equal 'DscFileDownloadManager' $lcm.DownloadManagerName
    Assert-Equal $env:TEMP $lcm.DownloadManagerCustomData[0].value
    Assert-Null $lcm.CertificateID
    Assert-Null $lcm.Credential
    Assert-Equal 'Pull' $lcm.RefreshMode
}


function Test-ShouldConfigureWebDownloadManager
{
    $Global:Error.Clear()

    $configID = [Guid]::NewGuid()
    $lcm = Initialize-Lcm -ServerUrl 'http://localhost:8976' `
                          -AllowUnsecureConnection `
                          -ConfigurationID $configID `
                          -ComputerName 'localhost' `
                          -AllowModuleOverwrite `
                          -CertFile $privateKeyPath `
                          -ConfigurationMode ApplyOnly `
                          -RebootIfNeeded `
                          -RefreshIntervalMinutes 40 `
                          -ConfigurationFrequency 3 `
                          -LcmCredential $CarbonTestUser `
                          -ErrorAction SilentlyContinue

    if( [Environment]::OSVersion.Version.Major -ge 10 )
    {
        Assert-Error ('can''t configure\b.*\bmanager')
        return
    }

    Assert-NoError 
    Assert-NotNull $lcm
    Assert-Equal $configID $lcm.ConfigurationID
    Assert-True $lcm.AllowModuleOverwrite
    Assert-True $lcm.RebootNodeIfNeeded
    Assert-Equal 'ApplyOnly' $lcm.ConfigurationMode
    Assert-Equal 40 $lcm.RefreshFrequencyMins
    Assert-Equal 120 $lcm.ConfigurationModeFrequencyMins
    Assert-Equal 'WebDownloadManager' $lcm.DownloadManagerName
    Assert-Equal 'http://localhost:8976' $lcm.DownloadManagerCustomData[0].value
    Assert-Equal 'True' $lcm.DownloadManagerCustomData[1].value
    Assert-Equal $username $lcm.Credential.UserName
    Assert-Equal $publicKey.Thumbprint $lcm.CertificateID
    Assert-Equal 'Pull' $lcm.RefreshMode

    $configID = [Guid]::NewGuid().ToString()
    $lcm = Initialize-Lcm -ServerUrl 'https://localhost:6798' -ConfigurationID $configID -ConfigurationMode ApplyAndMonitor -ComputerName 'localhost'

    Assert-NoError 
    Assert-NotNull $lcm
    Assert-Equal $configID $lcm.ConfigurationID
    Assert-False $lcm.AllowModuleOverwrite
    Assert-False $lcm.RebootNodeIfNeeded
    Assert-Equal 'ApplyAndMonitor' $lcm.ConfigurationMode
    Assert-Equal 30 $lcm.RefreshFrequencyMins
    Assert-Equal 30 $lcm.ConfigurationModeFrequencyMins
    Assert-Equal 'WebDownloadManager' $lcm.DownloadManagerName
    Assert-Equal 'https://localhost:6798' $lcm.DownloadManagerCustomData[0].value
    Assert-Equal 'False' $lcm.DownloadManagerCustomData[1].value
    Assert-Null $lcm.Credential
    Assert-Null $lcm.CertificateID
    Assert-Equal 'Pull' $lcm.RefreshMode
}

if( [Environment]::OSVersion.Version.Major -lt 10 )
{
    function Test-ShouldClearPullValuesWhenSwitchingToPush
    {
        $configID = [Guid]::NewGuid()
        $lcm = Initialize-Lcm -SourcePath $PSScriptRoot `
                              -ConfigurationID $configID `
                              -ComputerName 'localhost' `
                              -AllowModuleOverwrite `
                              -CertFile $privateKeyPath `
                              -ConfigurationMode ApplyOnly `
                              -RebootIfNeeded `
                              -RefreshIntervalMinutes 45 `
                              -ConfigurationFrequency 3 `
                              -LcmCredential $CarbonTestUser
        Assert-NoError    
        Assert-NotNull $lcm

        $lcm = Initialize-Lcm -Push -ComputerName 'localhost'
        Assert-NoError 
        Assert-NotNull $lcm
        Assert-Null $lcm.ConfigurationID
        Assert-Equal 'False' $lcm.AllowModuleOverwrite
        Assert-Equal 'False' $lcm.RebootNodeIfNeeded
        Assert-Equal 'ApplyAndMonitor' $lcm.ConfigurationMode
        Assert-NotEqual (45 * 3) $lcm.RefreshFrequencyMins
        Assert-NotEqual 45 $lcm.ConfigurationModeFrequencyMins
        Assert-Null $lcm.DownloadManagerName
        Assert-Null $lcm.DownloadManagerCustomData
        Assert-Null $lcm.Credential
        Assert-Null $lcm.CertificateID
        Assert-Equal 'Push' $lcm.RefreshMode
    }
}
