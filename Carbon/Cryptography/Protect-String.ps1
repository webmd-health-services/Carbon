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

filter Protect-String
{
    <#
    .SYNOPSIS
    Encrypts a string.
    
    .DESCRIPTION
    Strings can be encrypted with the Data Protection API (DPAPI) or RSA.
    
    ##  DPAPI 

    The DPAPI hides the encryptiong/decryption keys from you. As such, anything encrpted with via DPAPI can only be decrypted on the same computer it was encrypted on. Use the `ForUser` switch so that only the user who encrypted can decrypt. Use the `ForComputer` switch so that any user who can log into the computer can decrypt. To encrypt as a specific user on the local computer, pass that user's credentials with the `Credential` parameter. (Note this method doesn't work over PowerShell remoting.)

    ## RSA

    RSA is an assymetric encryption/decryption algorithm, which requires a public/private key pair. The secret is encrypted with the public key, and can only be decrypted with the corresponding private key. The secret being encrypted can't be larger than the RSA key pair's size/length, usually 1024, 2048, or 4096 bits (128, 256, and 512 bytes, respectively).

    You can specify the public key in three ways: 
    
     * with a `System.Security.Cryptography.X509Certificates.X509Certificate2` object, via the `Certificate` parameter
     * with a certificate in one of the Windows certificate stores, passing its unique thumbprint via the `Thumbprint` parameter, or via the `PublicKeyPath` parameter cn be certificat provider path, e.g. it starts with `cert:\`.
     * with a X509 certificate file, via the `PublicKeyPath` parameter
   
    .LINK
    New-RsaKeyPair

    .LINK
    Unprotect-String
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.protecteddata.aspx

    .EXAMPLE
    Protect-String -String 'TheStringIWantToEncrypt' -ForUser | Out-File MySecret.txt
    
    Encrypts the given string and saves the encrypted string into MySecret.txt.  Only the user who encrypts the string can unencrypt it.
    
    .EXAMPLE
    $cipherText = Protect-String -String "MySuperSecretIdentity" -ForComputer
    
    Encrypts the given string and stores the value in $cipherText.  Because the encryption scope is set to LocalMachine, any user logged onto the local computer can decrypt `$cipherText`.

    .EXAMPLE
    Protect-String -String 's0000p33333r s33333cr33333t' -Credential (Get-Credential 'builduser')

    Demonstrates how to use `Protect-String` to encrypt a secret as a specific user. This is useful for situation where a secret needs to be encrypted by a user other than the user running `Protect-String`. Encrypting as a specific user won't work over PowerShell remoting.

    .EXAMPLE
    Protect-String -String 'the secret sauce' -Certificate $myCert

    Demonstrates how to encrypt a secret using RSA with a `System.Security.Cryptography.X509Certificates.X509Certificate2` object. You're responsible for creating/loading it. The `New-RsaKeyPair` function will create a key pair for you, if you've got a Windows SDK installed.

    .EXAMPLE
    Protect-String -String 'the secret sauce' -Thumbprint '44A7C27F3353BC53F82318C14490D7E2500B6D9E'

    Demonstrates how to encrypt a secret using RSA with a certificate in one of the Windows certificate stores. All local machine and user stores are searched.

    .EXAMPLE
    ProtectString -String 'the secret sauce' -PublicKeyPath 'C:\Projects\Security\publickey.cer'

    Demonstrates how to encrypt a secret using RSA with a certificate file. The file must be loadable by the `System.Security.Cryptography.X509Certificates.X509Certificate` class.

    .EXAMPLE
    ProtectString -String 'the secret sauce' -PublicKeyPath 'cert:\LocalMachine\My\44A7C27F3353BC53F82318C14490D7E2500B6D9E'

    Demonstrates how to encrypt a secret using RSA with a certificate in the store, giving its exact path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        [string]
        # The text to encrypt.
        $String,
        
        [Parameter(Mandatory=$true,ParameterSetName='DPAPICurrentUser')]
        # Encrypts for the current user so that only he can decrypt.
        [Switch]
        $ForUser,
        
        [Parameter(Mandatory=$true,ParameterSetName='DPAPILocalMachine')]
        # Encrypts for the current computer so that any user logged into the computer can decrypt.
        [Switch]
        $ForComputer,

        [Parameter(Mandatory=$true,ParameterSetName='DPAPIForUser')]
        [Management.Automation.PSCredential]
        # Encrypts for a specific user.
        $Credential,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByCertificate')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        # The public key to use for encrypting.
        $Certificate,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByThumbprint')]
        [string]
        # The thumbprint of the certificate, found in one of the Windows certificate stores, to use when encrypting. All certificate stores are searched.
        $Thumbprint,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByPath')]
        [string]
        # The path to the public key to use for encrypting. Must be to an `X509Certificate2` object.
        $PublicKeyPath,

        [Parameter(ParameterSetName='RSAByCertificate')]
        [Parameter(ParameterSetName='RSAByThumbprint')]
        [Parameter(ParameterSetName='RSAByPath')]
        [Switch]
        # If true, uses Direct Encryption (PKCS#1 v1.5) padding. Otherwise (the default), uses OAEP (PKCS#1 v2) padding. See [Encrypt](http://msdn.microsoft.com/en-us/library/system.security.cryptography.rsacryptoserviceprovider.encrypt(v=vs.110).aspx) for information.
        $UseDirectEncryptionPadding
    )

    Set-StrictMode -Version 'Latest'

    $stringBytes = [Text.Encoding]::UTF8.GetBytes( $String )

    if( $PSCmdlet.ParameterSetName -like 'DPAPI*' )
    {
        if( $PSCmdlet.ParameterSetName -eq 'DPAPIForUser' ) 
        {
            $outFile = 'Carbon+ProtectString+{0}-stdout' -f ([IO.Path]::GetRandomFileName())
            $outFile = Join-Path -Path $env:TEMP -ChildPath $outFile
            Write-Verbose $outFile
            '' | Set-Content -Path $outFile

            $errFile = 'Carbon+ProtectString+{0}-stderr' -f ([IO.Path]::GetRandomFileName())
            $errFile = Join-Path -Path $env:TEMP -ChildPath $errFile
            Write-Verbose $errFile
            '' | Set-Content -Path $errFile

            try
            {
                $protectStringPath = Join-Path -Path $CarbonBinDir -ChildPath 'Protect-String.ps1' -Resolve
                $encodedString = Protect-String -String $String -ForComputer
            
                Start-Process -FilePath "powershell.exe" `
                              -ArgumentList $protectStringPath,"-ProtectedString",$encodedString `
                              -Credential $Credential `
                              -RedirectStandardOutput $outFile `
                              -RedirectStandardError $errFile 

                do
                {
                    try
                    {
                        $stdOut = [IO.File]::ReadAllText( $outFile )
                        if( $stdOut )
                        {
                            Write-Verbose -Message $stdOut
                        }
                        break
                    }
                    catch
                    {
                        Start-Sleep -Milliseconds 100
                    }
                }
                while( $true )

                do
                {
                    try
                    {
                        $stdErr = [IO.File]::ReadAllText( $errFile )
                        if( $stdErr )
                        {
                            Write-Error -Message $stdErr
                            return
                        }
                        break
                    }
                    catch
                    {
                        Start-Sleep -Milliseconds 100
                    }
                }
                while( $true )

                if( $stdOut )
                {
                    return Get-Content -Path $outFile -TotalCount 1
                }
            }
            finally
            {
                Remove-Item -Path $outFile,$errFile -ErrorAction SilentlyContinue
            }
        }
        else
        {
            $scope = [Security.Cryptography.DataProtectionScope]::CurrentUser
            if( $PSCmdlet.ParameterSetName -eq 'DPAPILocalMachine' )
            {
                $scope = [Security.Cryptography.DataProtectionScope]::LocalMachine
            }

            $encryptedBytes = [Security.Cryptography.ProtectedData]::Protect( $stringBytes, $null, $scope )
        }
    }
    elseif( $PSCmdlet.ParameterSetName -like 'RSA*' )
    {
        if( $PSCmdlet.ParameterSetName -eq 'RSAByThumbprint' )
        {
            $Certificate = Get-ChildItem -Path ('cert:\*\*\{0}' -f $Thumbprint) -Recurse | Select-Object -First 1
            if( -not $Certificate )
            {
                Write-Error ('Certificate with thumbprint ''{0}'' not found.' -f $Thumbprint)
                return
            }
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'RSAByPath' )
        {
            $Certificate = Get-Certificate -Path $PublicKeyPath
            if( -not $Certificate )
            {
                return
            }
        }

        $key = $Certificate.PublicKey.Key
        if( $key -isnot ([Security.Cryptography.RSACryptoServiceProvider]) )
        {
            Write-Error ('Certificate ''{0}'' (''{1}'') is not an RSA key. Found a public key of type ''{2}'', but expected type ''{3}''.' -f $Certificate.Subject,$Certificate.Thumbprint,$key.GetType().FullName,[Security.Cryptography.RSACryptoServiceProvider].FullName)
            return
        }

        try
        {
            $encryptedBytes = $key.Encrypt( $stringBytes, (-not $UseDirectEncryptionPadding) )
        }
        catch
        {
            if( $_.Exception.Message -match 'Bad Length\.' -or $_.Exception.Message -match 'The parameter is incorrect\.')
            {
                [int]$maxLengthGuess = ($key.KeySize - (2 * 160 - 2)) / 8
                Write-Error -Message ('Failed to encrypt. String is longer than maximum length allowed by RSA and your key size, which is {0} bits. We estimate the maximum string size you can encrypt with certificate ''{1}'' ({2}) is {3} bytes. You may still get errors when you attempt to decrypt a string within a few bytes of this estimated maximum.' -f $key.KeySize,$Certificate.Subject,$Certificate.Thumbprint,$maxLengthGuess)
                return
            }
            else
            {
                Write-Error -Exception $_.Exception
                return
            }
        }
    }

    return [Convert]::ToBase64String( $encryptedBytes )
}
