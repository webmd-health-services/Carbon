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
    Encrypts a string with the Data Protection API (DPAPI).  Encryption can be performed at the user or computer level.  If encrypted at the User level (with the `ForUser` switch), only the user who encrypted the data (i.e. the user running `Protect-String`) can decrypt it.  If encrypted at the computer scope (with the `ForComputer` switch), any user logged onto the computer can decrypt it.

    You can encrypt a string as a specific user with the `Credential` parameter. Only that user will be able to decrypt it on the computer on which it was encrypted. Useful for situation where you have a service user who needs access to protected secrets.
    
    .EXAMPLE
    Protect-String -String 'TheStringIWantToEncrypt' -ForUser | Out-File MySecret.txt
    
    Encrypts the given string and saves the encrypted string into MySecret.txt.  Only the user who encrypts the string can unencrypt it.
    
    .EXAMPLE
    $cipherText = Protect-String -String "MySuperSecretIdentity" -ForComputer
    
    Encrypts the given string and stores the value in $cipherText.  Because the encryption scope is set to LocalMachine, any user logged onto the local computer can decrypt $cipherText.

    .EXAMPLE
    Protect-String -String 's0000p33333r s33333cr33333t' -Credential (Get-Credential 'builduser')

    Demonstrates how to use `Protect-String` to encrypt a secret as a specific user. This is useful for situation where a secret needs to be encrypted by a user other than the user running `Protect-String`.
    
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
        $ForComputer,

        [Parameter(Mandatory=$true,ParameterSetName='ForUser')]
        [pscredential]
        # Encrypts for a specific user.
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    if( $PSCmdlet.ParameterSetName -eq 'ForUser' ) 
    {
        $outFile = '{0}-{1}-stdout' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
        $outFile = Join-Path -Path $env:TEMP -ChildPath $outFile
        Write-Verbose $outFile
        '' | Set-Content -Path $outFile

        $errFile = '{0}-{1}-stderr' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
        $errFile = Join-Path -Path $env:TEMP -ChildPath $errFile
        Write-Verbose $errFile
        '' | Set-Content -Path $errFile

        try
        {
            $protectStringPath = Join-Path -Path $PSScriptRoot -ChildPath '..\bin\Protect-String.ps1' -Resolve
            $encodedString = Protect-String -String $String -ForComputer
            
            $p = Start-Process -FilePath "powershell.exe" `
                               -ArgumentList $protectStringPath,"-ProtectedString",$encodedString `
                               -Credential $Credential `
                               -RedirectStandardOutput $outFile `
                               -RedirectStandardError $errFile `
                               -Wait `
                               -WindowStyle Hidden `
                               -PassThru

            $p.WaitForExit()

            $stdOut = Get-Content -Path $outFile -Raw
            if( $stdOut )
            {
                Write-Verbose -Message $stdOut
            }

            $stdErr = Get-Content -Path $errFile -Raw
            if( $stdErr )
            {
                Write-Error -Message $stdErr
                return
            }

            if( $p.ExitCode -ne 0 )
            {
                Write-Error -Message ('Unknown error encrypting string as {0}: exit code {1}{2}{3}' -f $Credential.UserName,$p.ExitCode,([Environment]::NewLine),$stdOut)
                return
            }

            if( $stdOut )
            {
                return Get-Content -Path $outFile -TotalCount 1
            }
        }
        finally
        {
            Remove-Item -Path $outFile,$errFile -ErrorAction Ignore
        }
    }
    else
    {
        $scope = $PSCmdlet.ParameterSetName
        $stringBytes = [Text.Encoding]::UTF8.GetBytes( $String )
        $encryptedBytes = [Security.Cryptography.ProtectedData]::Protect( $stringBytes, $null, $scope )
        return [Convert]::ToBase64String( $encryptedBytes )
    }
}
