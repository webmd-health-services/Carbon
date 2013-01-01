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
    Encrypts a string using the Data Protection API (DPAPI).
    
    .DESCRIPTION
    Encrypts a string with the Data Protection API (DPAPI).  Encryption can be performed at the user or computer level.  If encrypted at the User level (with the `ForUser` switch), only the user who encrypted the data can decrypt it.  If encrypted at the computer scope (with the `ForComputer` switch), any user logged onto the computer can decrypt it.
    
    .EXAMPLE
    Protect-String -String 'TheStringIWantToEncrypt' -ForUser | Out-File MySecret.txt
    
    Encrypts the given string and saves the encrypted string into MySecret.txt.  Only the user who encrypts the string can unencrypt it.
    
    .EXAMPLE
    
    $cipherText = Protect-String -String "MySuperSecretIdentity" -ForComputer
    
    Encrypts the given string and stores the value in $cipherText.  Because the encryption scope is set to LocalMachine, any user logged onto the local computer can decrypt $cipherText.
    
    .LINK
    Unprotect-String
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.protecteddata.aspx
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        [string]
        # The text to encrypt.
        $String,
        
        [Parameter(Mandatory=$true,ParameterSetName='CurrentUser')]
        # Encrypts for the current user so that only he can decrypt.
        [Switch]
        $ForUser,
        
        [Parameter(Mandatory=$true,ParameterSetName='LocalMachine')]
        # Encrypts for the current computer so that any user logged into the computer can decrypt.
        [Switch]
        $ForComputer
    )
    
    $bytes = [Text.Encoding]::UTF8.GetBytes( $String )
    $scope = $pscmdlet.ParameterSetName
    $encryptedBytes = [Security.Cryptography.ProtectedData]::Protect( $bytes, $null, $scope )
    return [Convert]::ToBase64String( $encryptedBytes )
}
