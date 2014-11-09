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

$publicKeyFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey.cer' -Resolve
$privateKeyFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPrivateKey.pfx' -Resolve
$dsaKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestDsaKey.cer' -Resolve

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldProtectString
{
    $cipherText = Protect-String -String 'Hello World!' -ForUser
    Assert-IsBase64EncodedString( $cipherText )
}

function Test-ShouldProtectStringWithScope
{
    $user = Protect-String -String 'Hello World' -ForUser 
    $machine = Protect-String -String 'Hello World' -ForComputer
    Assert-NotEqual $user $machine 'encrypting at different scopes resulted in the same string'
}

function Test-ShouldProtectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser
    Assert-Equal 4 $secrets.Length 'Didn''t encrypt all items in the pipeline.'
    foreach( $secret in $secrets )
    {
        Assert-IsBase64EncodedString $secret
    }
}

if( -not (Test-Path -Path 'env:CCNetArtifactDirectory') )
{
    function Test-ShouldProtectStringForCredential
    {
        $password = 'Tt6QML1lmDrFSf'
        Install-User -Username 'CarbonTestUser' -Password $password -Description 'Carbon test user.'

        $credential = New-Credential 'CarbonTestUser' -Password $password
        # special chars to make sure they get handled correctly
        $string = ' f u b a r '' " > ~!@#$%^&*()_+`-={}|:"<>?[]\;,./'
        $protectedString = Protect-String -String $string -Credential $credential
        if( -not $protectedString )
        {
            Fail ('Failed to protect a string as user {0}.' -f $credential.UserName)
        }

        $tempDir = New-TempDir -Prefix (Split-Path -Leaf -Path $PSScriptRoot)
        $outFile = Join-Path -Path $tempDir -ChildPath 'secret'
        $errFile = Join-Path -Path $tempDir -ChildPath 'errors'
        try
        {
            $p = Start-Process -FilePath "powershell.exe" `
                               -ArgumentList (Join-Path -Path $PSScriptRoot -ChildPath 'Unprotect-String.ps1'),'-ProtectedString',$protectedString `
                               -WindowStyle Hidden `
                               -Credential $credential `
                               -PassThru `
                               -Wait `
                               -RedirectStandardOutput $outFile `
			       -RedirectStandardError $errFile
            $p.WaitForExit()
	    
	        if( (Test-Path -Path $errFile -PathType Leaf) )
	        {
	    	    $err = Get-Content -Path $errFile -Raw
		        if( $err )
		        {
	                    Fail $err
		        }
            }

            $decrypedString = Get-Content -Path $outFile -TotalCount 1
            Assert-Equal $string $decrypedString
        }
        finally
        {
            Remove-Item -Recurse -Path (Split-Path -Parent -Path $outFile) -ErrorAction Ignore
        }
    }
}
else
{
    Write-Warning ('Can''t test protecting string under another identity: running under CC.Net, and the service user''s profile isn''t loaded, so can''t use Microsoft''s DPAPI.')
}

function Test-ShouldEncryptWithCertificate
{
    $cert = Get-Certificate -Path $publicKeyFilePath
    Assert-NotNull $cert
    $secret = [Guid]::NewGuid().ToString()
    $ciphertext = Protect-String -String $secret -Certificate $cert
    Assert-NotNull $ciphertext
    Assert-NotEqual $secret $ciphertext
    $privateKey = Get-Certificate -Path $privateKeyFilePath
    Assert-Equal $secret (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey)
}

function Test-ShouldHandleNotGettingAnRSACertificate
{
    $cert = Get-Certificate -Path $dsaKeyPath
    Assert-NotNull $cert
    $secret = [Guid]::NewGuid().ToString()
    $ciphertext = Protect-String -String $secret -Certificate $cert -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not an RSA key'
    Assert-Null $ciphertext
}

function Test-ShouldRejectStringsThatAreTooLongForRsaKey
{
    $cert = Get-Certificate -Path $privateKeyFilePath
    $secret = 'f' * 470
    $ciphertext = Protect-String -String $secret -Certificate $cert
    Assert-NoError
    Assert-NotNull $ciphertext
    Assert-Equal $secret (Unprotect-String -ProtectedString $ciphertext -Certificate $cert)

    $secret = 'f' * 472
    $ciphertext = Protect-String -String $secret -Certificate $cert -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'String is longer'
    Assert-Null $ciphertext
}

function Test-ShouldEncryptFromCertStoreByThumbprint
{
    $cert = Get-ChildItem -Path cert:\* -Recurse |
                Where-Object { $_ | Get-Member 'PublicKey' } |
                Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                Select-Object -First 1
    Assert-NotNull $cert
    $secret = [Guid]::NewGuid().ToString().Substring(0,20)
    $expectedCipherText = Protect-String -String $secret -Thumbprint $cert.Thumbprint
    Assert-NotNull $expectedCipherText
}

function Test-ShouldHandleThumbprintNotInStore
{
   $ciphertext = Protect-String -String 'fubar' -Thumbprint '1111111111111111111111111111111111111111' -ErrorAction SilentlyContinue
   Assert-Error -Last -Regex 'not found'
   Assert-Null $ciphertext
}

function Test-ShouldEncryptFromCertStoreByCertPath
{
    $cert = Get-ChildItem -Path cert:\* -Recurse |
                Where-Object { $_ | Get-Member 'PublicKey' } |
                Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                Select-Object -First 1
    Assert-NotNull $cert
    $secret = [Guid]::NewGuid().ToString().Substring(0,20)
    $certPath = Join-Path -Path 'cert:\' -ChildPath (Split-Path -NoQualifier -Path $cert.PSPath)
    $expectedCipherText = Protect-String -String $secret -PublicKeyPath $certPath
    Assert-NotNull $expectedCipherText
}

function Test-ShouldHandlePathNotFound
{
    $ciphertext = Protect-String -String 'fubar' -PublicKeyPath 'cert:\currentuser\fubar' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $ciphertext
}

function Test-ShouldEncryptFromCertificateFile
{
    $cert = Get-Certificate -Path $publicKeyFilePath
    Assert-NotNull $cert
    $secret = [Guid]::NewGuid().ToString()
    $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath
    Assert-NotNull $ciphertext
    Assert-NotEqual $secret $ciphertext
    $privateKey = Get-Certificate -Path $privateKeyFilePath
    Assert-Equal $secret (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey)
}

function Test-ShouldEncryptFromCertificateFileWithRelativePath
{
    $cert = Get-Certificate -Path $publicKeyFilePath
    Assert-NotNull $cert
    $secret = [Guid]::NewGuid().ToString()
    $ciphertext = Protect-String -String $secret -PublicKeyPath (Resolve-Path -Path $publicKeyFilePath -Relative)
    Assert-NotNull $ciphertext
    Assert-NotEqual $secret $ciphertext
    $privateKey = Get-Certificate -Path $privateKeyFilePath
    Assert-Equal $secret (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey)
}

function Test-ShouldUseDirectEncryptionPaddingSwitch
{
    $secret = [Guid]::NewGuid().ToString()
    $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath -UseDirectEncryptionPadding
    Assert-NotNull $ciphertext
    Assert-NotEqual $secret $ciphertext
    $revealedSecret = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKeyFilePath -UseDirectEncryptionPadding
    Assert-Equal $secret $revealedSecret
}

function Assert-IsBase64EncodedString($String)
{
    Assert-NotEmpty $String 'Didn''t encrypt cipher text.'
    [Convert]::FromBase64String( $String )
}
