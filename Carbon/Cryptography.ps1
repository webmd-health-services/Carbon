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

Add-Type -AssemblyName System.Security

filter Protect-String
{
    <#
    .SYNOPSIS
    Encrypts a string using the Data Protection API (DPAPI).
    
    .DESCRIPTION
    Encrypts a string with the Data Protection API (DPAPI).  Encryption can be performed at the user or machine level, so that only the current or user or any
    user on the current machine can decrypt the string.
    
    .EXAMPLE
    Protect-String -String 'TheStringIWantToEncrypt' | Out-File MySecret.txt
    
    Encrypts the given string and saves the encrypted string into MySecret.txt.  Only the user who encrypts the string can unencrypt it.
    
    .EXAMPLE
    
    $cipherText = Protect-String -String "MySuperSecretIdentity" -Scope LocalMachine
    
    Encrypts the given string and stores the value in $cipherText.  Because the encryption scope is set to LocalMachine, any user on the local machine
    can decrypt $cipherText.
    
    .LINK
    Unprotect-String
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        # The text to encrypt.
        $String,
        
        # The scope at which the encryption is performed.
        [Security.Cryptography.DataProtectionScope]
        $Scope = 'CurrentUser'
    )
    
    $bytes = [Text.Encoding]::UTF8.GetBytes( $String )
    $encryptedBytes = [Security.Cryptography.ProtectedData]::Protect( $bytes, $null, $Scope )
    return [Convert]::ToBase64String( $encryptedBytes )
}

filter Unprotect-String
{
    <#
    .SYNOPSIS
    Decrypts a string using the Data Protection API (DPAPI).
    
    .DESCRIPTION
    Decrypts a string with the Data Protection API (DPAPI).  The string must have also been encrypted with the DPAPI.  The same scope must be used to
    decrypt the string as was used to encrypt it.
    
    .EXAMPLE
    PS> $encryptedPassword = Protect-String -String 'MySuperSecretPassword'
    PS> $password = Unprotect-String -ProtectedString  $encryptedPassword
    
    Decrypts a protected string which was encrypted at the current user or default scopes.
    
    .EXAMPLE
    PS> $encryptedPassword = Protect-String -String 'MySuperSecretPassword' -Scope LocalMachine
    PS> $cipherText = Unprotect-String -ProtectedString $encryptedPassword -Scope LocalMachine
    
    Encrypts the given string and stores the value in $cipherText.  Because the string was encrypted at the LocalMachine scope, the string must be 
    decrypted at the same scope.
    
    .EXAMPLE
    Protect-String -String 'NotSoSecretSecret' | Unprotect-String
    
    Demonstrates how Unprotect-String takes input from the pipeline.  Adds 'NotSoSecretSecret' to the pipeline.
    
    
    .LINK
    Protect-String
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        # The text to encrypt.
        $ProtectedString
    )
    
    $encryptedBytes = [Convert]::FromBase64String($ProtectedString)
    $decryptedBytes = [Security.Cryptography.ProtectedData]::Unprotect( $encryptedBytes, $null, 0 )
    [Text.Encoding]::UTF8.GetString( $decryptedBytes )
}
