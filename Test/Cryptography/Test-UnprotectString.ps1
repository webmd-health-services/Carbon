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

$originalText = $null
$protectedText = $null
$secret = [Guid]::NewGuid().ToString()
$rsaCipherText = $null
$publicKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey.cer' -Resolve
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPrivateKey.pfx' -Resolve
$dsaKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestDsaKey.cer' -Resolve

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)

    $rsaCipherText = Protect-String -String $secret -PublicKeyPath $privateKeyPath
}

function Start-Test
{
    $originalText = [Guid]::NewGuid().ToString()
    $protectedText = Protect-String -String $originalText -ForUser
}

function Test-ShouldUnprotectString
{
    $actualText = Unprotect-String -ProtectedString $protectedText
    Assert-Equal $originalText $actualText "String not decrypted."
}


function Test-ShouldUnprotectStringFromMachineScope
{
    $secret = Protect-String -String 'Hello World' -ForComputer
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from local machine scope failed'
}

function Test-ShouldUnprotectStringFromUserScope
{
    $secret = Protect-String -String 'Hello World' -ForUser
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from user scope failed'
}


function Test-ShouldUnrotectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser | Unprotect-String 
    Assert-Equal 'Foo' $secrets[0] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Fizz' $secrets[1] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Buzz' $secrets[2] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Bar' $secrets[3] 'Didn''t decrypt first item in pipeline'
}

function Test-ShouldLoadCertificateFromFile
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $privateKeyPath
    Assert-NoError
    Assert-Equal $secret $revealedSecret
}

function Test-ShouldHandleMissingPrivateKey
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $publicKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'doesn''t have a private key'
    Assert-Null $revealedSecret
}

# Don't actually know how to generate a non-RSA private key. May not even be possible.
function Ignore-ShouldHandleNonRsaKey
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $dsaKeyPath
    Assert-Error -Last -Regex 'not an RSA key'
    Assert-Null $revealedSecret
}

# This test doesn't work on Windows 2012 R2. Bug fix?
function Ignore-ShouldHandleCiphertextThatIsTooLong
{
    $cert = Get-Certificate -Path $privateKeyPath
    $secret = 'f' * 471
    #Write-Host $secret.Length
    $ciphertext = Protect-String -String $secret -Certificate $cert
    Assert-NoError
    Assert-NotNull $ciphertext
    Assert-Null (Unprotect-String -ProtectedString $ciphertext -Certificate $cert -ErrorAction SilentlyContinue)
    Assert-Error -Last -Regex 'too long'
}

function Test-ShouldLoadPasswordProtectedPrivateKey
{
    $keyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey2.cer' -Resolve
    $ciphertext = Protect-String -String $secret -PublicKeyPath $keyPath

    $keyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPrivateKey2.pfx' -Resolve
    $revealedText = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $keyPath -Password 'fubar'
    Assert-NoError 
    Assert-Equal $secret $revealedText
}

function Test-ShouldDecryptWithDifferentPaddingFlag
{
    $revealedText = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $privateKeyPath -UseDirectEncryptionPadding -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'padding algorithm'
    Assert-Null $revealedText
}

function Test-ShouldHandleUnencryptedString
{
    $stringBytes = [Text.Encoding]::UTF8.GetBytes( 'fubar' )
    $mySecret = [Convert]::ToBase64String( $stringBytes )
    $result = Unprotect-String -ProtectedString $mySecret -PrivateKeyPath $privateKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'different key'
    Assert-Null $result
}

function Test-ShouldHandleEncryptedByDifferentKey
{
    $ciphertext = Protect-String -String 'fubar' -PublicKeyPath (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey2.cer' -Resolve)
    $result = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'isn''t encrypted'
    Assert-Null $result
}

function Test-ShouldDecryptWithCertificate
{
    $cert = Get-Certificate -Path $privateKeyPath
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Certificate $cert
    Assert-NoError
    Assert-Equal $secret $revealedSecret
}

function Test-ShouldDecryptWithThumbprint
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
    try
    {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint $cert.Thumbprint
        Assert-NoError
        Assert-Equal $secret $revealedSecret
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
    }
}

function Test-ShouldHandleInvalidThumbprint
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint ('1' * 40) -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $revealedSecret
}

function Test-ShouldHandleThumbprintToCertWithNoPrivateKey
{
    $cert = Get-ChildItem -Path 'cert:\*\*' -Recurse | 
                Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                Where-Object { -not $_.HasPrivateKey } |
                Select-Object -First 1
    Assert-NotNull $cert
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint $cert.Thumbprint -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'doesn''t have a private key'
    Assert-Null $revealedSecret
}

function Test-ShouldDecryptWithPathToCertInStore
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
    try
    {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath ('cert:\CurrentUser\My\{0}' -f $cert.Thumbprint)
        Assert-NoError
        Assert-Equal $secret $revealedSecret
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
    }
}

function Test-ShouldHandlePathNotFound
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath 'C:\fubar.cer' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $revealedSecret
}

function Test-ShouldConvertToSecureString
{
    $secureSecret = Unprotect-String -ProtectedString $protectedText -AsSecureString 
    Assert-Is $secureSecret ([securestring])
    Assert-Equal $originalText (Convert-SecureStringToString -SecureString $secureSecret)
}