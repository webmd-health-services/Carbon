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

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

$originalText = $null
$secret = [Guid]::NewGuid().ToString()
$rsaCipherText = $null
$publicKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPublicKey.cer' -Resolve
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve
$publicKey2Path = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPublicKey2.cer' -Resolve
$privateKey2Path = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey2.pfx' -Resolve
$dsaKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestDsaKey.cer' -Resolve

$rsaCipherText = Protect-String -String $secret -PublicKeyPath $privateKeyPath

Describe 'Unprotect-String.RSA' {
    BeforeEach {
        $Global:Error.Clear()
    }
    
    It 'should unprotect string' {
        $originalText = [Guid]::NewGuid().ToString()
        $protectedText = Protect-String -String $originalText -ForUser
        $actualText = Unprotect-String -ProtectedString $protectedText
        $actualText | Should -Be $originalText
    }
    
    
    It 'should unprotect string from machine scope' {
        $secret = Protect-String -String 'Hello World' -ForComputer
        $machine = Unprotect-String -ProtectedString $secret
        $machine | Should -Be 'Hello World'
    }
    
    It 'should unprotect string from user scope' {
        $secret = Protect-String -String 'Hello World' -ForUser
        $machine = Unprotect-String -ProtectedString $secret
        $machine | Should -Be 'Hello World'
    }
    
    
    It 'should unrotect strings in pipeline' {
        $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser | Unprotect-String 
        $secrets[0] | Should -Be 'Foo'
        $secrets[1] | Should -Be 'Fizz'
        $secrets[2] | Should -Be 'Buzz'
        $secrets[3] | Should -Be 'Bar'
    }
    
    It 'should load certificate from file' {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $privateKeyPath
        $Global:Error.Count | Should -Be 0
        $revealedSecret | Should -Be $secret
    }
    
    It 'should handle missing private key' {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $publicKeyPath -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'doesn''t have a private key'
        $revealedSecret | Should -BeNullOrEmpty
    }
    
    # Don't actually know how to generate a non-RSA private key. May not even be possible.
    It 'should handle non rsa key' -Skip {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $dsaKeyPath
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not an RSA key'
        $revealedSecret | Should -BeNullOrEmpty
    }
    
    # This test doesn't work on Windows 2012 R2. Bug fix?
    It 'should handle ciphertext that is too long' -Skip {
        $cert = Get-Certificate -Path $privateKeyPath
        $secret = 'f' * 471
        #Write-Host $secret.Length
        $ciphertext = Protect-String -String $secret -Certificate $cert
        $Global:Error.Count | Should -Be 0
        $ciphertext | Should -Not -BeNullOrEmpty
        (Unprotect-String -ProtectedString $ciphertext -Certificate $cert -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'too long'
    }
    
    It 'should load password protected private key' {
        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKey2Path
        $revealedText = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKey2Path -Password 'fubar'
        $Global:Error.Count | Should -Be 0
        $revealedText | Should -Be $secret
    }
    
    It 'should decrypt with different padding flag' {
        $revealedText = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $privateKeyPath -UseDirectEncryptionPadding -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'padding algorithm'
        $revealedText | Should -BeNullOrEmpty
    }
    
    It 'should handle unencrypted string' {
        $stringBytes = [Text.Encoding]::UTF8.GetBytes( 'fubar' )
        $mySecret = [Convert]::ToBase64String( $stringBytes )
        $result = Unprotect-String -ProtectedString $mySecret -PrivateKeyPath $privateKeyPath -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'different key'
        $result | Should -BeNullOrEmpty
    }
    
    It 'should handle encrypted by different key' {
        $ciphertext = Protect-String -String 'fubar' -PublicKeyPath $publicKey2Path
        $result = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKeyPath -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'isn''t encrypted'
        $result | Should -BeNullOrEmpty
    }
    
    It 'should decrypt with certificate' {
        $cert = Get-Certificate -Path $privateKeyPath
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Certificate $cert
        $Global:Error.Count | Should -Be 0
        $revealedSecret | Should -Be $secret
    }
    
    It 'should decrypt with thumbprint' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
        try
        {
            $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint $cert.Thumbprint
            $Global:Error.Count | Should -Be 0
            $revealedSecret | Should -Be $secret
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
        }
    }
    
    It 'should handle invalid thumbprint' {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint ('1' * 40) -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
        $revealedSecret | Should -BeNullOrEmpty
    }
    
    It 'should handle thumbprint to cert with no private key' {
        $cert = Get-ChildItem -Path 'cert:\*\*' -Recurse | 
                    Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSA] } |
                    Where-Object { -not $_.HasPrivateKey } |
                    Select-Object -First 1
        $cert | Should -Not -BeNullOrEmpty
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint $cert.Thumbprint -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'doesn''t have a private key'
        $revealedSecret | Should -BeNullOrEmpty
    }
    
    It 'should decrypt with path to cert in store' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
        try
        {
            $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath ('cert:\CurrentUser\My\{0}' -f $cert.Thumbprint)
            $Global:Error.Count | Should -Be 0
            $revealedSecret | Should -Be $secret
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
        }
    }
    
    It 'should handle path not found' {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath 'C:\fubar.cer' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
        $revealedSecret | Should -BeNullOrEmpty
    }
    
    It 'should convert to secure string' {
        $originalText = [Guid]::NewGuid().ToString()
        $protectedText = Protect-String -String $originalText -ForUser
        [securestring]$secureSecret = Unprotect-String -ProtectedString $protectedText -AsSecureString 
        $secureSecret | Should -BeOfType ([securestring])
        (Convert-SecureStringToString -SecureString $secureSecret) | Should -Be $originalText
        $secureSecret.IsReadOnly() | Should -Be $true
    }
}

Describe 'Unprotect-String.AES' {
    It 'should fail on invalid key length' {
        $key = 'a' * 8 
        { Protect-CString -String 'text' -Key $key -ErrorAction Stop } |
            Should -Throw 'requires a 128-bit, 192-bit, or 256-bit key (16, 24, or 32 bytes, respectively).'
    }

    foreach ($keyLength in @(16, 24, 32))
    {
        It "should succeed with key length: $($keyLength)" {
            $key = 'a' * $keyLength
            $originalText = [Guid]::NewGuid().ToString()
            $protectedText = Protect-CString -String $originalText -Key $key
            $actualText = Unprotect-CString -ProtectedString $protectedText -Key $key
            $actualText | Should -Be $originalText -Because 'the decrypted string should be unchanged'
            $actualText.Length | Should -Be $originalText.Length -Because 'the decrypted string should not contain any extra bytes'
        }
    }
}
