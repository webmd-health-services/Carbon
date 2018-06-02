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

$publicKeyFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPublicKey.cer' -Resolve
$privateKeyFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve
$dsaKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestDsaKey.cer' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$credential = $null

Describe 'Protect-String' {

    BeforeAll {
        $password = 'Tt6QML1lmDrFSf'
        $credential = New-Credential 'CarbonTestUser' -Password $password
        Install-User -Credential $credential -Description 'Carbon test user.'    
    }

    BeforeEach {
        $Global:Error.Clear()
    }
        
    function Assert-IsBase64EncodedString($String)
    {
        $String | Should Not BeNullOrEmpty 'Didn''t encrypt cipher text.'
        { [Convert]::FromBase64String( $String ) } | Should Not Throw
    }
    
    It 'should protect string' {
        $cipherText = Protect-String -String 'Hello World!' -ForUser
        Assert-IsBase64EncodedString( $cipherText )
    }
    
    It 'should protect string with scope' {
        $user = Protect-String -String 'Hello World' -ForUser 
        $machine = Protect-String -String 'Hello World' -ForComputer
        $machine | Should Not Be $user 
    }
    
    It 'should protect strings in pipeline' {
        $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser
        $secrets.Length | Should Be 4 'Didn''t encrypt all items in the pipeline.'
        foreach( $secret in $secrets )
        {
            Assert-IsBase64EncodedString $secret
        }
    }
    
    if( -not (Test-Path -Path 'env:CCNetArtifactDirectory') )
    {
        It 'should protect string for credential' {
            # special chars to make sure they get handled correctly
            $string = ' f u b a r '' " > ~!@#$%^&*()_+`-={}|:"<>?[]\;,./'
            $protectedString = Protect-String -String $string -Credential $credential
            $protectedString | Should Not BeNullOrEmpty ('Failed to protect a string as user {0}.' -f $credential.UserName)
    
            $decrypedString = Invoke-PowerShell -FilePath (Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\Unprotect-String.ps1') `
                                                -ArgumentList '-ProtectedString',$protectedString `
                                                -Credential $credential
            $decrypedString | Should Be $string
        }

        It 'should handle spaces in path to Carbon' {
            $tempDir = New-TempDirectory -Prefix 'Carbon Program Files'
            try
            {
                $junctionPath = Join-Path -Path $tempDir -ChildPath 'Carbon'
                Install-Junction -Link $junctionPath -Target (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve)
                try
                {
                    Remove-Module 'Carbon'
                    Import-Module $junctionPath
                    try
                    {
                        $ciphertext = Protect-String -String 'fubar' -Credential $credential
                        $Global:Error.Count | Should Be 0
                        Assert-IsBase64EncodedString $ciphertext
                    }
                    finally
                    {
                        Remove-Module 'Carbon'
                        & (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
                    }
                }
                finally
                {
                    Uninstall-Junction -Path $junctionPath
                }
            }
            finally
            {
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
    }
    else
    {
        Write-Warning ('Can''t test protecting string under another identity: running under CC.Net, and the service user''s profile isn''t loaded, so can''t use Microsoft''s DPAPI.')
    }
    
    It 'should encrypt with certificate' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -Certificate $cert
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath
        (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey) | Should Be $secret
    }
    
    It 'should handle not getting an rsa certificate' {
        $cert = Get-Certificate -Path $dsaKeyPath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -Certificate $cert -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not an RSA key'
        $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should reject strings that are too long for rsa key' {
        $cert = Get-Certificate -Path $privateKeyFilePath
        $secret = 'f' * 470
        $ciphertext = Protect-String -String $secret -Certificate $cert
        $Global:Error.Count | Should Be 0
        $ciphertext | Should Not BeNullOrEmpty
        (Unprotect-String -ProtectedString $ciphertext -Certificate $cert) | Should Be $secret
    
        $secret = 'f' * 472
        $ciphertext = Protect-String -String $secret -Certificate $cert -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'String is longer'
        $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should encrypt from cert store by thumbprint' {
        $cert = Get-ChildItem -Path cert:\* -Recurse |
                    Where-Object { $_ | Get-Member 'PublicKey' } |
                    Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                    Select-Object -First 1
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString().Substring(0,20)
        $expectedCipherText = Protect-String -String $secret -Thumbprint $cert.Thumbprint
        $expectedCipherText | Should Not BeNullOrEmpty
    }
    
    It 'should handle thumbprint not in store' {
       $ciphertext = Protect-String -String 'fubar' -Thumbprint '1111111111111111111111111111111111111111' -ErrorAction SilentlyContinue
       $Global:Error.Count | Should BeGreaterThan 0
       $Global:Error[0] | Should Match 'not found'
       $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should encrypt from cert store by cert path' {
        $cert = Get-ChildItem -Path cert:\* -Recurse |
                    Where-Object { $_ | Get-Member 'PublicKey' } |
                    Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                    Select-Object -First 1
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString().Substring(0,20)
        $certPath = Join-Path -Path 'cert:\' -ChildPath (Split-Path -NoQualifier -Path $cert.PSPath)
        $expectedCipherText = Protect-String -String $secret -PublicKeyPath $certPath
        $expectedCipherText | Should Not BeNullOrEmpty
    }
    
    It 'should handle path not found' {
        $ciphertext = Protect-String -String 'fubar' -PublicKeyPath 'cert:\currentuser\fubar' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
        $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should encrypt from certificate file' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath 
        (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey) | Should Be $secret
    }
    
    It 'should encrypt a secure string' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $password = 'waffles'
        $secret = New-Object -TypeName System.Security.SecureString
        $password.ToCharArray() | ForEach-Object { $secret.AppendChar($_) }

        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath 
        $decryptedPassword = Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey
        $decryptedPassword | Should Be $password
        $passwordBytes = [Text.Encoding]::UTF8.GetBytes($password)
        $decryptedBytes = [Text.Encoding]::UTF8.GetBytes($decryptedPassword)
        $decryptedBytes.Length | Should Be $passwordBytes.Length
        for( $idx = 0; $idx -lt $passwordBytes.Length; ++$idx )
        {
            $passwordBytes[$idx] | Should Be $decryptedPassword[$idx]
        }
    }

    It 'should convert passed objects to string' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $input = New-Object -TypeName Carbon.Security.SecureStringConverter
        $cipherText = Protect-String -String $input -PublicKeyPath $publicKeyFilePath
        $cipherText | Should Not BeNullOrEmpty
        $cipherText | Should Not Be $input
        $privateKey = Get-Certificate -Path $privateKeyFilePath
        Assert-IsBase64EncodedString( $cipherText )
        (Unprotect-String -ProtectedString $cipherText -Certificate $privateKey) | Should Be $input.ToString()
    }

    It 'should encrypt from certificate file with relative path' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -PublicKeyPath (Resolve-Path -Path $publicKeyFilePath -Relative)
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath
        (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey) | Should Be $secret
    }
    
    It 'should use direct encryption padding switch' {
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath -UseDirectEncryptionPadding
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $revealedSecret = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKeyFilePath -UseDirectEncryptionPadding
        $revealedSecret | Should Be $secret
    }

}

foreach( $keySize in @( 128, 192, 256 ) )
{
    Describe ('Protect-String when given a {0}-bit key' -f $keySize) {
        $Global:Error.Clear()
        # Generate a secret that is too long for asymmetric encryption
        $secret = [Guid]::NewGuid().ToString() * 20
        $guid = [Guid]::NewGuid()
        $passphrase = $guid.ToString().Substring(0,($keySize / 8))
        $keyBytes = [Text.Encoding]::UTF8.GetBytes($passphrase)
        $keySecureString = New-Object -TypeName 'Security.SecureString'
        foreach( $char in $passphrase.ToCharArray() )
        {
            $keySecureString.AppendChar($char)
        }

        foreach( $key in @( $passphrase,$keyBytes,$keySecureString) )
        {
            Context ('key as {0}' -f $key.GetType().FullName) {
                $ciphertext = Protect-String -String $secret -Key $key
                It 'should return ciphertext' {
                    $ciphertext | Should Not BeNullOrEmpty
                    ConvertFrom-Base64 -Value $ciphertext | Should Not BeNullOrEmpty
                    $Global:Error.Count | Should Be 0
                }

                It 'should encrypt ciphertext' {
                    $revealedSecret = Unprotect-String -ProtectedString $ciphertext -Key $key
                    $revealedSecret | Should Be $secret
                }
            }
        }
    }
}
