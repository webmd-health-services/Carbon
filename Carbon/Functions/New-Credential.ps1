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

function New-Credential
{
    <#
    .SYNOPSIS
    Creates a new `PSCredential` object from a given username and password.

    .DESCRIPTION
    `New-Credential` will create a credential for you from a username and password, converting a password stored as a `String` into a `SecureString`.

    PowerShell commands use `PSCredential` objects instead of username/password. Although Microsoft recommends using `Get-Credential` to get credentials, when automating installs, there's usually no one around to answer that prompt, so secrets are often pulled from encrypted stores. 

    Beginning with Carbon 2.0, you can pass a `SecureString` as the value for the `Password` parameter.

    Beginning with Carbon 2.0, you can pipe passwords to `New-Credential`, e.g.

        Read-EncrptedPassword | Unprotect-String | New-Credential -Username 'fubar'

    We do *not* recommend passing plaintext passwords around. Beginning ing with Carbon 2.0, you can use `Unprotect-String` to decrypt secrets securely to `SecureStrings` and then use those secure strings with `New-Credential` to create a credential.

    .LINK
    Protect-String

    .LINK
    Unprotect-String

    .OUTPUTS
    System.Management.Automation.PSCredential.

    .EXAMPLE
    New-Credential -User ENTERPRISE\picard -Password 'earlgrey'

    Creates a new credential object for Captain Picard.

    .EXAMPLE
    Read-EncryptedPassword | Unprotect-String | New-Credential -UserName 'ENTERPRISE\picard'

    Demonstrates how to securely decrypt a secret into a new credential object.
    #>
    [CmdletBinding()]
    [OutputType([Management.Automation.PSCredential])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Alias('User')]
        [string]
        # The username. Beginning with Carbon 2.0, this parameter is optional. Previously, this parameter was required.
        $UserName, 

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The password. Can be a `[string]` or a `[System.Security.SecureString]`.
        $Password
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        if( $Password -is [string] )
        {
            $Password = ConvertTo-SecureString -AsPlainText -Force -String $Password
        }
        elseif( $Password -isnot [securestring] )
        {
            Write-Error ('Value for Password parameter must be a [String] or [System.Security.SecureString]. You passed a [{0}].' -f $Password.GetType())
            return
        }

        return New-Object 'Management.Automation.PsCredential' $UserName,$Password
    }
    
    end
    {
    }
}

