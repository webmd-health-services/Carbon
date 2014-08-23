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

function New-RsaKeyPair
{
    <#
    .SYNOPSIS
    Generates a public/private RSA key pair.

    .DESCRIPTION
    Uses the `makecert.exe` and `pvk2pfx.exe` programs to generate a public/private RSA key pair, and saves each to files of your choosing. The public key is saved as an X509Certificate. The private key is saved as a PFX file. Both can be loaded by .NET's `X509Certificate` class. Returns `System.IO.FileInfo` objects for the public and private key, in that order.

    You will be prompted for the private key password. Once when creating the private key, once to save it to a file, and finally to export it to a PFX file. Sorry about that: the `makecert.exe` tool doesn't have an password command-line parameter. The first two prompts will be GUIs, so you can't run this command headless. To create a password-less private key, click "None" when prompted for the private key password, and leave the other password prompts blank.

    `makecert.exe` and `pvk2pfx.exe` are part of the Windows SDK. They can be downloaded from the following locations:

        * [Windows 7](http://www.microsoft.com/en-us/download/details.aspx?id=8279)
        * [Windows 8](http://msdn.microsoft.com/en-us/windows/desktop/hh852363.aspx)
        * [Windows 8.1](http://msdn.microsoft.com/en-us/windows/desktop/bg162891.aspx)

    .OUTPUTS
    System.IO.FileInfo

    .LINK
    http://www.microsoft.com/en-us/download/details.aspx?id=8279

    .LINK
    http://msdn.microsoft.com/en-us/windows/desktop/hh852363.aspx

    .LINK
    http://msdn.microsoft.com/en-us/windows/desktop/bg162891.aspx

    .EXAMPLE
    New-RsaKeyPair -Subject 'CN=MyName' -PublicKeyFile 'MyName.cer' -PrivateKeyFile 'MyName.pfx'

    Demonstrates the minimal parameters needed to generate a key pair. The key will use a sha512 signing algorithm, have a length of 4096 bits, expire on `DateTime::MaxValue`, as an `individual` authority. The public key will be saved in the current directory as `MyName.cer`. The private key will be saved to the current directory as `MyName.pfx`.

    .EXAMPLE
    New-RsaKeyPair -Subject 'CN=MyName' -PublicKeyFile 'MyName.cer' -PrivateKeyFile 'MyName.pfx' -Algorithm 'sha1' -ValidFrom (Get-Date -Year 2015 -Month 1 -Day 1) -ValidTo (Get-Date -Year 2015 -Month 12 -Day 31) -Length 1024 -Authority 'commercial'

    Demonstrates how to use all the parameters to create a truly customized key pair. The generated certificate will use the sha1 signing algorithm, becomes effective 1/1/2015, expires 12/31/2015, is 1024 bits in length, as specifies `commercial` as the signing authority.
    #>
    [OutputType([IO.FileInfo])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The key's subject. Should be of the form `CN=Name,OU=Name,O=SuperMagicFunTime,ST=OR,C=US`. Only the `CN=Name` part is required.
        $Subject,

        [ValidateSet('md5','sha1','sha256','sha384','sha512')]
        [string]
        # The signature algorithm. Default is `sha512`.
        $Algorithm = 'sha512',

        [DateTime]
        # The date/time the keys will become valid. Default is now.
        $ValidFrom = (Get-Date),

        [DateTime]
        # The date/time the keys should expire. Default is `DateTime::MaxValue`.
        $ValidTo = ([DateTime]::MaxValue),

        [int]
        # The length, in bits, of the generated key length. Default is `4096`.
        $Length = 4096,

        [ValidateSet('commercial','individual')]
        [string]
        # The signing authority of the certificate. Must be `commercial` (for certificates used by commercial software publishers) or `individual`, for certificates used by individual software publishers. Default is `individual`.
        $Authority = 'individual',

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        # The file where the public key should be stored. Saved as an X509 certificate.
        $PublicKeyFile,

        [Parameter(Mandatory=$true,Position=2)]
        [string]
        # The file where the private key should be stored. The private key will be saved as an X509 certificate in PFX format and will include the public key.
        $PrivateKeyFile,

        [Switch]
        # Overwrites `PublicKeyFile` and/or `PrivateKeyFile`, if they exist.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    function Find-WindowsSdkCommand
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Name
        )

        Set-StrictMode -Version 'Latest'

        $item = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows' | 
                    Get-ItemProperty -Name 'InstallationFolder' |
                    Select-Object -ExpandProperty 'InstallationFolder' |
                    ForEach-Object { Join-Path -Path $_ -ChildPath ('Bin\{0}' -f $Name) } |
                    Where-Object { Test-Path -Path $_ -PathType Leaf } |
                    Get-Item |
                    Sort-Object -Property { $_.VersionInfo.ProductVersion } -Descending |
                    Select-Object -First 1

        if( -not $item )
        {
            Write-Error ('Command ''{0}'' not found. Please install a Windows SDK.' -f $Name)
            return
        }
        Write-Verbose ('{0} v{1}' -f $item.FullName,$item.VersionInfo.ProductVersion)
     
         $item   
    }

    function Resolve-KeyPath
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Path
        )

        Set-StrictMode -Version 'Latest'

        $Path = Resolve-FullPath -Path $Path

        if( (Test-Path -Path $Path -PathType Leaf) )
        {
            if( -not $Force )
            {
                Write-Error ('File ''{0}'' exists. Use the -Force switch to overwrite.' -f $Path)
                return
            }
        }
        else
        {
            $root = Split-Path -Parent -Path $Path
            if( -not (Test-Path -Path $root -PathType Container) )
            {
                New-Item -Path $root -ItemType 'Directory' -Force -Verbose:$VerbosePreference | Out-Null
            }
        }

        return $Path
    }

    $PublicKeyFile = Resolve-KeyPath -Path $PublicKeyFile
    if( -not $PublicKeyFile )
    {
        return
    }

    $PrivateKeyFile = Resolve-KeyPath -Path $PrivateKeyFile
    if( -not $PrivateKeyFile )
    {
        return
    }

    if( (Test-Path -Path $PrivateKeyFile -PathType Leaf) )
    {
        if( -not $Force )
        {
            Write-Error ('Private key file ''{0}'' exists. Use the -Force switch to overwrite.' -f $PrivateKeyFile)
            return
        }
    }

    $tempDir = 'Carbon+NewRsaKeyPair+{0}+' -f ([IO.Path]::GetRandomFileName())
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' -Verbose:$VerbosePreference | Out-Null

    try
    {
        $makeCert = Find-WindowsSdkCommand 'makecert.exe'
        if( -not $makeCert )
        {
            return
        }

        $pvk2pfx = Find-WindowsSdkCommand 'pvk2pfx.exe'
        if( -not $pvk2pfx )
        {
            return
        }

        $privateKeyPath = Join-Path -Path $tempDir -ChildPath 'private.pkv'
        $output = & $makeCert.FullName -r `
                             -a $Algorithm `
                             -sky 'exchange' `
                             -n $Subject `
                             -pe `
                             -sv $privateKeyPath `
                             -len $Length `
                             -b ($ValidFrom.ToString('MM/dd/yyyy')) `
                             -e ($ValidTo.ToString('MM/dd/yyyy')) `
                             '-$' $Authority `
                             $PublicKeyFile
        if( $LASTEXITCODE )
        {
            Write-Error ('Failed to create public/private key pair:{0}{1}' -f ([Environment]::NewLine),($output -join ([Environment]::NewLine)))
            return
        }
        else
        {
            $output | Write-Verbose
        }

        $password = Read-Host -Prompt 'Enter private key password' -AsSecureString
        $password = Convert-SecureStringToString $password
        $passwordArgName = ''
        $passwordArgValue = ''
        if( $password )
        {
            $passwordArgName = '-pi'
            $passwordArgValue = $password
        }

        $output = & $pvk2pfx.FullName -pvk $privateKeyPath -spc $PublicKeyFile -pfx $PrivateKeyFile $passwordArgName $passwordArgValue -f
        if( $LASTEXITCODE )
        {
            Write-Error ('Failed to create PFX file for public/key pair:{0}{1}' -f ([Environment]::NewLine),($output -join ([Environment]::NewLine)))
            return
        }
        else
        {
            $output | Write-Verbose
        }

        Get-Item $PublicKeyFile
        Get-Item $PrivateKeyFile
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse
    }
}