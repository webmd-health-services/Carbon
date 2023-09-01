
function Complete-CJob
{
    <#
    .SYNOPSIS
    OBSOLETE. Use PowerShell's `Wait-Job` cmdlet instead. Will be removed in a future major version of Carbon.

    .DESCRIPTION
    OBSOLETE. Use PowerShell's `Wait-Job` cmdlet instead. Will be removed in a future major version of Carbon.

    .EXAMPLE
    Get-Job | Wait-Job

    Demonstrates that `Complete-CJob` is OBSOLETE and you should use PowerShell's `Wait-Job` cmdlet instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Management.Automation.Job[]]
        # The jobs to complete.
        [Alias('Jobs')]
        $Job,

        [Parameter()]
        [int]
        # The number of seconds to sleep between job status checks.  Default is 1 second.
        $IntervalSeconds = 1
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name -NewCommandName 'Wait-Job'

    $errorAction = 'Continue'
    $params = $PSBoundParameters
    if( $PSBoundParameters.ContainsKey( 'ErrorAction' ) )
    {
        $errorAction = $PSBoundParameters.ErrorAction
    }

    trap { Write-Warning "Unhandled error found: $_" }
    $numFailed = 0
    do
    {
        Start-Sleep -Seconds $IntervalSeconds

        $jobsStillRunning = $false
        foreach( $pendingJob in $Job )
        {
            $currentJob = Get-Job $pendingJob.Id -ErrorAction SilentlyContinue
            if( -not $currentJob )
            {
                Write-Verbose "Job with ID $($pendingJob.Id) doesn't exist."
                continue
            }

            try
            {
                Write-Verbose "Job $($currentJob.Name) is in the $($currentJob.State) state."

                $jobHeader = "# $($currentJob.Name): $($currentJob.State)"
                if( $currentJob.State -eq 'Blocked' -or $currentJob.State -eq 'Stopped')
                {
                    Write-Host $jobHeader

                    Write-Verbose "Stopping job $($currentJob.Name)."
                    Stop-Job -Job $currentJob

                    Write-Verbose "Receiving job $($currentJob.Name)."
                    Receive-Job -Job $currentJob -ErrorAction $errorAction| Write-Host

                    Write-Verbose "Removing job $($currentJob.Name)."
                    Remove-Job -Job $currentJob
                    $numFailed += 1
                }
                elseif( $currentJob.State -eq 'Completed' -or $currentJob.State -eq 'Failed' )
                {
                    Write-Host $jobHeader

                    Write-Verbose "Receiving job $($currentJob.Name)."
                    Receive-Job -Job $currentJob -ErrorAction $errorAction | Write-Host

                    Write-Verbose "Removing job $($currentJob.Name)."
                    Remove-Job -Job $currentJob
                    if( $currentJob.State -eq 'Failed' )
                    {
                        $numFailed += 1
                    }
                }
                elseif( $currentJob.State -eq 'NotStarted' -or $currentJob.State -eq 'Running' )
                {
                    $jobsStillRunning = $true
                }
                else
                {
                    Write-Error "Found unknown job state $($currentJob.State)."
                }
            }
            catch
            {
                Write-Warning "Encountered error handling job $($currentJob.Name)."
                Write-Warning $_
            }
        }

     } while( $jobsStillRunning )

     return $numFailed
}

Set-Alias -Name 'Complete-Jobs' -Value 'Complete-CJob'


function Convert-CSecureStringToString
{
    <#
    .SYNOPSIS
    Converts a secure string into a plain text string.

    .DESCRIPTION
    Sometimes you just need to convert a secure string into a plain text string.  This function does it for you.  Yay!  Once you do, however, the cat is out of the bag and your password will be *all over memory* and, perhaps, the file system.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Convert-CSecureStringToString -SecureString $mySuperSecretPasswordIAmAboutToExposeToEveryone

    Returns the plain text/decrypted value of the secure string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Security.SecureString]
        # The secure string to convert.
        $SecureString,

        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
    }

    $stringPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto($stringPtr)
}


function ConvertTo-CBase64
{
    <#
    .SYNOPSIS
    Converts a value to base-64 encoding.

    .DESCRIPTION
    For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process.

    You're actually allowed to pass in `$null` and an empty string.  If you do, you'll get `$null` and an empty string back.

    .LINK
    ConvertFrom-CBase64

    .EXAMPLE
    ConvertTo-CBase64 -Value 'Encode me, please!'

    Encodes `Encode me, please!` into a base-64 string.

    .EXAMPLE
    ConvertTo-CBase64 -Value 'Encode me, please!' -Encoding ([Text.Encoding]::ASCII)

    Shows how to specify a custom encoding in case your string isn't in Unicode text encoding.

    .EXAMPLE
    'Encode me!' | ConvertTo-CBase64

    Converts `Encode me!` into a base-64 string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]
        # The value to base-64 encoding.
        $Value,

        [Text.Encoding]
        # The encoding to use.  Default is Unicode.
        $Encoding = ([Text.Encoding]::Unicode),

        [switch]$NoWarn
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( -not $NoWarn )
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Core'
        }
    }

    process
    {
        $Value | ForEach-Object {
            if( $_ -eq $null )
            {
                return $null
            }

            $bytes = $Encoding.GetBytes($_)
            [Convert]::ToBase64String($bytes)
        }
    }
}



function ConvertTo-CSecurityIdentifier
{
    <#
    .SYNOPSIS
    Converts a string or byte array security identifier into a `System.Security.Principal.SecurityIdentifier` object.

    .DESCRIPTION
    `ConvertTo-CSecurityIdentifier` converts a SID in SDDL form (as a string), in binary form (as a byte array) into a
    `System.Security.Principal.SecurityIdentifier` object. It also accepts
    `System.Security.Principal.SecurityIdentifier` objects, and returns them back to you.

    If the string or byte array don't represent a SID, an error is written and nothing is returned.

    .LINK
    Resolve-CIdentity

    .LINK
    Resolve-CIdentityName

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID 'S-1-5-21-2678556459-1010642102-471947008-1017'

    Demonstrates how to convert a a SID in SDDL into a `System.Security.Principal.SecurityIdentifier` object.

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID (New-Object 'Security.Principal.SecurityIdentifier' 'S-1-5-21-2678556459-1010642102-471947008-1017')

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter. The SID you passed
    in will be returned to you unchanged.

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding()]
    param(
        # The SID to convert to a `System.Security.Principal.SecurityIdentifier`. Accepts a SID in SDDL form as a
        # `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of
        # bytes.
        [Parameter(Mandatory)]
        [Object] $SID,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName 'ConvertTo-CSecurityIdentifier' `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NoWarn:$NoWarn

    try
    {
        if( $SID -is [string] )
        {
            New-Object 'Security.Principal.SecurityIdentifier' $SID
        }
        elseif( $SID -is [byte[]] )
        {
            New-Object 'Security.Principal.SecurityIdentifier' $SID,0
        }
        elseif( $SID -is [Security.Principal.SecurityIdentifier] )
        {
            $SID
        }
        else
        {
            Write-Error ('Invalid SID. The `SID` parameter accepts a `System.Security.Principal.SecurityIdentifier` object, a SID in SDDL form as a `string`, or a SID in binary form as byte array. You passed a ''{0}''.' -f $SID.GetType())
            return
        }
    }
    catch
    {
        Write-Error ('Exception converting SID parameter to a `SecurityIdentifier` object. This usually means you passed an invalid SID in SDDL form (as a string) or an invalid SID in binary form (as a byte array): {0}' -f $_.Exception.Message)
        return
    }
}


# Leave these here so that when Get-CCertificate moves to its own module, these go with it.
Add-CTypeData -Type Security.Cryptography.X509Certificates.X509Certificate2 `
              -MemberName 'IssuedTo' `
              -MemberType ScriptProperty `
              -Value { $this.GetNameInfo( 'SimpleName', $false ) }

Add-CTypeData -Type Security.Cryptography.X509Certificates.X509Certificate2 `
              -MemberName 'IssuedBy' `
              -MemberType ScriptProperty `
              -Value { $this.GetNameInfo( 'SimpleName', $true ) }

Add-CTypeData -Type Security.Cryptography.X509Certificates.X509Store `
              -MemberName 'DisplayName' `
              -MemberType ScriptProperty `
              -Value {
                    switch( $this.Name )
                    {
                        'AddressBook' { return 'Other People' }
                        'AuthRoot' { return 'Third-Party Root Certification Authorities' }
                        'CA' { return 'Intermediate Certification Authorities' }
                        'CertificateAuthority' { return 'Intermediate Certification Authorities' }
                        'Disallowed' { return 'Untrusted Certificates' }
                        'My' { return 'Personal' }
                        'Root' { return 'Trusted Root Certification Authorities' }
                        'TrustedPeople' { return 'Trusted People' }
                        'TrustedPublisher' { return 'Trusted Publishers' }
                        default { return '' }
                    }
                }

Add-CTypeData -Type Security.Cryptography.X509Certificates.X509Store `
              -MemberName 'StoreName' `
              -MemberType ScriptProperty `
              -Value {
                    if( $this.Name -eq 'CA' )
                    {
                        return [Security.Cryptography.X509Certificates.StoreName]::CertificateAuthority
                    }

                    foreach( $value in ([Enum]::GetValues([Security.Cryptography.X509Certificates.StoreName])) )
                    {
                        if( $this.Name -eq $value.ToString() )
                        {
                            return $value
                        }
                    }

                    return ''
                }

function Get-CCertificate
{
    <#
    .SYNOPSIS
    Gets a certificate from a file on the file system or from a Windows certificate store by thumbprint or friendly name.

    Beginning in Carbon 2.7, the returned object will have a `Path` property that is the full path to either the file or certificate in the certificate store.

    .DESCRIPTION
    Certificates can be files or they can be in a Windows certificate store.  This function returns an `X509Certificate2` object for a script that's a file on the file system or a cert stored in Microsoft's certificate store.  You can get a certificate from a certificate store with its unique thumbprint or its friendly name.  Friendly names are *not* required to be unique, so you may get multiple certificates when using that search method.

    Certificates loaded from a file are imported with default key storage values, which means if you try to add the certifiate returned by this function to a certificate store it will get persisted in the user's key store and *not* persisted.

    .OUTPUTS
    System.Security.Cryptography.x509Certificates.X509Certificate2. The X509Certificate2 certificates that were found, or `$null`.

    .EXAMPLE
    Get-CCertificate -Path C:\Certificates\certificate.cer -Password MySuperSecurePassword

    Gets an X509Certificate2 object representing the certificate.cer file. Wildcards *not* supported when using a file system path.

    .EXAMPLE
    Get-CCertificate -Thumbprint a909502dd82ae41433e6f83886b00d4277a32a7b -StoreName My -StoreLocation LocalMachine

    Gets an X509Certificate2 object for the certificate in the Personal store with a specific thumbprint under the Local Machine.

    .EXAMPLE
    Get-CCertificate -FriendlyName 'Development Certificate' -StoreLocation CurrentUser -StoreName TrustedPeople

    Gets the X509Certificate2 whose friendly name is Development Certificate from the Current User's Trusted People certificate store.

    .EXAMPLE
    Get-CCertificate -Thumbprint a909502dd82ae41433e6f83886b00d4277a32a7b -CustomStoreName 'SharePoint' -StoreLocation LocalMachine

    Demonstrates how to get a certificate from a custom store, i.e. one that is not part of the standard `StoreName` enumeration.

    .EXAMPLE
    Get-CCertificate -Path 'cert:\CurrentUser\a909502dd82ae41433e6f83886b00d4277a32a7b'

    Demonstrates how to get a certificate out of a Windows certificate store with its certificate path. Wildcards supported.
    #>
    [CmdletBinding(DefaultParameterSetName='ByFriendlyName')]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        # The path to the certificate. Can be a file system path or a certificate path, e.g. `cert:\`. Wildcards supported.
        $Path,

        [Parameter(ParameterSetName='ByPath')]
        # The password to the certificate.  Can be plaintext or a [SecureString](http://msdn.microsoft.com/en-us/library/system.securestring.aspx).
        $Password,

        [Parameter(ParameterSetName='ByPath')]
        [Security.Cryptography.X509Certificates.X509KeyStorageFlags]
        # The storage flags to use when loading a certificate file. This controls where/how you can store the certificate in the certificate stores later. Use the `-bor` operator to combine flags.
        $KeyStorageFlags,


        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintCustomStoreName')]
        [string]
        # The certificate's thumbprint.
        $Thumbprint,

        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyNameCustomStoreName')]
        [string]
        # The friendly name of the certificate.
        $FriendlyName,

        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyNameCustomStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintCustomStoreName')]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.
        $StoreLocation,

        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='ByFriendlyNameCustomStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintCustomStoreName')]
        [string]
        # The name of the non-standard, custom store.
        $CustomStoreName,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
    }

    function Add-PathMember
    {
        param(
            [Parameter(Mandatory,VAlueFromPipeline=$true)]
            [Security.Cryptography.X509Certificates.X509Certificate2]
            $Certificate,

            [Parameter(Mandatory)]
            [string]
            $Path
        )

        process
        {
            $Certificate | Add-Member -MemberType NoteProperty -Name 'Path' -Value $Path -PassThru
        }
    }

    function Resolve-CertificateProviderFriendlyPath
    {
        param(
            [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
            [string]
            $PSPath,

            [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
            [Management.Automation.PSDriveInfo]
            $PSDrive
        )

        process
        {
            $qualifier = '{0}:' -f $PSDrive.Name
            $path = $PSPath | Split-Path -NoQualifier
            Join-Path -Path $qualifier -ChildPath $path
        }
    }

    if( $PSCmdlet.ParameterSetName -eq 'ByPath' )
    {
        if( -not (Test-Path -Path $Path -PathType Leaf) )
        {
            Write-Error ('Certificate ''{0}'' not found.' -f $Path)
            return
        }

        Get-Item -Path $Path |
            ForEach-Object {
                $item = $_
                if( $item -is [Security.Cryptography.X509Certificates.X509Certificate2] )
                {
                    $certFriendlyPath = $item | Resolve-CertificateProviderFriendlyPath
                    return $item | Add-PathMember -Path $certFriendlyPath
                }
                elseif( $item -is [IO.FileInfo] )
                {
                    try
                    {
                        $ctorParams = @( $item.FullName, $Password )
                        if( $KeyStorageFlags )
                        {
                            $ctorParams += $KeyStorageFlags
                        }
                        return New-Object 'Security.Cryptography.X509Certificates.X509Certificate2' $ctorParams | Add-PathMember -Path $item.FullName
                    }
                    catch
                    {
                        $ex = $_.Exception
                        while( $ex.InnerException )
                        {
                            $ex = $ex.InnerException
                        }
                        Write-Error -Message ('Failed to create X509Certificate2 object from file ''{0}'': {1}' -f $item.FullName,$ex.Message)
                    }
                }
            }
    }
    else
    {
        $storeLocationPath = '*'
        if( $StoreLocation )
        {
            $storeLocationPath = $StoreLocation
        }

        $storeNamePath = '*'
        if( $PSCmdlet.ParameterSetName -like '*CustomStoreName' )
        {
            $storeNamePath = $CustomStoreName
        }
        else
        {
            $storeNamePath = $StoreName
            if( $StoreName -eq [Security.Cryptography.X509Certificates.StoreName]::CertificateAuthority )
            {
                $storeNamePath = 'CA'
            }
        }

        if( $pscmdlet.ParameterSetName -like 'ByThumbprint*' )
        {
            $certPath = 'cert:\{0}\{1}\{2}' -f $storeLocationPath,$storeNamePath,$Thumbprint
            if( (Test-Path -Path $certPath) )
            {
                foreach( $certPathItem in (Get-ChildItem -Path $certPath) )
                {
                    $path = $certPathItem | Resolve-CertificateProviderFriendlyPath
                    $certPathItem | Add-PathMember -Path $path
                }
            }
            return
        }
        elseif( $PSCmdlet.ParameterSetName -like 'ByFriendlyName*' )
        {
            $certPath = Join-Path -Path 'cert:' -ChildPath $storeLocationPath
            $certPath = Join-Path -Path $certPath -ChildPath $storeNamePath
            $certPath = Join-Path -Path $certPath -ChildPath '*'
            return Get-ChildItem -Path $certPath |
                        Where-Object { $_.FriendlyName -eq $FriendlyName } |
                        ForEach-Object {
                            $friendlyPath = $_ | Resolve-CertificateProviderFriendlyPath
                            $_ | Add-PathMember -Path $friendlyPath
                        }
        }
        Write-Error "Unknown parameter set '$($pscmdlet.ParameterSetName)'."
    }
}


function Get-CMsi
{
    <#
    .SYNOPSIS
    Gets details about an MSI file.

    .DESCRIPTION
    The `Get-CMsi` function reads the installer properties from an MSI file and returns a `Carbon.Msi.MsiInfo` object representing an MSI's properties. `Carbon.Msi.MsiInfo` has properties for the following required MSI properties:

     * ProductName
     * ProductCode
     * ProduceLanguage
     * Manufacturer
     * ProductVersion

    All other properties are accessible via the `Properties` property, which is a hashtable of property name/value pairs.

    There is an additioanl `Path` property to capture the path of the MSI the properties came from.

    `Get-CMsi` was introduced in Carbon 2.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa370905.aspx

    .EXAMPLE
    Get-CMsi -Path MyCool.msi

    Demonstrates how to read the properties from `MyCool.msi` file.

    .EXAMPLE
    Get-ChildItem *.msi -Recurse | Get-CMsi

    Demonstrates how you can pipe file info objects into `Get-CMsi`.
    #>
    [CmdletBinding()]
    [OutputType('Carbon.Msi.MsiInfo')]
    param(
        # Path to the MSI file whose information to retrieve. Wildcards supported.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]] $Path
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Installer'
    }

    process
    {
        $Path |
            Resolve-Path |
            Select-Object -ExpandProperty 'ProviderPath' |
            ForEach-Object {

                $msiPath = $_

                try
                {
                    Write-Verbose ('Opening MSI {0}' -f $msiPath)
                    New-Object -TypeName 'Carbon.Msi.MsiInfo' -ArgumentList $msiPath
                }
                catch
                {
                    $ex = $_.Exception
                    $errMsg = 'Failed to open MSI file ''{0}''.' -f $msiPath
                    if( $ex )
                    {
                        $errMsg = '{0} {1} was thrown. The exception message is: ''{2}''.' -f $errMsg,$ex.GetType().FullName,$ex.Message
                        if( $ex -is [Runtime.InteropServices.COMException] )
                        {
                            $errMsg = '{0} HRESULT: {1:x}. (You can look up the meaning of HRESULT values at https://msdn.microsoft.com/en-us/library/cc704587.aspx.)' -f $errMsg,$ex.ErrorCode
                        }
                    }
                    Write-Error -Message $errMsg
                    return
                }


            }
    }

    end
    {
    }
}



function Get-CPathProvider
{
    <#
    .SYNOPSIS
    Returns a path's PowerShell provider.

    .DESCRIPTION
    When you want to do something with a path that depends on its provider, use this function.  The path doesn't have to exist.

    If you pass in a relative path, it is resolved relative to the current directory.  So make sure you're in the right place.

    .OUTPUTS
    System.Management.Automation.ProviderInfo.

    .EXAMPLE
    Get-CPathProvider -Path 'C:\Windows'

    Demonstrates how to get the path provider for an NTFS path.
    #>
    [CmdletBinding()]
    param(
        # The path whose provider to get.
        [Parameter(Mandatory)]
        [String] $Path,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName 'Get-CPathProvider' -ModuleName 'Carbon.Core' -NoWarn:$NoWarn

    $pathQualifier = Split-Path -Qualifier $Path -ErrorAction SilentlyContinue
    if( -not $pathQualifier )
    {
        $Path = Join-Path -Path (Get-Location) -ChildPath $Path
        $pathQualifier = Split-Path -Qualifier $Path -ErrorAction SilentlyContinue
        if( -not $pathQualifier )
        {
            Write-Error "Qualifier for path '$Path' not found."
            return
        }
    }

    $pathQualifier = $pathQualifier.Trim(':')
    $drive = Get-PSDrive -Name $pathQualifier -ErrorAction Ignore
    if( -not $drive )
    {
        $drive = Get-PSDrive -PSProvider $pathQualifier -ErrorAction Ignore
    }

    if( -not $drive )
    {
        Write-Error -Message ('Unable to determine the provider for path {0}.' -f $Path)
        return
    }

    $drive  |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'Provider'

}


function Get-CPowershellPath
{
    <#
    .SYNOPSIS
    Gets the path to powershell.exe.

    .DESCRIPTION
    Returns the path to the powershell.exe binary for the machine's default architecture (i.e. x86 or x64).  If you're on a x64 machine and want to get the path to x86 PowerShell, set the `x86` switch.

    Here are the possible combinations of operating system, PowerShell, and desired path architectures, and the path they map to.

        +-----+-----+------+--------------------------------------------------------------+
        | OS  | PS  | Path | Result                                                       |
        +-----+-----+------+--------------------------------------------------------------+
        | x64 | x64 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x64 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x86 | x64  | $env:windir\sysnative\Windows PowerShell\v1.0\powershell.exe |
        | x64 | x86 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x86  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        +-----+-----+------+--------------------------------------------------------------+

    .EXAMPLE
    Get-CPowerShellPath

    Returns the path to the version of PowerShell that matches the computer's architecture (i.e. x86 or x64).

    .EXAMPLE
    Get-CPowerShellPath -x86

    Returns the path to the x86 version of PowerShell.
    #>
    [CmdletBinding()]
    param(
        # Gets the path to 32-bit PowerShell.
        [switch]$x86,

        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Core'
    }

    $psPath = $PSHOME
    if( $PSVersionTable.PSEdition -eq 'Core' )
    {
        $psPath = 'C:\Windows\System32\WindowsPowerShell\v1.0'
    }

    # x86 OS/x86 PowerShell. There's no 64-bit anything, so just return $PSHOME.
    if (Test-COSIs32Bit -NoWarn)
    {
        if( $x86 )
        {
            return Join-Path -Path $psPath -ChildPath 'powershell.exe'
        }

        $msg = 'Unable to get the path to 64-bit PowerShell: this is a 32-bit operating system and ' +
            '64-bit PowerShell does not exist.'
        Write-Error -Message $msg -ErrorAction Ignore
        return
    }

    # Make sure the paths end in '\' so we don't replace/change
    # paths that start with the directory name and have extra characters.
    $programFilesPath = Join-Path -Path ([Environment]::GetFolderPath('ProgramFiles')) -ChildPath '\'
    $systemPath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath '\'

    if( (Test-CPowerShellIs64Bit -NoWarn) )
    {
        $programFilesx86Path =
            Join-Path -Path ([Environment]::GetFolderPath('ProgramFilesx86')) -ChildPath '\'
        $system32Path = Join-Path -Path ([Environment]::GetFolderPath('Systemx86')) -ChildPath '\'

        if( $x86 )
        {
            # x64 OS/x64 PS wanting x86 paths.
            # C:\Program Files\ -> C:\Program Files (x86)\
            # C:\WINDOWS\system32\ -> C:\WINDOWS\SysWOW64\
            return Join-Path -Path (($psPath -replace ([regex]::Escape($programFilesPath)), $programFilesx86Path)  `
                            -replace ([regex]::Escape($systemPath)), $system32Path) -ChildPath 'powershell.exe'
        }

        # x64 OS/PS, wanting x64 Path, which is the same as this process's PSHOME variable.
        return Join-Path $psPath -ChildPath 'powershell.exe'
    }

    if( $x86 )
    {
        # x64 OS/x86 PowerShell, wanting x86 path, which is the same as this process.
        return Join-Path $psPath -ChildPath 'powershell.exe'
    }

    # x64 OS, x86 PowerShell, wanting x64 path
    # C:\Program Files (x86)\ -> C:\Program Files\
    # C:\WINDOWS\system32\ -> C:\WINDOWS\sysnative\
    $programFiles64Path = Join-Path -Path $env:ProgramFilesW6432 -ChildPath '\'
    $system64Path = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'sysnative\'
    return Join-Path -Path (($psPath -replace ([regex]::Escape($programFilesPath)), $programFiles64Path) `
                    -replace ([regex]::Escape($systemPath)), $system64Path) -ChildPath 'powershell.exe'
}


function Get-CProgramInstallInfo
{
    <#
    .SYNOPSIS
    Gets information about the programs installed on the computer.

    .DESCRIPTION
    The `Get-CProgramInstallInfo` function is the PowerShell equivalent of the Programs and Features UI in the Control Panel. It inspects the registry to determine what programs are installed. It will return programs installed for *all* users, not just the current user.

    `Get-CProgramInstallInfo` tries its best to get accurate data. The following properties either isn't stored consistently, is in strange formats, can't be parsed, etc.

     * The `ProductCode` property is set to `[Guid]::Empty` if the software doesn't have a product code.
     * The `User` property will only be set for software installed for specific users. For global software, the `User` property will be `[String]::Empty`.
     * The `InstallDate` property is set to `[DateTime]::MinValue` if the install date can't be determined.
     * The `Version` property is `$null` if the version can't be parsed

    .OUTPUTS
    Carbon.Computer.ProgramInstallInfo.

    .EXAMPLE
    Get-CProgramInstallInfo

    Demonstrates how to get a list of all the installed programs, similar to what the Programs and Features UI shows.

    .EXAMPLE
    Get-CProgramInstallInfo -Name 'Google Chrome'

    Demonstrates how to get a specific program. If the specific program isn't found, `$null` is returned.

    .EXAMPLE
    Get-CProgramInstallInfo -Name 'Microsoft*'

    Demonstrates how to use wildcards to search for multiple programs.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Computer.ProgramInstallInfo])]
    param(
        # The name of a specific program to get. Wildcards supported.
        [string] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Windows.Installer' `
                                    -NewCommandName 'Get-CInstalledProgram'

    if( -not (Test-Path -Path 'hku:\') )
    {
        $null = New-PSDrive -Name 'HKU' -PSProvider Registry -Root 'HKEY_USERS'
    }

    ('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall','hku:\*\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') |
        Where-Object { Test-Path -Path $_ -PathType Container } |
        Get-ChildItem |
        Where-Object {
            $valueNames = $_.GetValueNames()

            [Microsoft.Win32.RegistryKey]$key = $_

            if( $valueNames -notcontains 'DisplayName' )
            {
                Write-Debug ('Skipping {0}: DisplayName not found.' -f $_.Name)
                return $false
            }

            $displayName = $_.GetValue( 'DisplayName' )

            if( $valueNames -contains 'ParentKeyName' )
            {
                Write-Debug ('Skipping {0} ({1}): found ParentKeyName property.' -f $displayName,$_.Name)
                return $false
            }

            if( $valueNames -contains 'SystemComponent' -and $_.GetValue( 'SystemComponent' ) -eq 1 )
            {
                Write-Debug ('Skipping {0} ({1}): SystemComponent property is 1.' -f $displayName,$_.Name)
                return $false
            }

            return $true
        } |
        Where-Object {
                if( $Name )
                {
                    return $_.GetValue('DisplayName') -like $Name
                }
                return $true
            } |
        ForEach-Object { New-Object 'Carbon.Computer.ProgramInstallInfo' $_ }
}



function Get-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Gets the value from a registry key.

    .DESCRIPTION
    PowerShell's `Get-ItemProperty` cmdlet is a pain to use.  It doesn't actually return an object representing a registry key's value, but some other weird object that requires painful gyrations to get values from. This function returns just the value of a key.

    .EXAMPLE
    Get-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns the value of the 'hklm:\Software\Carbon\Test' key's `Title` value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Registry'
    }

    if( -not (Test-CRegistryKeyValue -Path $Path -Name $Name -NoWarn) )
    {
        return $null
    }

    $itemProperties = Get-ItemProperty -Path $Path -Name *
    $value = $itemProperties.$Name
    Write-Debug -Message ('[{0}@{1}: {2} -is {3}' -f $Path,$Name,$value,$value.GetType())
    return $value
}



function Get-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Gets the SSL certificate bindings on this computer.

    .DESCRIPTION
    Windows binds SSL certificates to an IP addresses/port combination.  This function gets all the SSL bindings on this computer, or a binding for a specific IP/port, or $null if one doesn't exist.  The bindings are returned as `Carbon.Certificates.SslCertificateBinding` objects.

    .OUTPUTS
    Carbon.Certificates.SslCertificateBinding.

    .EXAMPLE
    > Get-CSslCertificateBinding

    Gets all the SSL certificate bindings on the local computer.

    .EXAMPLE
    > Get-CSslCertificateBinding -IPAddress 42.37.80.47 -Port 443

    Gets the SSL certificate bound to 42.37.80.47, port 443.

    .EXAMPLE
    > Get-CSslCertificateBinding -Port 443

    Gets the default SSL certificate bound to ALL the computer's IP addresses on port 443.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Certificates.SslCertificateBinding])]
    param(
        [IPAddress]
        # The IP address whose certificate(s) to get.  Should be in the form IP:port. Optional.
        $IPAddress,

        [UInt16]
        # The port whose certificate(s) to get. Optional.
        $Port,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Windows.HttpServer'
    }

    [Carbon.Certificates.SslCertificateBinding]::GetSslCertificateBindings() |
        Where-Object {
            if( $IPAddress )
            {
                $_.IPAddress -eq $IPAddress
            }
            else
            {
                return $true
            }
        } |
        Where-Object {
            if( $Port )
            {
                $_.Port -eq $Port
            }
            else
            {
                return $true
            }
        }

}

Set-Alias -Name 'Get-SslCertificateBindings' -Value 'Get-CSslCertificateBinding'


# This function should only be available if the Windows PowerShell v3.0 Server Manager cmdlets aren't already installed.
if( -not (Get-Command -Name 'Get-WindowsFeature*' | Where-Object { $_.ModuleName -ne 'Carbon' }) )
{
    function Get-CWindowsFeature
    {
        <#
        .SYNOPSIS
        Gets a list of available Windows features, or details on a specific windows feature.

        .DESCRIPTION
        Different versions of Windows use different names for installing Windows features.  Use this function to get the list of functions for your operating system.

        With no arguments, will return a list of all Windows features.  You can use the `Name` parameter to return a specific feature or a list of features that match a wildcard.

        **This function is not available on Windows 8/2012.**

        .OUTPUTS
        PsObject.  A generic PsObject with properties DisplayName, Name, and Installed.

        .LINK
        Install-CWindowsFeature

        .LINK
        Test-CWindowsFeature

        .LINK
        Uninstall-CWindowsFeature

        .EXAMPLE
        Get-CWindowsFeature

        Returns a list of all available Windows features.

        .EXAMPLE
        Get-CWindowsFeature -Name MSMQ

        Returns the MSMQ feature.

        .EXAMPLE
        Get-CWindowsFeature -Name *msmq*

        Returns any Windows feature whose name matches the wildcard `*msmq*`.
        #>
        [CmdletBinding()]
        param(
            [Parameter()]
            [string]
            # The feature name to return.  Can be a wildcard.
            $Name
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                      -NewCommandName 'Get-WindowsFeature' `
                                      -NewModuleName 'ServerManager'

        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }

        if( $useOCSetup )
        {
            Get-CCimInstance -Class 'Win32_OptionalFeature' |
                Where-Object {
                    if( $Name )
                    {
                        return ($_.Name -like $Name)
                    }
                    else
                    {
                        return $true
                    }
                } |
                ForEach-Object {
                    $properties = @{
                        Installed = ($_.InstallState -eq 1);
                        Name = $_.Name;
                        DisplayName = $_.Caption;
                    }
                    New-Object PsObject -Property $properties
                }
        }
        elseif( $useServerManager )
        {
            servermanagercmd.exe -query |
                Where-Object {
                    if( $Name )
                    {
                        return ($_ -match ('\[{0}\]$' -f [Text.RegularExpressions.Regex]::Escape($Name)))
                    }
                    else
                    {
                        return $true
                    }
                } |
                Where-Object { $_ -match '\[(X| )\] ([^[]+) \[(.+)\]' } |
                ForEach-Object {
                    $properties = @{
                        Installed = ($matches[1] -eq 'X');
                        Name = $matches[3]
                        DisplayName = $matches[2];
                    }
                    New-Object PsObject -Property $properties
               }
        }
        else
        {
            Write-Error $supportNotFoundErrorMessage
        }
    }

    Set-Alias -Name 'Get-WindowsFeature' -Value 'Get-CWindowsFeature'
}



function Install-CCertificate
{
    <#
    .SYNOPSIS
    Installs a certificate in a given store.

    .DESCRIPTION
    Uses the .NET certificates API to add a certificate to a store for the machine or current user.  The user performing
    the action must have permission to modify the store or the installation will fail.

    To install a certificate on a remote computer, create a remoting session with the `New-PSSession` cmdlet, and pass
    the session object to this function's `Session` parameter. When installing to a remote computer, the certificate's
    binary data is converted to a base-64 encoded string and sent to the remote computer, where it is converted back
    into a certificate. If installing a certificate from a file, the file's bytes are converted to base-64, sent to the
    remote computer, saved as a temporary file, installed, and the temporary file is removed.

    The ability to install a certificate on a remote computer was added in Carbon 2.1.0.

    .OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2. An X509Certificate2 object representing the newly
    installed certificate.

    .EXAMPLE
    > Install-CCertificate -Path C:\Users\me\certificate.cer -StoreLocation LocalMachine -StoreName My -Exportable -Password My5up3r53cur3P@55w0rd

    Installs the certificate (which is protected by a password) at C:\Users\me\certificate.cer into the local machine's
    Personal store.  The certificate is marked exportable.

    .EXAMPLE
    Install-CCertificate -Path C:\Users\me\certificate.cer -StoreLocation LocalMachine -StoreName My -ComputerName remote1,remote2

    Demonstrates how to install a certificate from a file on the local computer into the local machine's personal store
    on two remote cmoputers, remote1 and remote2. Use the `Credential` parameter to connect as a specific principal.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='FromFileInWindowsStore')]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromFileInWindowsStore')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromFileInCustomStore')]
        [string]
        # The path to the certificate file.
        $Path,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromCertificateInWindowsStore')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromCertificateInCustomStore')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        # The certificate to install.
        $Certificate,

        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.  To see a list of acceptable values, run:
        #
        #   > [Enum]::GetValues([Security.Cryptography.X509Certificates.StoreLocation])
        $StoreLocation,

        [Parameter(Mandatory=$true,ParameterSetName='FromFileInWindowsStore')]
        [Parameter(Mandatory=$true,ParameterSetName='FromCertificateInWindowsStore')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.  To see a list of acceptable values run:
        #
        #  > [Enum]::GetValues([Security.Cryptography.X509Certificates.StoreName])
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='FromFileInCustomStore')]
        [Parameter(Mandatory=$true,ParameterSetName='FromCertificateInCustomStore')]
        [string]
        # The name of the non-standard, custom store where the certificate should be installed.
        $CustomStoreName,

        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        [Switch]
        # Mark the private key as exportable. Only valid if loading the certificate from a file.
        $Exportable,

        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        # The password for the certificate.  Should be a `System.Security.SecureString`.
        $Password,

        [Management.Automation.Runspaces.PSSession[]]
        # Use the `Session` parameter to install a certificate on remote computer(s) using PowerShell remoting. Use `New-PSSession` to create a session.
        #
        # This parameter was added in Carbon 2.1.0.
        $Session,

        # Re-install the certificate, even if it is already installed. Calls the `Add()` method for store even if the
        # certificate is in the store. This function assumes that the `Add()` method replaces existing certificates.
        [switch]$Force,

        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
    }

    if( $Password -and $Password -isnot [securestring] )
    {
        Write-CWarningOnce -Message ('You passed a plain text password to `Install-CCertificate`. A future version of Carbon will remove support for plain-text passwords. Please pass a `SecureString` instead.')
        $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
    }

    if( $PSCmdlet.ParameterSetName -like 'FromFile*' )
    {
        $resolvedPath = Resolve-Path -Path $Path
        if( -not $resolvedPath )
        {
            return
        }

        $Path = $resolvedPath.ProviderPath

        $fileBytes = [IO.File]::ReadAllBytes($Path)
        $encodedCert = [Convert]::ToBase64String( $fileBytes )

        # Make sure loading the certificate doesn't leave temporary cruft around on the file system. We're only loading
        # the cert to get its thumbprint.
        $keyStorageFlags = @{}
        if( $StoreLocation -eq [Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser )
        {
            $keyStorageFlags['KeyStorageFlags'] =
                [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
        }
        $Certificate = Get-CCertificate -Path $Path -Password $Password -NoWarn @keyStorageFlags
    }
    else
    {
        $encodedCert = [Convert]::ToBase64String( $Certificate.RawData )
    }

    $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet
    if( $StoreLocation -eq [Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser )
    {
        $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet
    }
    $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet

    if( $Exportable )
    {
        $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    }

    $invokeCommandArgs = @{ }
    if( $Session )
    {
        $invokeCommandArgs['Session'] = $Session
    }

    Invoke-Command @invokeCommandArgs -ScriptBlock {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory,Position=0)]
            # The base-64 encoded certificate to install.
            [String]$EncodedCertificate,

            # The password for the certificate.
            [Parameter(Position=1)]
            [securestring]$Password,

            [Parameter(Mandatory,Position=2)]
            [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation,

            [Parameter(Position=3)]
            $StoreName,

            [Parameter(Position=4)]
            [String]$CustomStoreName,

            [Parameter(Position=5)]
            [Security.Cryptography.X509Certificates.X509KeyStorageFlags]$KeyStorageFlags,

            [Parameter(Position=6)]
            [bool]$WhatIf,

            [Parameter(Position=7)]
            [Management.Automation.ActionPreference]$Verbosity,

            [Parameter(Position=8)]
            [switch]$Force,

            [Parameter(Mandatory,Position=9)]
            [String]$Thumbprint
        )

        Set-StrictMode -Version 'Latest'

        $WhatIfPreference = $WhatIf
        $VerbosePreference = $Verbosity

        $tempDir = 'Carbon+Install-CCertificate+{0}' -f [IO.Path]::GetRandomFileName()
        $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir

        try
        {
            if( $CustomStoreName )
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' $CustomStoreName,$StoreLocation
            }
            else
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store'  ([Security.Cryptography.X509Certificates.StoreName]$StoreName),$StoreLocation
            }

            if( -not $Force )
            {
                $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly) )
                try
                {
                    if( $store.Certificates | Where-Object { $_.Thumbprint -eq $Thumbprint } )
                    {
                        return
                    }
                }
                finally
                {
                    $store.Close()
                }
            }

            # Only do the file system work if the certificate isn't installed.
            New-Item -Path $tempDir -ItemType 'Directory' -WhatIf:$false | Out-Null

            $certBytes = [Convert]::FromBase64String( $EncodedCertificate )
            $certFilePath = Join-Path -Path $tempDir -ChildPath ([IO.Path]::GetRandomFileName())
            [IO.File]::WriteAllBytes( $certFilePath, $certBytes )

            $cert = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2' ($certFilePath, $Password, $KeyStorageFlags)
            $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )

            $description = $cert.FriendlyName
            if( -not $description )
            {
                $description = $cert.Subject
            }

            if( $PSCmdlet.ShouldProcess( ('install into {0}''s {1} store' -f $StoreLocation,$StoreName), ('{0} ({1})' -f $description,$cert.Thumbprint) ) )
            {
                Write-Verbose ('Installing certificate ''{0}'' ({1}) into {2}''s {3} store.' -f $description,$cert.Thumbprint,$StoreLocation,$StoreName)
                $store.Add( $cert )
            }
            $store.Close()
        }
        finally
        {
            if( (Test-Path -Path $tempDir) )
            {
                Remove-Item -Path $tempDir -Recurse -ErrorAction Ignore -WhatIf:$false -Force
            }
        }

    } -ArgumentList $encodedCert,$Password,$StoreLocation,$StoreName,$CustomStoreName,$keyFlags,$WhatIfPreference,$VerbosePreference,$Force,$Certificate.Thumbprint

    return $Certificate
}


function Install-CMsi
{
    <#
    .SYNOPSIS
    Installs software from an MSI file.

    .DESCRIPTION
    `Install-CMsi` installs software from an MSI file. If the install fails, it writes an error. Installation is always done in quiet mode, i.e. you won't see any UI.

    In Carbon 1.9 and earlier, this function was called `Invoke-WindowsInstaller`.

    Beginning with Carbon 2.0, `Install-CMsi` only runs the MSI if the software isn't installed. Use the `-Force` switch to always run the installer.

    .EXAMPLE
    Install-CMsi -Path Path\to\installer.msi

    Runs installer.msi, and waits untils for the installer to finish.  If the installer has a UI, it is shown to the user.

    .EXAMPLE
    Get-ChildItem *.msi | Install-CMsi

    Demonstrates how to pipe MSI files into `Install-CMsi` for installation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the installer to run. Wildcards supported.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [String[]] $Path,

        # OBSOLETE. Installers are run in quiet mode by default. This switch will be removed in a future major version of Carbon.
        [Parameter(DontShow)]
        [switch] $Quiet,

        # Install the MSI even if it has already been installed. Will cause a repair/reinstall to run.
        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSBoundParameters.ContainsKey('Quiet') )
    {
        $msg = 'Install-CMsi''s `Quiet` switch is obsolete and will be removed in the next major version of Carbon. ' +
               'Installers are now run in quiet mode by default. Remove usages of the `Quiet` switch.'
        Write-CWarningOnce -Message $msg
    }

    Get-CMsi -Path $Path |
        Where-Object {
            if( $Force )
            {
                return $true
            }

            $installInfo = Get-CProgramInstallInfo -Name $_.ProductName -ErrorAction Ignore
            if( -not $installInfo )
            {
                return $true
            }

            $result = ($installInfo.ProductCode -ne $_.ProductCode)
            if( -not $result )
            {
                Write-Verbose -Message ('[MSI] [{0}] Installed {1}.' -f $installInfo.DisplayName,$installInfo.InstallDate)
            }
            return $result
        } |
        ForEach-Object {
            $msi = $_
            if( $PSCmdlet.ShouldProcess( $msi.Path, "install" ) )
            {
                Write-Verbose -Message ('[MSI] [{0}] Installing from {1}.' -f $msi.ProductName,$msi.Path)
                $msiProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/quiet","/i",('"{0}"' -f $msi.Path) -NoNewWindow -Wait -PassThru

                if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
                {
                    Write-Error ("{0} {1} installation failed. (Exit code: {2}; MSI: {3})" -f $msi.ProductName,$msi.ProductVersion,$msiProcess.ExitCode,$msi.Path)
                }
            }
        }
}

Set-Alias -Name 'Invoke-WindowsInstaller' -Value 'Install-CMsi'



function Install-CMsmq
{
    <#
    .SYNOPSIS
    Installs Microsoft's Message Queueing system/feature.

    .DESCRIPTION
    Microsoft's MSMQ is *not* installed by default.  It has to be turned on manually.   This function will enable the MSMQ feature.  There are two sub-features: Active Directory integration and HTTP support.  These can also be enabled by setting the `ActiveDirectoryIntegration` and `HttpSupport` switches, respectively.  If MSMQ will be working with queues on other machines, you'll need to enable DTC (the Distributed Transaction Coordinator) by passing the `DTC` switch.

     This function uses Microsoft's feature management command line utilities: `ocsetup.exe` or `servermanagercmd.exe`. **A word of warning**, however.  In our experience, **these tools do not seem to work as advertised**.  They are very slow, and, at least with MSMQ, we have intermittent errors installing it on our developer's Windows 7 computers.  We strongly recommend you install MSMQ manually on a base VM or computer image so that it's a standard part of your installation.  If that isn't possible in your environment, good luck!  let us know how it goes.

    If you know better ways of installing MSMQ or other Windows features, or can help us figure out why Microsoft's command line installation tools don't work consistently, we would appreciate it.

    .EXAMPLE
    Install-CMsmq

    Installs MSMQ on this meachine.  In our experience, this may or may not work.  You'll want to check that the MSMQ service exists and is running after this.  Please help us make this better!

    .EXAMPLE
    Install-CMsmq -HttpSupport -ActiveDirectoryIntegration -Dtc

    Installs MSMQ with the HTTP support and Active Directory sub-features.  Enables and starts the Distributed Transaction Coordinator.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Switch]
        # Enable HTTP Support
        $HttpSupport,

        [Switch]
        # Enable Active Directory Integrations
        $ActiveDirectoryIntegration,

        [Switch]
        # Will MSMQ be participating in external, distributed transactions? I.e. will it be sending messages to queues on other machines?
        $Dtc
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name

    $optionalArgs = @{ }
    if( $HttpSupport )
    {
        $optionalArgs.MsmqHttpSupport = $true
    }

    if( $ActiveDirectoryIntegration )
    {
        $optionalArgs.MsmqActiveDirectoryIntegration = $true
    }

    Install-CWindowsFeature -Msmq @optionalArgs

    if( $Dtc )
    {
        Set-Service -Name MSDTC -StartupType Automatic
        Start-Service -Name MSDTC
        $svc = Get-Service -Name MSDTC
        $svc.WaitForStatus( [ServiceProcess.ServiceControllerStatus]::Running )
    }
}


# This function should only be available if the Windows PowerShell v3.0 Server Manager cmdlets aren't already installed.
if( -not (Get-Command -Name 'Get-WindowsFeature*' | Where-Object { $_.ModuleName -ne 'Carbon' }) )
{
    function Install-CWindowsFeature
    {
        <#
        .SYNOPSIS
        Installs an optional Windows component/feature.

        .DESCRIPTION
        This function will install Windows features.  Note that the name of these features can differ between different versions of Windows. Use `Get-CWindowsFeature` to get the list of features on your operating system.

        **This function is not available on Windows 8/2012.**

        .LINK
        Get-CWindowsFeature

        .LINK
        Test-CWindowsFeature

        .LINK
        Uninstall-CWindowsFeature

        .EXAMPLE
        Install-CWindowsFeature -Name TelnetClient

        Installs Telnet.

        .EXAMPLE
        Install-CWindowsFeature -Name TelnetClient,TFTP

        Installs Telnet and TFTP

        .EXAMPLE
        Install-CWindowsFeature -Iis

        Installs IIS.
        #>
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByName')]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ByName')]
            [string[]]
            # The components to enable/install.  Feature names are case-sensitive.
            [Alias('Features')]
            $Name,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs IIS.
            $Iis,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs IIS's HTTP redirection feature.
            $IisHttpRedirection,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs MSMQ.
            $Msmq,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs MSMQ HTTP support.
            $MsmqHttpSupport,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Installs MSMQ Active Directory Integration.
            $MsmqActiveDirectoryIntegration
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                      -NewCommandName 'Install-WindowsFeature' `
                                      -NewModuleName 'ServerManager'

        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }

        if( $pscmdlet.ParameterSetName -eq 'ByFlag' )
        {
            $Name = Resolve-WindowsFeatureName -Name $PSBoundParameters.Keys
        }

        $componentsToInstall = $Name |
                                    ForEach-Object {
                                        if( (Test-CWindowsFeature -Name $_) )
                                        {
                                            $_
                                        }
                                        else
                                        {
                                            Write-Error ('Windows feature {0} not found.' -f $_)
                                        }
                                    } |
                                    Where-Object { -not (Test-CWindowsFeature -Name $_ -Installed) }

        if( -not $componentsToInstall -or $componentsToInstall.Length -eq 0 )
        {
            return
        }

        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$componentsToInstall'", "install" ) )
        {
            if( $useServerManager )
            {
                servermanagercmd.exe -install $componentsToInstall
            }
            else
            {
                $featuresArg = $componentsToInstall -join ';'
                & ocsetup.exe $featuresArg
                $ocsetup = Get-Process 'ocsetup' -ErrorAction SilentlyContinue
                if( -not $ocsetup )
                {
                    Write-Error "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                    return
                }
                $ocsetup.WaitForExit()
            }
        }
    }

    Set-Alias -Name 'Install-WindowsFeatures' -Value 'Install-CWindowsFeature'
    Set-Alias -Name 'Install-WindowsFeature' -Value 'Install-CWindowsFeature'
}



function Install-CRegistryKey
{
    <#
    .SYNOPSIS
    Creates a registry key.  If it already exists, does nothing.

    .DESCRIPTION
    Given the path to a registry key, creates the key and all its parents.  If the key already exists, nothing happens.

    .EXAMPLE
    Install-CRegistryKey -Path 'hklm:\Software\Carbon\Test'

    Creates the `hklm:\Software\Carbon\Temp` registry key if it doesn't already exist.
    #>
    [CmdletBinding(SupportsShouldPRocess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key to create.
        $Path,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Registry'
    }

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        New-Item -Path $Path -ItemType RegistryKey -Force | Out-String | Write-Verbose
    }
}



function Invoke-CAppCmd
{
    <#
    .SYNOPSIS
    OBSOLETE. Will be removed in a future major version of Carbon. Use `Get-CIisConfigurationSection` with the `Microsoft.Web.Administration` API instead.

    .DESCRIPTION
    OBSOLETE. Will be removed in a future major version of Carbon. Use `Get-CIisConfigurationSection` with the `Microsoft.Web.Administration` API instead.

    .EXAMPLE
    Get-CIisConfigurationSection -SiteName 'Peanuts' -Section 'system.webServer'

    Demonstrates the `Invoke-CAppCmd` is OBSOLETE and will be removed in a future major version of Carbon. Use `Get-CIisConfigurationSection` with the `Microsoft.Web.Administration` API instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        # The arguments to pass to appcmd.
        $AppCmdArgs
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CWarningOnce ('Invoke-CAppCmd is obsolete and will be removed in a future major version of Carbon. Use Carbon''s IIS functions, or `Get-CIisConfigurationSection` to get `ConfigurationElement` objects to manipulate using the `Microsoft.Web.Administration` API.')

    Write-Verbose ($AppCmdArgs -join " ")
    & (Join-Path $env:SystemRoot 'System32\inetsrv\appcmd.exe') $AppCmdArgs
    if( $LastExitCode -ne 0 )
    {
        Write-Error "``AppCmd $($AppCmdArgs)`` exited with code $LastExitCode."
    }
}


function Invoke-CPowerShell
{
    <#
    .SYNOPSIS
    Invokes a script block, script, command, or encoded command under a new `powershell.exe` process.

    .DESCRIPTION

    The `Invoke-CPowerShell` scripts executes `powershell.exe`. All processes are started with powershell.exe's `-NoProfile` paramter. You can specify values for powershell.exe's `OutputFormat`, `ExecutionPolicy`, and `NonInteractive` paramters via parameters of the same name on the `Invoke-CPowerShell` function. Use the `Runtime` parameter to run `powershell.exe` version 2.

    To run a script, pass the path to the script with the `-FilePath` paramter. Pass any script arguments with the `ArgumentList` parameter. You must escape any parameters. They are passed to `powershell.exe` as-is.

    To run a script block, pass the script block with the `-ScriptBlock` parameter. Pass any script block arguments with the `ArgumentList` parameter. You must escape any parameters. They are passed to `powershell.exe` as-is.

    To run a command (Carbon 2.3.0 and later only), pass the command (i.e. string of PowerShell code) with the `Command` parameter. Any arguments to your command must be in the command itself. You must do any escaping.

    To run an encoded command (Carbon 2.3.0 and later only), pass the command (i.e. string of PowerShell code) with the `Command` parameter and the `-Encode` switch. `Invoke-CPowerShell` will base-64 encode your command for you and pass it to `powershell.exe` with its `-EncodedCommand` parameter.

    Beginning in Carbon 2.3.0, you can run scripts, commands, and encoded commands as another user. Pass that user's credentials with the `Credential` parameter.

    On 64-bit operating systems, use the `-x86` switch to run the new `powershell.exe` process under 32-bit PowerShell. If this switch is ommitted, `powershell.exe` will be run under a 64-bit PowerShell process (even if called from a 32-bit process). On 32-bit operating systems, this switch is ignored.

    The `Runtime` paramter controls what version of the .NET framework `powershell.exe` should use. Pass `v2.0` and `v4.0` to run under .NET versions 2.0 or 4.0, respectivey. Those frameworks must be installed. When running under PowerShell 2, `Invoke-CPowerShell` uses a temporary [activation configuration file](https://msdn.microsoft.com/en-us/library/ff361644(v=vs.100).aspx) to force PowerShell 2 to use .NET 4. When run under PowerShell 3 and later, `powershell.exe` is run with the `-Version` switch set to `2.0` to run `powershell.exe` under .NET 2.

    If using PowerShell v3.0 or later with a version of Carbon before 2.0, you can *only* run script blocks under a `v4.0` CLR.  PowerShell converts script blocks to an encoded command, and when running encoded commands, PowerShell doesn't allow the `-Version` parameter for running PowerShell under a different version.  To run code under a .NET 2.0 CLR from PowerShell 3, use the `FilePath` parameter to run a specfic script.

    .EXAMPLE
    Invoke-CPowerShell -ScriptBlock { $PSVersionTable }

    Runs a separate PowerShell process which matches the architecture of the operating system, returning the $PSVersionTable from that process.  This will fail under 32-bit PowerShell on a 64-bit operating system.

    .EXAMPLE
    Invoke-CPowerShell -ScriptBlock { $PSVersionTable } -x86

    Runs a 32-bit PowerShell process, return the $PSVersionTable from that process.

    .EXAMPLE
    Invoke-CPowerShell -ScriptBlock { $PSVersionTable } -Runtime v4.0

    Runs a separate PowerShell process under the v4.0 .NET CLR, returning the $PSVersionTable from that process.  Should return a CLRVersion of `4.0`.

    .EXAMPLE
    Invoke-CPowerShell -FilePath C:\Projects\Carbon\bin\Set-CDotNetConnectionString.ps1 -ArgumentList '-Name','myConn','-Value',"'data source=.\DevDB;Integrated Security=SSPI;'"

    Runs the `Set-CDotNetConnectionString.ps1` script with `ArgumentList` as arguments/parameters.

    Note that you have to double-quote any arguments with spaces.  Otherwise, the argument gets interpreted as multiple arguments.

    .EXAMPLE
    Invoke-CPowerShell -FilePath Get-PsVersionTable.ps1 -x86 -ExecutionPolicy RemoteSigned

    Shows how to run powershell.exe with a custom executin policy, in case the running of scripts is disabled.

    .EXAMPLE
    Invoke-CPowerShell -FilePath Get-PsVersionTable.ps1 -Credential $cred

    Demonstrates that you can run PowerShell scripts as a specific user with the `Credential` parameter.

    .EXAMPLE
    Invoke-CPowerShell -FilePath Get-PsVersionTable.ps1 -Credential $cred

    Demonstrates that you can run PowerShell scripts as a specific user with the `Credential` parameter.

    .EXAMPLE
    Invoke-CPowerShell -Command '$PSVersionTable'

    Demonstrates how to run a PowerShell command contained in a string. You are responsible for quoting things correctly.

    .EXAMPLE
    Invoke-CPowerShell -Command '$PSVersionTable' -Encode

    Demonstrates how to run a base-64 encode then run PowerShell command contained in a string. This runs the command using PowerShell's `-EncodedCommand` parameter. `Invoke-CPowerShell` does the base-64 encoding for you.

    .EXAMPLE
    Invoke-CPowerShell -Command '$env:USERNAME' -Credential $credential

    Demonstrates how to run a PowerShell command as another user. Uses `Start-Process` to launch `powershell.exe` as the user.
    #>
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock')]
        [ScriptBlock]
        # The script block to pass to `powershell.exe`.
        $ScriptBlock,

        [Parameter(Mandatory=$true,ParameterSetName='Command')]
        [object]
        # The command to run, as a string. Passed to PowerShell.exe as the value to the `-Command` parameter.
        #
        # Use the `-Encode` switch to avoid complicated quoting, and have `Invoke-CPowerShell` encode this command for you and pass it to powershell.exe's `-EncodedCommand parameter.
        #
        # This parameter was introduced in Carbon 2.3.0. In previous versions, this parameter was an alias to the `ScriptBlock` parameter. To maintain backwards-compatibility, if you pass a `ScriptBlock` to this parameter, `Invoke-CPowerShell` will run the script block as a script block. In the next major version of Carbon, this parameter will stop accepting `ScriptBlock` objects.
        $Command,

        [Parameter(Mandatory=$true,ParameterSetName='FilePath')]
        [string]
        # The script to run.
        $FilePath,

        [Parameter(ParameterSetName='Command')]
        [Parameter(ParameterSetName='ScriptBlock')]
        [Parameter(ParameterSetName='FilePath')]
        [object[]]
        [Alias('Args')]
        # Any arguments to pass to the script or command. These *are not* powershell.exe arguments. They are passed to powershell.exe as-is, so you'll need to escape them.
        $ArgumentList,

        [Parameter(ParameterSetName='Command')]
        [Switch]
        # Base-64 encode the command in `Command` and run it with powershell.exe's `-EncodedCommand` switch.
        #
        # This parameter was added in Carbon 2.3.0.
        $Encode,

        [string]
        # Determines how output from the PowerShel command is formatted. The value of this parameter is passed as-is to `powershell.exe` with its `-OutputFormat` paramter.
        $OutputFormat,

        [Microsoft.PowerShell.ExecutionPolicy]
        # The execution policy to use when running `powershell.exe`. Passed to `powershell.exe` with its `-ExecutionPolicy` parameter.
        $ExecutionPolicy,

        [Switch]
        # Run `powershell.exe` non-interactively. This passes the `-NonInteractive` switch to powershell.exe.
        $NonInteractive,

        [Switch]
        # Run the x86 (32-bit) version of PowerShell. if not provided, the version which matches the OS architecture is used, *regardless of the architecture of the currently running process*. I.e. this command is run under a 32-bit PowerShell on a 64-bit operating system, without this switch, `Invoke-Command` will start a 64-bit `powershell.exe`.
        $x86,

        [string]
        [ValidateSet('v2.0','v4.0')]
        # The CLR to use.  Must be one of `v2.0` or `v4.0`.  Default is the current PowerShell runtime.
        #
        # Beginning with Carbon 2.3.0, this parameter is ignored, since Carbon 2.0 and later only supports PowerShell 4 and you can't run PowerShell 4 under .NET 2.0.
        #
        # This parameter is OBSOLETE and will be removed in a future major version of Carbon.
        $Runtime,

        [Parameter(ParameterSetName='FilePath')]
        [Parameter(ParameterSetName='Command')]
        [pscredential]
        # Run `powershell.exe` as a specific user. Pass that user's credentials with this parameter.
        #
        # This parameter is new in Carbon 2.3.0.
        $Credential,

        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Core'
    }

    $powerShellv3Installed = Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3
    $currentRuntime = 'v{0}.0' -f [Environment]::Version.Major
    if( $powerShellv3Installed )
    {
        $currentRuntime = 'v4.0'
    }

    # Check that the selected runtime is installed.
    if( $PSBoundParameters.ContainsKey('Runtime') )
    {
        $runtimeInstalled = switch( $Runtime )
        {
            'v2.0' { Test-CDotNet -V2 }
            'v4.0' { Test-CDotNet -V4 -Full }
            default { Write-Error ('Unknown runtime value ''{0}''.' -f $Runtime) }
        }

        if( -not $runtimeInstalled )
        {
            Write-Error ('.NET {0} not found.' -f $Runtime)
            return
        }
    }


    if( -not $Runtime )
    {
        $Runtime = $currentRuntime
    }

    if(  $PSCmdlet.ParameterSetName -eq 'ScriptBlock' -and `
         $Host.Name -eq 'Windows PowerShell ISE Host' -and `
         $Runtime -eq 'v2.0' -and `
         $powerShellv3Installed )
    {
        Write-Error ('The PowerShell ISE v{0} can''t run script blocks under .NET {1}. Please run from the PowerShell console, or save your script block into a file and re-run Invoke-CPowerShell using the `FilePath` parameter.' -f `
                        $PSVersionTable.PSVersion,$Runtime)
        return
    }

    $comPlusAppConfigEnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
    $activationConfigDir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
    $activationConfigPath = Join-Path $activationConfigDir powershell.exe.activation_config
    $originalCOMAppConfigEnvVar = [Environment]::GetEnvironmentVariable( $comPlusAppConfigEnvVarName )
    if( -not $powerShellv3Installed -and $currentRuntime -ne $Runtime )
    {
        $null = New-Item -Path $activationConfigDir -ItemType Directory
        @"
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <startup useLegacyV2RuntimeActivationPolicy="true">
    <supportedRuntime version="{0}" />
  </startup>
</configuration>
"@ -f $Runtime | Out-File -FilePath $activationConfigPath -Encoding OEM
        Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $activationConfigDir -ForProcess
    }

    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }

    try
    {
        $psPath = Get-CPowerShellPath @params -NoWarn
        if( $ArgumentList -eq $null )
        {
            $ArgumentList = @()
        }

        $runningAScriptBlock = $PSCmdlet.ParameterSetName -eq 'ScriptBlock'
        if( $PSCmdlet.ParameterSetName -eq 'Command' -and $Command -is [scriptblock] )
        {
            Write-CWarningOnce -Message ('Passing a script block to the Command parameter is OBSOLETE and will be removed in a future major version of Carbon. Use the `ScriptBlock` parameter instead.')
            $ScriptBlock = $Command
            $runningAScriptBlock = $true
            if( $Credential )
            {
                Write-Error -Message ('It looks like you''re trying to run a script block as another user. `Start-Process` is used to start powershell.exe as that user. Start-Process requires all arguments to be strings. Converting a script block to a string automatically is unreliable. Please convert the script block to a command string or omit the Credential parameter.')
                return
            }
        }

        $powerShellArgs = Invoke-Command -ScriptBlock {
            if( $powerShellv3Installed -and $Runtime -eq 'v2.0' )
            {
                '-Version'
                '2.0'
            }

            # Can't run a script block in non-interactive mode. Because reasons.
            if( $NonInteractive -and -not $runningAScriptBlock )
            {
                '-NonInteractive'
            }

            '-NoProfile'

            if( $OutputFormat )
            {
                '-OutputFormat'
                $OutputFormat
            }

            if( $ExecutionPolicy -and $PSCmdlet.ParameterSetName -ne 'ScriptBlock' )
            {
                '-ExecutionPolicy'
                $ExecutionPolicy
            }
        }

        if( $runningAScriptBlock )
        {
            Write-Debug -Message ('& {0} {1} -Command {2} -Args {3}' -f $psPath,($powerShellArgs -join ' '),$ScriptBlock,($ArgumentList -join ' '))
            & $psPath $powerShellArgs -Command $ScriptBlock -Args $ArgumentList
            Write-Debug -Message ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'FilePath' )
        {
            if( $Credential )
            {
                Start-PowerShellProcess -CommandLine ('{0} -File "{1}" {2}' -f ($powerShellArgs -join " "),$FilePath,($ArgumentList -join " ")) -Credential $Credential
            }
            else
            {
                Write-Debug ('{0} {1} -File {2} {3}' -f $psPath,($powerShellArgs -join " "),$FilePath,($ArgumentList -join ' '))
                & $psPath $powerShellArgs -File $FilePath $ArgumentList
                Write-Debug ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
            }
        }
        else
        {
            if( $ArgumentList )
            {
                Write-Error -Message ('Can''t use ArgumentList parameter with Command parameter because powershell.exe''s -Command parameter doesn''t support it. Please embed the argument list in your command string, or convert your command to a script block and use the `ScriptBlock` parameter.')
                return
            }

            $argName = '-Command'
            if( $Encode )
            {
                $Command = ConvertTo-CBase64 -Value $Command -NoWarn
                $argName = '-EncodedCommand'
            }
            if( $Credential )
            {
                Start-PowerShellProcess -CommandLine ('{0} {1} {2}' -f ($powerShellArgs -join " "),$argName,$Command) -Credential $Credential
            }
            else
            {
                Write-Debug ('{0} {1} {2} {3}' -f $psPath,($powerShellArgs -join " "),$argName,$Command)
                & $psPath $powerShellArgs $argName $Command
                Write-Debug ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
            }
        }
    }
    finally
    {
        if( Test-Path -Path $activationConfigDir -PathType Leaf )
        {
            Remove-Item -Path $activationConfigDir -Recurse -Force
        }

        if( Test-Path -Path env:$comPlusAppConfigEnvVarName )
        {
            if( $originalCOMAppConfigEnvVar )
            {
                Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $originalCOMAppConfigEnvVar -ForProcess
            }
            else
            {
                Remove-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -ForProcess
            }
        }
    }
}



function New-CRsaKeyPair
{
    <#
    .SYNOPSIS
    Generates a public/private RSA key pair.

    .DESCRIPTION
    The `New-CRsaKeyPair` function uses the `certreq.exe` program to generate an RSA public/private key pair suitable
    for use in encrypting/decrypting CMS messages, credentials in DSC resources, etc. It uses the following `.inf` file
    as input (taken from the first example in the help for the `Protect-CmsMessage` cmdlet):

        [Version]
        Signature = "$Windows NT$"

        [Strings]
        szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
        szOID_DOCUMENT_ENCRYPTION = "1.3.6.1.4.1.311.80.1"

        [NewRequest]
        Subject = $Subject
        MachineKeySet = false
        KeyLength = $Length
        KeySpec = AT_KEYEXCHANGE
        HashAlgorithm = $Algorithm
        Exportable = true
        RequestType = Cert
        KeyUsage = "CERT_KEY_ENCIPHERMENT_KEY_USAGE | CERT_DATA_ENCIPHERMENT_KEY_USAGE"
        ValidityPeriod = Days
        ValidityPeriodUnits =

        [Extensions]
        %szOID_ENHANCED_KEY_USAGE% = "{{text}}%szOID_DOCUMENT_ENCRYPTION%"

    You can control the subject (via the `-Subject` parameter), key length (via the `-Length` parameter), the hash
    algorithm (via the `-Algorithm` parameter), and the expiration date of the keys (via the `-ValidTo` parameter). The
    subject is always required and should begin with "CN=". The length, hash algorithm, and expiration date are
    optional, and default to `4096`, `sha512`, and `12/31/9999`, respectively.

    The `certreq.exe` command stores the private key in the current user's `My` certificate store. This function exports
    that private key to a file and removes it from the current user's `My` store. The private key is protected with the
    password provided via the `-Password` parameter. If you don't provide a password, you will be prompted for one. To
    not protect the private key with a password, pass `$null` as the value of the `-Password` parameter.

    The public key is saved as an X509Certificate. The private key is saved as a PFX file. Both can be loaded by .NET's
    `X509Certificate` class. Returns `System.IO.FileInfo` objects for the public and private key, in that order.

    Before Carbon 2.1, this function used the `makecert.exe` and `pvk2pfx.exe` programs, from the Windows SDK. These
    programs prompt multiple times for the private key password, so if you're using a version before 2.1, you can't run
    this function non-interactively.

    .OUTPUTS
    System.IO.FileInfo

    .LINK
    Get-CCertificate

    .LINK
    Install-CCertificate

    .EXAMPLE
    New-CRsaKeyPair -Subject 'CN=MyName' -PublicKeyFile 'MyName.cer' -PrivateKeyFile 'MyName.pfx' -Password $secureString

    Demonstrates the minimal parameters needed to generate a key pair. The key will use a sha512 signing algorithm, have
    a length of 4096 bits, and expire on `12/31/9999`. The public key will be saved in the current directory as
    `MyName.cer`. The private key will be saved to the current directory as `MyName.pfx` and protected with password in
    `$secureString`.

    .EXAMPLE
    New-CRsaKeyPair -Subject 'CN=MyName' -PublicKeyFile 'MyName.cer' -PrivateKeyFile 'MyName.pfx' -Password $null

    Demonstrates how to save the private key unprotected (i.e. without a password). You must set the password to
    `$null`. This functionality was introduced in Carbon 2.1.

    .EXAMPLE
    New-CRsaKeyPair -Subject 'CN=MyName' -PublicKeyFile 'MyName.cer' -PrivateKeyFile 'MyName.pfx' -Algorithm 'sha1' -ValidTo (Get-Date -Year 2015 -Month 12 -Day 31) -Length 1024 -Password $secureString

    Demonstrates how to use all the parameters to create a truly customized key pair. The generated certificate will use
    the sha1 signing algorithm, becomes effective 1/1/2015, expires 12/31/2015, and is 1024 bits in length.
    #>
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidatePattern('^CN=')]
        [string]
        # The key's subject. Should be of the form `CN=Name,OU=Name,O=SuperMagicFunTime,ST=OR,C=US`. Only the `CN=Name`
        # part is required.
        $Subject,

        [ValidateSet('md5','sha1','sha256','sha384','sha512')]
        [string]
        # The signature algorithm. Default is `sha512`.
        $Algorithm = 'sha512',

        [Parameter(DontShow=$true)]
        [DateTime]
        # The date/time the keys will become valid. Default is now.
        #
        # This parameter was made obsolete in Carbon 2.1.
        $ValidFrom = (Get-Date),

        [DateTime]
        # The date/time the keys should expire. Default is `DateTime::MaxValue`.
        $ValidTo = ([DateTime]::MaxValue),

        [int]
        # The length, in bits, of the generated key length. Default is `4096`.
        $Length = 4096,

        [Parameter(DontShow=$true)]
        [ValidateSet('commercial','individual')]
        [string]
        # The signing authority of the certificate. Must be `commercial` (for certificates used by commercial software
        # publishers) or `individual`, for certificates used by individual software publishers. Default is `individual`.
        #
        # This parameter was made obsolete in Carbon 2.1.
        $Authority = 'individual',

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        # The file where the public key should be stored. Saved as an X509 certificate.
        $PublicKeyFile,

        [Parameter(Mandatory=$true,Position=2)]
        [string]
        # The file where the private key should be stored. The private key will be saved as an X509 certificate in PFX
        # format and will include the public key.
        $PrivateKeyFile,

        [securestring]
        # The password for the private key. If one is not provided, you will be prompted for one. Pass `$null` to not
        # protect your private key with a password.
        #
        # This parameter was introduced in Carbon 2.1.
        $Password,

        [Switch]
        # Overwrites `PublicKeyFile` and/or `PrivateKeyFile`, if they exist.
        $Force,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
    }

    if( $PSBoundParameters.ContainsKey('ValidFrom') )
    {
        Write-CWarningOnce -Message ('New-CRsaKeyPair: The -ValidFrom parameter is obsolete and will be removed in a future version of Carbon. Please remove usages of this parameter.')
    }

    if( $PSBoundParameters.ContainsKey('Authority') )
    {
        Write-CWarningOnce -Message ('New-CRsaKeyPair: The -Authority parameter is obsolete and will be removed in a future version of Carbon. Please remove usages of this parameter.')
    }

    function Resolve-KeyPath
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Path
        )

        Set-StrictMode -Version 'Latest'

        $Path = Resolve-CFullPath -Path $Path -NoWarn

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
                New-Item -Path $root -ItemType 'Directory' -Force | Out-Null
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

    $tempDir = '{0}-{1}' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null
    $tempInfFile = Join-Path -Path $tempDir -ChildPath 'temp.inf'

    try
    {
        $certReqPath = Get-Command -Name 'certreq.exe' | Select-Object -ExpandProperty 'Path'
        if( -not $certReqPath )
        {
            return
        }

        # Taken from example 1 of the Protect-CmsMessage help topic.
        [int]$daysValid = [Math]::Floor(($ValidTo - $ValidFrom).TotalDays)
        [int]$MaxDaysValid = [Math]::Floor(([DateTime]::MaxValue - [DateTime]::UtcNow).TotalDays)
        Write-Debug -Message ('Days Valid:              {0}' -f $daysValid)
        Write-Debug -Message ('Max Days Valid:          {0}' -f $MaxDaysValid)
        if( $daysValid -gt $MaxDaysValid )
        {
            Write-Debug -Message ('Adjusted Days Valid:     {0}' -f $daysValid)
            $daysValid = $MaxDaysValid
        }
        (@'
[Version]
Signature = "$Windows NT$"

[Strings]
szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
szOID_DOCUMENT_ENCRYPTION = "1.3.6.1.4.1.311.80.1"

[NewRequest]
Subject = "{0}"
MachineKeySet = false
KeyLength = {1}
KeySpec = AT_KEYEXCHANGE
HashAlgorithm = {2}
Exportable = true
RequestType = Cert
KeyUsage = "CERT_KEY_ENCIPHERMENT_KEY_USAGE | CERT_DATA_ENCIPHERMENT_KEY_USAGE"
ValidityPeriod = Days
ValidityPeriodUnits = {3}

[Extensions]
%szOID_ENHANCED_KEY_USAGE% = "{{text}}%szOID_DOCUMENT_ENCRYPTION%"
'@ -f $Subject,$Length,$Algorithm,$daysValid) | Set-Content -Path $tempInfFile

        Get-Content -Raw -Path $tempInfFile | Write-Debug

        $output = & $certReqPath -q -new $tempInfFile $PublicKeyFile
        if( $LASTEXITCODE -or -not (Test-Path -Path $PublicKeyFile -PathType Leaf) )
        {
            Write-Error ('Failed to create public/private key pair:{0}{1}' -f ([Environment]::NewLine),($output -join ([Environment]::NewLine)))
            return
        }
        else
        {
            $output | Write-Debug
        }

        $publicKey = Get-CCertificate -Path $PublicKeyFile -NoWarn
        if( -not $publicKey )
        {
            Write-Error ('Failed to load public key ''{0}'':{1}{2}' -f $PublicKeyFile,([Environment]::NewLine),($output -join ([Environment]::NewLine)))
            return
        }

        $privateCertPath = Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $publicKey.Thumbprint
        if( -not (Test-Path -Path $privateCertPath -PathType Leaf) )
        {
            Write-Error -Message ('Private key ''{0}'' not found. Did certreq.exe fail to install the private key there?' -f $privateCertPath)
            return
        }

        try
        {
            $privateCert = Get-Item -Path $privateCertPath
            if( -not $privateCert.HasPrivateKey )
            {
                Write-Error -Message ('Certificate ''{0}'' doesn''t have a private key.' -f $privateCertPath)
                return
            }

            if( -not $PSBoundParameters.ContainsKey('Password') )
            {
                $Password = Read-Host -Prompt 'Enter private key password' -AsSecureString
            }

            $privateCertBytes = $privateCert.Export( 'PFX', $Password )
            [IO.File]::WriteAllBytes( $PrivateKeyFile, $privateCertBytes )

            Get-Item $PublicKeyFile
            Get-Item $PrivateKeyFile
        }
        finally
        {
            Remove-Item -Path $privateCertPath
        }
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse
    }
}


filter Protect-CString
{
    <#
    .SYNOPSIS
    Encrypts a string.

    .DESCRIPTION
    The `Protect-CString` function encrypts a string using the Data Protection API (DPAPI), RSA, or AES. In Carbon 2.3.0 or earlier, the plaintext string to encrypt is passed to the `String` parameter. Beginning in Carbon 2.4.0, you can also pass a `SecureString`. When encrypting a `SecureString`, it is converted to an array of bytes, encrypted, then the array of bytes is cleared from memory (i.e. the plaintext version of the `SecureString` is only in memory long enough to encrypt it).

    ##  DPAPI

    The DPAPI hides the encryptiong/decryption keys from you. As such, anything encrpted with via DPAPI can only be decrypted on the same computer it was encrypted on. Use the `ForUser` switch so that only the user who encrypted can decrypt. Use the `ForComputer` switch so that any user who can log into the computer can decrypt. To encrypt as a specific user on the local computer, pass that user's credentials with the `Credential` parameter. (Note this method doesn't work over PowerShell remoting.)

    ## RSA

    RSA is an assymetric encryption/decryption algorithm, which requires a public/private key pair. The secret is encrypted with the public key, and can only be decrypted with the corresponding private key. The secret being encrypted can't be larger than the RSA key pair's size/length, usually 1024, 2048, or 4096 bits (128, 256, and 512 bytes, respectively). `Protect-CString` encrypts with .NET's `System.Security.Cryptography.RSACryptoServiceProvider` class.

    You can specify the public key in three ways:

     * with a `System.Security.Cryptography.X509Certificates.X509Certificate2` object, via the `Certificate` parameter
     * with a certificate in one of the Windows certificate stores, passing its unique thumbprint via the `Thumbprint` parameter, or via the `PublicKeyPath` parameter cn be certificat provider path, e.g. it starts with `cert:\`.
     * with a X509 certificate file, via the `PublicKeyPath` parameter

    You can generate an RSA public/private key pair with the `New-CRsaKeyPair` function.

    ## AES

    AES is a symmetric encryption/decryption algorithm. You supply a 16-, 24-, or 32-byte key/password/passphrase with the `Key` parameter, and that key is used to encrypt. There is no limit on the size of the data you want to encrypt. `Protect-CString` encrypts with .NET's `System.Security.Cryptography.AesCryptoServiceProvider` class.

    Symmetric encryption requires a random, unique initialization vector (i.e. IV) everytime you encrypt something. `Protect-CString` generates one for you. This IV must be known to decrypt the secret, so it is pre-pendeded to the encrypted text.

    This code demonstrates how to generate a key:

        $key = (New-Object 'Security.Cryptography.AesManaged').Key

    You can save this key as a string by encoding it as a base-64 string:

        $base64EncodedKey = [Convert]::ToBase64String($key)

    If you base-64 encode your string, it must be converted back to bytes before passing it to `Protect-CString`.

        Protect-CString -String 'the secret sauce' -Key ([Convert]::FromBase64String($base64EncodedKey))

    The ability to encrypt with AES was added in Carbon 2.3.0.

    .LINK
    New-CRsaKeyPair

    .LINK
    Unprotect-CString

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.protecteddata.aspx

    .EXAMPLE
    Protect-CString -String 'TheStringIWantToEncrypt' -ForUser | Out-File MySecret.txt

    Encrypts the given string and saves the encrypted string into MySecret.txt.  Only the user who encrypts the string can unencrypt it.

    .EXAMPLE
    Protect-CString -String $credential.Password -ForUser | Out-File MySecret.txt

    Demonstrates that `Protect-CString` can encrypt a `SecureString`. This functionality was added in Carbon 2.4.0.

    .EXAMPLE
    $cipherText = Protect-CString -String "MySuperSecretIdentity" -ForComputer

    Encrypts the given string and stores the value in $cipherText.  Because the encryption scope is set to LocalMachine, any user logged onto the local computer can decrypt `$cipherText`.

    .EXAMPLE
    Protect-CString -String 's0000p33333r s33333cr33333t' -Credential (Get-Credential 'builduser')

    Demonstrates how to use `Protect-CString` to encrypt a secret as a specific user. This is useful for situation where a secret needs to be encrypted by a user other than the user running `Protect-CString`. Encrypting as a specific user won't work over PowerShell remoting.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -Certificate $myCert

    Demonstrates how to encrypt a secret using RSA with a `System.Security.Cryptography.X509Certificates.X509Certificate2` object. You're responsible for creating/loading it. The `New-CRsaKeyPair` function will create a key pair for you, if you've got a Windows SDK installed.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -Thumbprint '44A7C27F3353BC53F82318C14490D7E2500B6D9E'

    Demonstrates how to encrypt a secret using RSA with a certificate in one of the Windows certificate stores. All local machine and user stores are searched.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -PublicKeyPath 'C:\Projects\Security\publickey.cer'

    Demonstrates how to encrypt a secret using RSA with a certificate file. The file must be loadable by the `System.Security.Cryptography.X509Certificates.X509Certificate` class.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -PublicKeyPath 'cert:\LocalMachine\My\44A7C27F3353BC53F82318C14490D7E2500B6D9E'

    Demonstrates how to encrypt a secret using RSA with a certificate in the store, giving its exact path.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -Key 'gT4XPfvcJmHkQ5tYjY3fNgi7uwG4FB9j'

    Demonstrates how to encrypt a secret with a key, password, or passphrase. In this case, we are encrypting with a plaintext password. This functionality was added in Carbon 2.3.0.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -Key (Read-Host -Prompt 'Enter password (must be 16, 24, or 32 characters long):' -AsSecureString)

    Demonstrates that you can use a `SecureString` as the key, password, or passphrase. This functionality was added in Carbon 2.3.0.

    .EXAMPLE
    Protect-CString -String 'the secret sauce' -Key ([byte[]]@(163,163,185,174,205,55,157,219,121,146,251,116,43,203,63,38,73,154,230,112,82,112,151,29,189,135,254,187,164,104,45,30))

    Demonstrates that you can use an array of bytes as the key, password, or passphrase. This functionality was added in Carbon 2.3.0.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        # The string to encrypt. Any non-string object you pass will be converted to a string before encrypting by calling the object's `ToString` method.
        #
        # Beginning in Carbon 2.4.0, this can also be a `SecureString` object. The `SecureString` is converted to an array of bytes, the bytes are encrypted, then the plaintext bytes are cleared from memory (i.e. the plaintext password is in memory for the amount of time it takes to encrypt it).
        [Object]$String,

        [Parameter(Mandatory, ParameterSetName='DPAPICurrentUser')]
        # Encrypts for the current user so that only he can decrypt.
        [switch]$ForUser,

        [Parameter(Mandatory, ParameterSetName='DPAPILocalMachine')]
        # Encrypts for the current computer so that any user logged into the computer can decrypt.
        [switch]$ForComputer,

        [Parameter(Mandatory, ParameterSetName='DPAPIForUser')]
        # Encrypts for a specific user.
        [pscredential]$Credential,

        [Parameter(Mandatory, ParameterSetName='RSAByCertificate')]
        # The public key to use for encrypting.
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(Mandatory, ParameterSetName='RSAByThumbprint')]
        # The thumbprint of the certificate, found in one of the Windows certificate stores, to use when encrypting. All certificate stores are searched.
        [String]$Thumbprint,

        [Parameter(Mandatory, ParameterSetName='RSAByPath')]
        # The path to the public key to use for encrypting. Must be to an `X509Certificate2` object.
        [String]$PublicKeyPath,

        [Parameter(ParameterSetName='RSAByCertificate')]
        [Parameter(ParameterSetName='RSAByThumbprint')]
        [Parameter(ParameterSetName='RSAByPath')]
        # If true, uses Direct Encryption (PKCS#1 v1.5) padding. Otherwise (the default), uses OAEP (PKCS#1 v2) padding. See [Encrypt](http://msdn.microsoft.com/en-us/library/system.security.cryptography.rsacryptoserviceprovider.encrypt(v=vs.110).aspx) for information.
        [switch]$UseDirectEncryptionPadding,

        [Parameter(Mandatory, ParameterSetName='Symmetric')]
        # The key to use to encrypt the secret. Can be a `SecureString`, a `String`, or an array of bytes. Must be 16, 24, or 32 characters/bytes in length.
        [Object]$Key,

        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
    }

    Add-Type -AssemblyName 'System.Security'

    if( $String -is [System.Security.SecureString] )
    {
        $stringBytes = [Carbon.Security.SecureStringConverter]::ToBytes($String)
    }
    else
    {
        $stringBytes = [Text.Encoding]::UTF8.GetBytes( $String.ToString() )
    }

    try
    {

        if( $PSCmdlet.ParameterSetName -like 'DPAPI*' )
        {
            if( $PSCmdlet.ParameterSetName -eq 'DPAPIForUser' )
            {
                $protectStringPath = Join-Path -Path $CarbonBinDir -ChildPath 'Protect-String.ps1' -Resolve
                $encodedString = Protect-CString -String $String -ForComputer -NoWarn
                $argumentList = '-ProtectedString {0}' -f $encodedString
                Invoke-CPowerShell -ExecutionPolicy 'ByPass' `
                                   -NonInteractive `
                                   -FilePath $protectStringPath `
                                   -ArgumentList $argumentList `
                                   -Credential $Credential `
                                   -NoWarn |
                    Select-Object -First 1
                return
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
                $Certificate = Get-Item -Path ('cert:\*\*\{0}' -f $Thumbprint) | Select-Object -First 1
                if( -not $Certificate )
                {
                    Write-Error ('Certificate with thumbprint ''{0}'' not found.' -f $Thumbprint)
                    return
                }
            }
            elseif( $PSCmdlet.ParameterSetName -eq 'RSAByPath' )
            {
                $Certificate = Get-CCertificate -Path $PublicKeyPath -NoWarn
                if( -not $Certificate )
                {
                    return
                }
            }

            $rsaKey = $Certificate.PublicKey.Key
            if( -not $rsaKey.GetType().IsSubclassOf([Security.Cryptography.RSA]) )
            {
                Write-Error ('Certificate ''{0}'' (''{1}'') is not an RSA key. Found a public key of type ''{2}'', but expected type ''{3}''.' -f $Certificate.Subject,$Certificate.Thumbprint,$rsaKey.GetType().FullName,[Security.Cryptography.RSACryptoServiceProvider].FullName)
                return
            }

            $padding = [Security.Cryptography.RSAEncryptionPadding]::OaepSHA1
            if( $UseDirectEncryptionPadding )
            {
                $padding = [Security.Cryptography.RSAEncryptionPadding]::Pkcs1
            }
            try
            {
                $encryptedBytes = $rsaKey.Encrypt($stringBytes, $padding)
            }
            catch
            {
                if( $_.Exception.Message -match 'Bad Length\.' -or $_.Exception.Message -match 'The parameter is incorrect\.')
                {
                    [int]$maxLengthGuess = ($rsaKey.KeySize - (2 * 160 - 2)) / 8
                    Write-Error -Message ('Failed to encrypt. String is longer than maximum length allowed by RSA and your key size, which is {0} bits. We estimate the maximum string size you can encrypt with certificate ''{1}'' ({2}) is {3} bytes. You may still get errors when you attempt to decrypt a string within a few bytes of this estimated maximum.' -f $rsaKey.KeySize,$Certificate.Subject,$Certificate.Thumbprint,$maxLengthGuess)
                    return
                }
                else
                {
                    Write-Error -Exception $_.Exception
                    return
                }
            }
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'Symmetric' )
        {
            $Key = ConvertTo-Key -InputObject $Key -From 'Protect-CString'
            if( -not $Key )
            {
                return
            }

            $aes = [Security.Cryptography.Aes]::Create()
            try
            {
                $aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
                $aes.KeySize = $Key.Length * 8
                $aes.Key = $Key

                $memoryStream = New-Object 'IO.MemoryStream'
                try
                {
                    $cryptoStream = New-Object 'Security.Cryptography.CryptoStream' $memoryStream,$aes.CreateEncryptor(),([Security.Cryptography.CryptoStreamMode]::Write)
                    try
                    {
                        $cryptoStream.Write($stringBytes,0,$stringBytes.Length)
                    }
                    finally
                    {
                        $cryptoStream.Dispose()
                    }

                    $encryptedBytes = Invoke-Command -ScriptBlock {
                                                                     $aes.IV
                                                                     $memoryStream.ToArray()
                                                                  }
                }
                finally
                {
                    $memoryStream.Dispose()
                }
            }
            finally
            {
                $aes.Dispose()
            }
        }

        return [Convert]::ToBase64String( $encryptedBytes )
    }
    finally
    {
        $stringBytes.Clear()
    }
}


function Remove-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Removes a value from a registry key, if it exists.

    .DESCRIPTION
    If the given key doesn't exist, nothing happens.

    .EXAMPLE
    Remove-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'InstallPath'

    Removes the `InstallPath` value from the `hklm:\Software\Carbon\Test` registry key.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be removed.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value to remove.
        $Name,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Registry'
    }

    if( (Test-CRegistryKeyValue -Path $Path -Name $Name -NoWarn) )
    {
        if( $pscmdlet.ShouldProcess( ('Item: {0} Property: {1}' -f $Path,$Name), 'Remove Property' ) )
        {
            Remove-ItemProperty -Path $Path -Name $Name
        }
    }
}


function Remove-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Removes an SSL certificate binding.

    .DESCRIPTION
    Uses the netsh command line application to remove an SSL certificate binding for an IP/port combination.  If the binding doesn't exist, nothing is changed.

    .EXAMPLE
    > Remove-CSslCertificateBinding -IPAddress '45.72.89.57' -Port 443

    Removes the SSL certificate bound to IP 45.72.89.57 on port 443.

    .EXAMPLE
    > Remove-CSslCertificateBinding

    Removes the default SSL certificate from port 443.  The default certificate is bound to all IP addresses.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [IPAddress]
        # The IP address whose binding to remove.  Default is all IP addresses.
        $IPAddress = '0.0.0.0',

        [UInt16]
        # The port of the binding to remove.  Default is port 443.
        $Port = 443,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Windows.HttpServer'
    }

    if( -not (Test-CSslCertificateBinding -IPAddress $IPAddress -Port $Port -NoWarn) )
    {
        return
    }

    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    Invoke-ConsoleCommand -Target $ipPort `
                          -Action "removing SSL certificate binding" `
                          -ScriptBlock { netsh http delete sslcert ipPort=$ipPort }
}


function Resolve-CFullPath
{
    <#
    .SYNOPSIS
    Converts a relative path to an absolute path.

    .DESCRIPTION
    Unlike `Resolve-Path`, this function does not check whether the path exists.  It just converts relative paths to absolute paths.

    Unrooted paths (e.g. `..\..\See\I\Do\Not\Have\A\Root`) are first joined with the current directory (as returned by `Get-Location`).

    .EXAMPLE
    Resolve-CFullPath -Path 'C:\Projects\Carbon\Test\..\Carbon\FileSystem.ps1'

    Returns `C:\Projects\Carbon\Carbon\FileSystem.ps1`.

    .EXAMPLE
    Resolve-CFullPath -Path 'C:\Projects\Carbon\..\I\Do\Not\Exist'

    Returns `C:\Projects\I\Do\Not\Exist`.

    .EXAMPLE
    Resolve-CFullPath -Path ..\..\Foo\..\Bar

    Because the `Path` isn't rooted, joins `Path` with the current directory (as returned by `Get-Location`), and returns the full path.  If the current directory is `C:\Projects\Carbon`, returns `C:\Bar`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to resolve.  Must be rooted, i.e. have a drive at the beginning.
        $Path,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Core'
    }

    if( -not ( [System.IO.Path]::IsPathRooted($Path) ) )
    {
        $Path = Join-Path (Get-Location) $Path
    }
    return [IO.Path]::GetFullPath($Path)
}

Set-Alias -Name 'ConvertTo-FullPath' -Value 'Resolve-CFullPath'



# When Resolve-CIdentity gets moved to a new module, this should go with it.
Add-CTypeData -TypeName 'System.DirectoryServices.AccountManagement.Principal' `
              -MemberName 'ConnectedServer' `
              -MemberType ScriptProperty `
              -Value { $this.Context.ConnectedServer }

function Resolve-CIdentity
{
    <#
    .SYNOPSIS
    Gets domain, name, type, and SID information about a user or group.

    .DESCRIPTION
    The `Resolve-CIdentity` function takes an identity name or security identifier (SID) and gets its canonical representation. It returns a `Carbon.Identity` object, which contains the following information about the identity:

     * Domain - the domain the user was found in
     * FullName - the users full name, e.g. Domain\Name
     * Name - the user's username or the group's name
     * Type - the Sid type.
     * Sid - the account's security identifier as a `System.Security.Principal.SecurityIdentifier` object.

    The common name for an account is not always the canonical name used by the operating system.  For example, the local Administrators group is actually called BUILTIN\Administrators.  This function uses the `LookupAccountName` and `LookupAccountSid` Windows functions to resolve an account name or security identifier into its domain, name, full name, SID, and SID type.

    You may pass a `System.Security.Principal.SecurityIdentifer`, a SID in SDDL form (as a string), or a SID in binary form (a byte array) as the value to the `SID` parameter. You'll get an error and nothing returned if the SDDL or byte array SID are invalid.

    If the name or security identifier doesn't represent an actual user or group, an error is written and nothing is returned.

    .LINK
    Test-CIdentity

    .LINK
    Resolve-CIdentityName

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx

    .LINK
    ConvertTo-CSecurityIdentifier

    .LINK
    Resolve-CIdentityName

    .LINK
    Test-CIdentity

    .OUTPUTS
    Carbon.Identity.

    .EXAMPLE
    Resolve-CIdentity -Name 'Administrators'

    Returns an object representing the `Administrators` group.

    .EXAMPLE
    Resolve-CIdentity -SID 'S-1-5-21-2678556459-1010642102-471947008-1017'

    Demonstrates how to use a SID in SDDL form to convert a SID into an identity.

    .EXAMPLE
    Resolve-CIdentity -SID (New-Object 'Security.Principal.SecurityIdentifier' 'S-1-5-21-2678556459-1010642102-471947008-1017')

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter.

    .EXAMPLE
    Resolve-CIdentity -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='ByName')]
    [OutputType([Carbon.Identity])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByName',Position=0)]
        [string]
        # The name of the identity to return.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='BySid')]
        # The SID of the identity to return. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
        $SID,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -Command 'Resolve-CIdentity' -ModuleName 'Carbon.Accounts' -NoWarn:$NoWarn

    if( $PSCmdlet.ParameterSetName -eq 'BySid' )
    {
        $SID = ConvertTo-CSecurityIdentifier -SID $SID -NoWarn
        if( -not $SID )
        {
            return
        }

        $id = [Carbon.Identity]::FindBySid( $SID )
        if( -not $id )
        {
            Write-Error ('Identity ''{0}'' not found.' -f $SID) -ErrorAction $ErrorActionPreference
        }
        return $id
    }

    if( -not (Test-CIdentity -Name $Name -NoWarn) )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
        return
    }

    return [Carbon.Identity]::FindByName( $Name )
}


function Resolve-CNetPath
{
    <#
    .SYNOPSIS
    OBSOLETE. Will be removed in a future major version of Carbon.

    .DESCRIPTION
    OBSOLETE. Will be removed in a future major version of Carbon.

    .EXAMPLE
    Write-Error 'OBSOLETE. Will be removed in a future major version of Carbon.'

    Demonstates that `Resolve-CNetPath` is obsolete and you shouldn't use it.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name

    $netCmd = Get-Command -CommandType Application -Name net.exe* |
                Where-Object { $_.Name -eq 'net.exe' }
    if( $netCmd )
    {
        return $netCmd.Definition
    }

    $netPath = Join-Path $env:WINDIR system32\net.exe
    if( (Test-Path -Path $netPath -PathType Leaf) )
    {
        return $netPath
    }

    Write-Error 'net.exe command not found.'
    return $null
}



function Resolve-WindowsFeatureName
{
    <#
    .SYNOPSIS
    INTERNAL.  DO NOT USE.  Converts a Carbon-specific, common Windows feature name, into the feature name used on the current computer.

    .DESCRIPTION
    Windows feature names change between versions.  This function converts a Carbon-specific name into feature names used on the current computer's version of Windows.

    **This function is not available on Windows 8/2012.**

    .EXAMPLE
    Resolve-WindowsFeatureNames -Name 'Iis','Msmq'

    Returns `'IIS-WebServer','MSMQ-Server'` if running Windows 7/Windows 2008 R2, or `'Web-WebServer','MSMQ-Server'` if on Windows 2008.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The Carbon feature names to convert to Windows-specific feature names.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name

    Assert-WindowsFeatureFunctionsSupported -WarningAction SilentlyContinue | Out-Null

    $featureMap = @{
                        Iis = 'Web-WebServer';
                        IisHttpRedirection = 'Web-Http-Redirect';
                        Msmq = 'MSMQ-Server';
                        MsmqHttpSupport = 'MSMQ-HTTP-Support';
                        MsmqActiveDirectoryIntegration = 'MSMQ-Directory';
                   }

    if( $useOCSetup )
    {
        $featureMap = @{
                            Iis = 'IIS-WebServer';
                            IisHttpRedirection = 'IIS-HttpRedirect';
                            Msmq = 'MSMQ-Server';
                            MsmqHttpSupport = 'MSMQ-HTTP';
                            MsmqActiveDirectoryIntegration = 'MSMQ-ADIntegration';
                       }
    }

    $Name |
        Where-Object { $featureMap.ContainsKey( $_ ) } |
        ForEach-Object { $featureMap[$_] }

}



function Set-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Sets a value in a registry key.

    .DESCRIPTION
    The `Set-CRegistryKeyValue` function sets the value of a registry key. If the key doesn't exist, it is created first. Uses PowerShell's `New-ItemPropery` to create the value if doesn't exist. Otherwise uses `Set-ItemProperty` to set the value.

    `DWord` and `QWord` values are stored in the registry as unsigned integers. If you pass a negative integer for the `DWord` and `QWord` parameters, PowerShell will convert it to an unsigned integer before storing. You won't get the same negative number back.

    To store integer values greater than `[Int32]::MaxValue` or `[Int64]::MaxValue`, use the `UDWord` and `UQWord` parameters, respectively, which are unsigned integers. These parameters were in Carbon 2.0.

    In versions of Carbon before 2.0, you'll need to convert these large unsigned integers into signed integers. You can't do this with casting. Casting preservers the value, not the bits underneath. You need to re-interpret the bits. Here's some sample code:

        # Carbon 1.0
        $bytes = [BitConverter]::GetBytes( $unsignedInt )
        $signedInt = [BitConverter]::ToInt32( $bytes, 0 )  # Or use `ToInt64` if you're working with 64-bit/QWord values
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -DWord $signedInt

        # Carbon 2.0
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -UDWord $unsignedInt

    .LINK
    Get-CRegistryKeyValue

    .LINK
    Test-CRegistryKeyValue

    .EXAMPLE
    Set-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name Status -String foobar

    Creates the `Status` string value under the `hklm:\Software\Carbon\Test` key and sets its value to `foobar`.

    .EXAMPLE
    Set-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name ComputerName -String '%ComputerName%' -Expand

    Creates an expandable string.  When retrieving this value, environment variables will be expanded.

    .EXAMPLE
    Set-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name Movies -String ('Signs','Star Wars','Raiders of the Lost Ark')

    Sets a multi-string (i.e. array) value.

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'SomeBytes' -Binary ([byte[]]@( 1, 2, 3, 4))

    Sets a binary value (i.e. `REG_BINARY`).

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnInt' -DWord 48043

    Sets a binary value (i.e. `REG_DWORD`).

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnInt64' -QWord 9223372036854775807

    Sets a binary value (i.e. `REG_QWORD`).

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnUnsignedInt' -UDWord [uint32]::MaxValue

    Demonstrates how to set a registry value with an unsigned integer or an integer bigger than `[int]::MaxValue`.

    The `UDWord` parameter was added in Carbon 2.0. In earlier versions of Carbon, you have to convert the unsigned int's bits to a signed integer:

        $bytes = [BitConverter]::GetBytes( $unsignedInt )
        $signedInt = [BitConverter]::ToInt32( $bytes, 0 )
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -DWord $signedInt

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnUnsignedInt64' -UQWord [uint64]::MaxValue

    Demonstrates how to set a registry value with an unsigned 64-bit integer or a 64-bit integer bigger than `[long]::MaxValue`.

    The `UQWord parameter was added in Carbon 2.0. In earlier versions of Carbon, you have to convert the unsigned int's bits to a signed integer:

        $bytes = [BitConverter]::GetBytes( $unsignedInt )
        $signedInt = [BitConverter]::ToInt64( $bytes, 0 )
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -DWord $signedInt

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'UsedToBeAStringNowShouldBeDWord' -DWord 1 -Force

    Uses the `Force` parameter to delete the existing `UsedToBeAStringNowShouldBeDWord` before re-creating it.  This flag is useful if you need to change the type of a registry value.
    #>
    [CmdletBinding(SupportsShouldPRocess=$true,DefaultParameterSetName='String')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='String')]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        # The value's data.  Creates a value for holding string data (i.e. `REG_SZ`). If `$null`, the value will be saved as an empty string.
        $String,

        [Parameter(ParameterSetName='String')]
        [Switch]
        # The string should be expanded when retrieved.  Creates a value for holding expanded string data (i.e. `REG_EXPAND_SZ`).
        $Expand,

        [Parameter(Mandatory=$true,ParameterSetName='Binary')]
        [byte[]]
        # The value's data.  Creates a value for holding binary data (i.e. `REG_BINARY`).
        $Binary,

        [Parameter(Mandatory=$true,ParameterSetName='DWord')]
        [int]
        # The value's data.  Creates a value for holding a 32-bit integer (i.e. `REG_DWORD`).
        $DWord,

        [Parameter(Mandatory=$true,ParameterSetName='DWordAsUnsignedInt')]
        [uint32]
        # The value's data as an unsigned integer (i.e. `UInt32`).  Creates a value for holding a 32-bit integer (i.e. `REG_DWORD`).
        $UDWord,

        [Parameter(Mandatory=$true,ParameterSetName='QWord')]
        [long]
        # The value's data.  Creates a value for holding a 64-bit integer (i.e. `REG_QWORD`).
        $QWord,

        [Parameter(Mandatory=$true,ParameterSetName='QWordAsUnsignedInt')]
        [uint64]
        # The value's data as an unsigned long (i.e. `UInt64`).  Creates a value for holding a 64-bit integer (i.e. `REG_QWORD`).
        $UQWord,

        [Parameter(Mandatory=$true,ParameterSetName='MultiString')]
        [string[]]
        # The value's data.  Creates a value for holding an array of strings (i.e. `REG_MULTI_SZ`).
        $Strings,

        [Switch]
        # Removes and re-creates the value.  Useful for changing a value's type.
        $Force,

        [Parameter(DontShow=$true)]
        [Switch]
        # OBSOLETE. Will be removed in a future version of Carbon.
        $Quiet,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Registry'
    }

    if( $PSBoundParameters.ContainsKey('Quiet') )
    {
        Write-CWarningOnce ('Set-CRegistryKeyValue''s -Quiet switch is obsolete and will be removed in a future version of Carbon. Please remove usages.')
    }

    $value = $null
    $type = $pscmdlet.ParameterSetName
    switch -Exact ( $pscmdlet.ParameterSetName )
    {
        'String'
        {
            $value = $String
            if( $Expand )
            {
                $type = 'ExpandString'
            }
        }
        'Binary' { $value = $Binary }
        'DWord' { $value = $DWord }
        'QWord' { $value = $QWord }
        'DWordAsUnsignedInt'
        {
            $value = $UDWord
            $type = 'DWord'
        }
        'QWordAsUnsignedInt'
        {
            $value = $UQWord
            $type = 'QWord'
        }
        'MultiString' { $value = $Strings }
    }

    Install-CRegistryKey -Path $Path -NoWarn

    if( $Force )
    {
        Remove-CRegistryKeyValue -Path $Path -Name $Name -NoWarn
    }

    if( Test-CRegistryKeyValue -Path $Path -Name $Name -NoWarn )
    {
        $currentValue = Get-CRegistryKeyValue -Path $Path -Name $Name -NoWarn
        if( $currentValue -ne $value )
        {
            Write-Verbose -Message ("[{0}@{1}] {2} -> {3}'" -f $Path,$Name,$currentValue,$value)
            Set-ItemProperty -Path $Path -Name $Name -Value $value
        }
    }
    else
    {
        Write-Verbose -Message ("[{0}@{1}]  -> {2}'" -f $Path,$Name,$value)
        $null = New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType $type
    }
}


function Set-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Sets an SSL certificate binding for a given IP/port.

    .DESCRIPTION
    Uses the netsh command line application to set the certificate for an IP address and port.  If a binding already exists for the IP/port, it is removed, and the new binding is created.

    Beginning with Carbon 2.0, returns a `Carbon.Certificates.SslCertificateBinding` object for the binding that was set.

    .OUTPUTS
    Carbon.Certificates.SslCertificateBinding.

    .EXAMPLE
    Set-CSslCertificateBinding -IPAddress 43.27.89.54 -Port 443 -ApplicationID 88d1f8da-aeb5-40a2-a5e5-0e6107825df7 -Thumbprint 4789073458907345907434789073458907345907

    Configures the computer to use the 478907345890734590743 certificate on IP 43.27.89.54, port 443.

    .EXAMPLE
    Set-CSslCertificateBinding -ApplicationID 88d1f8da-aeb5-40a2-a5e5-0e6107825df7 -Thumbprint 4789073458907345907434789073458907345907

    Configures the compute to use the 478907345890734590743 certificate as the default certificate on all IP addresses, port 443.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Carbon.Certificates.SslCertificateBinding])]
    param(
        [IPAddress]
        # The IP address for the binding.  Defaults to all IP addresses.
        $IPAddress = '0.0.0.0',

        [UInt16]
        # The port for the binding.  Defaults to 443.
        $Port = 443,

        [Parameter(Mandatory=$true)]
        [Guid]
        # A unique ID representing the application using the binding.  Create your own.
        $ApplicationID,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("^[0-9a-f]{40}$")]
        [string]
        # The thumbprint of the certificate to use.  The certificate must be installed.
        $Thumbprint,

        [Switch]
        # Return a `Carbon.Certificates.SslCertificateBinding` for the configured binding.
        $PassThru,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Windows.HttpServer'
    }

    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    Remove-CSslCertificateBinding -IPAddress $IPAddress -Port $Port -NoWarn

    $action = 'creating SSL certificate binding'
    if( $pscmdlet.ShouldProcess( $IPPort, $action ) )
    {
        $appID = $ApplicationID.ToString('B')
        Invoke-ConsoleCommand -Target $ipPort -Action $action -ScriptBlock {
            netsh http add sslcert ipport=$ipPort certhash=$Thumbprint appid=$appID
        }

        if( $PassThru )
        {
            Get-CSslCertificateBinding -IPAddress $IPAddress -Port $Port -NoWarn
        }
    }
}



function Test-CIdentity
{
    <#
    .SYNOPSIS
    Tests that a name is a valid Windows local or domain user/group.

    .DESCRIPTION
    Uses the Windows `LookupAccountName` function to find an identity.  If it can't be found, returns `$false`.  Otherwise, it returns `$true`.

    Use the `PassThru` switch to return a `Carbon.Identity` object (instead of `$true` if the identity exists.

    .LINK
    Resolve-CIdentity

    .LINK
    Resolve-CIdentityName

    .EXAMPLE
    Test-CIdentity -Name 'Administrators

    Tests that a user or group called `Administrators` exists on the local computer.

    .EXAMPLE
    Test-CIdentity -Name 'CARBON\Testers'

    Tests that a group called `Testers` exists in the `CARBON` domain.

    .EXAMPLE
    Test-CIdentity -Name 'Tester' -PassThru

    Tests that a user or group named `Tester` exists and returns a `System.Security.Principal.SecurityIdentifier` object if it does.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the identity to test.
        $Name,

        [Switch]
        # Returns a `Carbon.Identity` object if the identity exists.
        $PassThru,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName 'Test-CIdentity' -ModuleName 'Carbon.Accounts' -NoWarn:$NoWarn

    $identity = [Carbon.Identity]::FindByName( $Name )
    if( -not $identity )
    {
        return $false
    }

    if( $PassThru )
    {
        return $identity
    }
    return $true
}



function Test-COSIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 32-bit.

    .DESCRIPTION
    Regardless of the bitness of the currently running process, returns `True` if the current OS is a 32-bit OS.

    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx

    .EXAMPLE
    Test-COSIs32Bit

    Returns `True` if the current operating system is 32-bit, and `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Core' `
                                        -NewCommandName 'Test-COperatingSystem'
    }

    return -not (Test-COSIs64Bit -NoWarn)
}



function Test-COSIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 64-bit.

    .DESCRIPTION
    Regardless of the bitness of the currently running process, returns `True` if the current OS is a 64-bit OS.

    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx

    .EXAMPLE
    Test-COSIs64Bit

    Returns `True` if the current operating system is 64-bit, and `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Core' `
                                        -NewCommandName 'Test-COperatingSystem'
    }

    return ([Environment]::Is64BitOperatingSystem)
}



function Test-CPowerShellIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current PowerShell process is 32-bit.

    .DESCRIPTION
    Returns `True` if the currently executing PowerShell process is 32-bit/x86, `False` if it is 64-bit/x64.

    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitprocess.aspx

    .EXAMPLE
    Test-CPowerShellIs32Bit

    Returns `True` if PowerShell is 32-bit/x86, `False` if it is 64-bit/x64.
    #>
    [CmdletBinding()]
    param(
        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Core' `
                                        -NewCommandName 'Test-CPowerShell'
    }

    return -not (Test-CPowerShellIs64Bit -NoWarn)

}



function Test-CPowerShellIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current PowerShell process is 64-bit/x64.

    .DESCRIPTION
    Returns `True` if the currently executing PowerShell process is 64-bit/x64, `False` if it is 32-bit/x86.

    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitprocess.aspx

    .EXAMPLE
    Test-CPowerShellIs64Bit

    Returns `True` if PowerShell is 64-bit/x64, `False` if it is 32-bit/x86.
    #>
    [CmdletBinding()]
    param(
        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Core' `
                                        -NewCommandName 'Test-CPowerShell'
    }

    return ([Environment]::Is64BitProcess)
}



function Test-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.

    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.

    .EXAMPLE
    Test-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Registry'
    }

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        return $false
    }

    $properties = Get-ItemProperty -Path $Path
    if( -not $properties )
    {
        return $false
    }

    $member = Get-Member -InputObject $properties -Name $Name
    if( $member )
    {
        return $true
    }
    else
    {
        return $false
    }
}



function Test-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Tests if an SSL certificate binding exists.

	.DESCRIPTION
	SSL certificates are bound to IP addresses and ports.  This function tests if one exists on a given IP address/port.

	.EXAMPLE
	Test-CSslCertificateBinding -Port 443

	Tests if there is a default SSL certificate bound to all a machine's IP addresses on port 443.

	.EXAMPLE
	Test-CSslCertificateBinding -IPAddress 10.0.1.1 -Port 443

	Tests if there is an SSL certificate bound to IP address 10.0.1.1 on port 443.

	.EXAMPLE
	Test-CSslCertificateBinding

	Tests if there are any SSL certificates bound to any IP address/port on the machine.
    #>
    [CmdletBinding()]
    param(
        [IPAddress]
        # The IP address to test for an SSL certificate.
        $IPAddress,

        [Uint16]
        # The port to test for an SSL certificate.
        $Port,

        # Don't show the warning message that this command was moved to a new module.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Windows.HttpServer'
    }

    $getArgs = @{ }
    if( $IPAddress )
    {
        $getArgs.IPAddress = $IPAddress
    }

    if( $Port )
    {
        $getArgs.Port = $Port
    }

    $binding = Get-CSslCertificateBinding @getArgs -NoWarn
    if( $binding )
    {
        return $True
    }
    else
    {
        return $False
    }
}


function Test-CWindowsFeature
{
    <#
    .SYNOPSIS
    Tests if an optional Windows component exists and, optionally, if it is installed.

    .DESCRIPTION
    Feature names are different across different versions of Windows.  This function tests if a given feature exists.  You can also test if a feature is installed by setting the `Installed` switch.

    Feature names are case-sensitive and are different between different versions of Windows.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.  On Windows 8/2012, use `Get-CWindowsFeature`.

    .LINK
    Get-CWindowsFeature

    .LINK
    Install-CWindowsFeature

    .LINK
    Uninstall-CWindowsFeature

    .EXAMPLE
    Test-CWindowsFeature -Name MSMQ-Server

    Tests if the MSMQ-Server feature exists on the current computer.

    .EXAMPLE
    Test-CWindowsFeature -Name IIS-WebServer -Installed

    Tests if the IIS-WebServer features exists and is installed/enabled.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the feature to test.  Feature names are case-sensitive and are different between different versions of Windows.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.  On Windows 8/2012, use `Get-CWindowsFeature`.
        $Name,

        [Switch]
        # Test if the service is installed in addition to if it exists.
        $Installed
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name

    if( -not (Get-Module -Name 'ServerManager') -and -not (Assert-WindowsFeatureFunctionsSupported) )
    {
        return
    }

    $feature = Get-CWindowsFeature -Name $Name

    if( $feature )
    {
        if( $Installed )
        {
            return $feature.Installed
        }
        return $true
    }
    else
    {
        return $false
    }
}



function Uninstall-CCertificate
{
    <#
    .SYNOPSIS
    Removes a certificate from a store for the user or machine account.

    .DESCRIPTION
    The `Uninstall-CCertificate` function uses .NET's certificates API to remove a certificate from a given store for the machine or current user. Use the thumbprint to identify which certificate to remove. The thumbprint is unique to each certificate. The user performing the removal must have read and write permission on the store where the certificate is located.

    If the certificate isn't in the store, nothing happens, not even an error.

    To uninstall a certificate from a remote computer, use the `Session`parameter, which was added in Carbon 2.1.0. You can create a new session with the `New-PSSession` cmdlet.

    You can uninstall a certificate using just its thumbprint (this functionality is new in Carbon 2.5.0). `Uninstall-CCertificate` will search through all certificate locations and stores and uninstall all certificates that have the thumbprint. When you enumerate all certificates over a remoting session, you get a terminating `The system cannot open the device or file specified` error, so you can't delete a certificate with just a thumbprint over remoting.

    .EXAMPLE
    Uninstall-CCertificate -Thumbprint 570895470234023dsaaefdbcgbefa

    Demonstrates how to delete a certificate from all stores it is installed in. `Uninstall-CCertificate` searches every certificate stores and deletes all certificates with the given thumbprint. This functionality was added in Carbon 2.5.0.

    .EXAMPLE
    '570895470234023dsaaefdbcgbefa' | Uninstall-CCertificate

    Demonstrates that you can pipe a thumbprint to `Uninstall-CCertificate`. The certificate is uninstall from all stores it is in. This functionality was added in Carbon 2.5.0.

    .EXAMPLE
    Get-Item -Path 'cert:\LocalMachine\My\570895470234023dsaaefdbcgbefa' | Uninstall-CCertificate

    Demonstrates that you can pipe a certificate `Uninstall-CCertificate`. The certificate is uninstalled from all stores it is in. This functionality was added in Carbon 2.5.0.

    .EXAMPLE
    > Uninstall-CCertificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation CurrentUser -StoreName My

    Removes the 570895470234023dsaaefdbcgbefa certificate from the current user's Personal certificate store.

    .EXAMPLE
    > $cert = Get-CCertificate -FriendlyName 'Carbon Testing Certificate' -StoreLocation LocalMachine -StoreName Root
    > Uninstall-CCertificate -Certificate $cert -StoreLocation LocalMachine -StoreName Root

    Removes the certificate with friendly name 'Carbon Testing Certificate' from the local machine's Trusted Root Certification Authorities store.

    .EXAMPLE
    Uninstall-CCertificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation LocalMachine -StoreName 'SharePoint'

    Demonstrates how to uninstall a certificate from a custom, non-standard store.

    .EXAMPLE
    > Uninstall-CCertificate -Thumbprint 570895470234023dsaaefdbcgbefa -StoreLocation CurrentUser -StoreName My -Session (New-PSSession -ComputerName remote1,remote2)

    Demonstrates how to uninstall a certificate from a remote computer.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByThumbprint')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprint',ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndCustomStoreName')]
        [string]
        # The thumbprint of the certificate to remove.
        #
        # If you want to uninstall the certificate from all stores it is installed in, you can pipe the thumbprint to this parameter or you can pipe a certificate object. (This functionality was added in Carbon 2.5.0.)
        $Thumbprint,

        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndCustomStoreName')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        # The certificate to remove
        $Certificate,

        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndCustomStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndCustomStoreName')]
        [Security.Cryptography.X509Certificates.StoreLocation]
        # The location of the certificate's store.
        $StoreLocation,

        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndStoreName')]
        [Security.Cryptography.X509Certificates.StoreName]
        # The name of the certificate's store.
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='ByThumbprintAndCustomStoreName')]
        [Parameter(Mandatory=$true,ParameterSetName='ByCertificateAndCustomStoreName')]
        [string]
        # The name of the non-standard, custom store where the certificate should be un-installed.
        $CustomStoreName,

        [Parameter(ParameterSetName='ByThumbprintAndStoreName')]
        [Parameter(ParameterSetName='ByThumbprintAndCustomStoreName')]
        [Parameter(ParameterSetName='ByCertificateAndStoreName')]
        [Parameter(ParameterSetName='ByCertificateAndCustomStoreName')]
        [Management.Automation.Runspaces.PSSession[]]
        # Use the `Session` parameter to uninstall a certificate on remote computer(s) using PowerShell remoting. Use `New-PSSession` to create a session.
        #
        # Due to a bug in PowerShell, you can't remove a certificate by just its thumbprint over remoting. Using just a thumbprint requires us to enumerate through all installed certificates. When you do this over remoting, PowerShell throws a terminating `The system cannot open the device or file specified` error.
        #
        # This parameter was added in Carbon 2.1.0.
        $Session,

        [switch]$NoWarn
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( -not $NoWarn )
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
        }

        if( $PSCmdlet.ParameterSetName -like 'ByCertificate*' )
        {
            $Thumbprint = $Certificate.Thumbprint
        }

        $invokeCommandParameters = @{}
        if( $Session )
        {
            $invokeCommandParameters['Session'] = $Session
        }

        if( $PSCmdlet.ParameterSetName -eq 'ByThumbprint' )
        {
            # Must be in this order. Delete LocalMachine certs *first* so they don't show
            # up in CurrentUser stores. If you delete a certificate that "cascades" into
            # the CurrentUser store first, you'll get errors when running non-
            # interactively as SYSTEM.
            Get-ChildItem -Path 'Cert:\LocalMachine','Cert:\CurrentUser' -Recurse |
                Where-Object { -not $_.PsIsContainer } |
                Where-Object { $_.Thumbprint -eq $Thumbprint } |
                ForEach-Object {
                    $cert = $_
                    $description = $cert.FriendlyName
                    if( -not $description )
                    {
                        $description = $cert.Subject
                    }

                    $certPath = $_.PSPath | Split-Path -NoQualifier
                    Write-Verbose ('Uninstalling certificate ''{0}'' ({1}) at {2}.' -f $description,$cert.Thumbprint,$certPath)
                    $_
                } |
                Remove-Item
            return
        }

        Invoke-Command @invokeCommandParameters -ScriptBlock {
            [CmdletBinding()]
            param(
                [string]
                # The thumbprint of the certificate to remove.
                $Thumbprint,

                [Security.Cryptography.X509Certificates.StoreLocation]
                # The location of the certificate's store.
                $StoreLocation,

                # The name of the certificate's store.
                $StoreName,

                [string]
                # The name of the non-standard, custom store where the certificate should be un-installed.
                $CustomStoreName
            )

            Set-StrictMode -Version 'Latest'

            if( $CustomStoreName )
            {
                $storeNamePath = $CustomStoreName
            }
            else
            {
                $storeNamePath = $StoreName
                if( $StoreName -eq [Security.Cryptography.X509Certificates.StoreName]::CertificateAuthority )
                {
                    $storeNamePath = 'CA'
                }
            }

            $certPath = Join-Path -Path 'Cert:\' -ChildPath $StoreLocation
            $certPath = Join-Path -Path $certPath -ChildPath $storeNamePath
            $certPath = Join-Path -Path $certPath -ChildPath $Thumbprint

            if( -not (Test-Path -Path $certPath -PathType Leaf) )
            {
                Write-Debug -Message ('Certificate {0} not found.' -f $certPath)
                return
            }

            $cert = Get-Item -Path $certPath

            if( $CustomStoreName )
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' $CustomStoreName,$StoreLocation
            }
            else
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' ([Security.Cryptography.X509Certificates.StoreName]$StoreName),$StoreLocation
            }

            $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )

            try
            {
                $target = $cert.FriendlyName
                if( -not $target )
                {
                    $target = $cert.Subject
                }

                if( $PSCmdlet.ShouldProcess( ("certificate {0} ({1})" -f $certPath,$target), "remove" ) )
                {
                    Write-Verbose ('Uninstalling certificate ''{0}'' ({1}) at {2}.' -f $target,$cert.Thumbprint,$certPath)
                    $store.Remove( $cert )
                }
            }
            finally
            {
                $store.Close()
            }
        } -ArgumentList $Thumbprint,$StoreLocation,$StoreName,$CustomStoreName
    }
}

Set-Alias -Name 'Remove-Certificate' -Value 'Uninstall-CCertificate'



# This function should only be available if the Windows PowerShell v3.0 Server Manager cmdlets aren't already installed.
if( -not (Get-Command -Name 'Get-WindowsFeature*' | Where-Object { $_.ModuleName -ne 'Carbon' }) )
{
    function Uninstall-CWindowsFeature
    {
        <#
        .SYNOPSIS
        Uninstalls optional Windows components/features.

        .DESCRIPTION
        The names of the features are different on different versions of Windows.  For a list, run `Get-WindowsService`.

        Feature names are case-sensitive.  If a feature is already uninstalled, nothing happens.

        **This function is not available on Windows 8/2012.**

        .LINK
        Get-CWindowsFeature

        .LINK
        Install-WindowsService

        .LINK
        Test-WindowsService

        .EXAMPLE
        Uninstall-CWindowsFeature -Name TelnetClient,TFTP

        Uninstalls Telnet and TFTP.

        .EXAMPLE
        Uninstall-CWindowsFeature -Iis

        Uninstalls IIS.
        #>
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ByName')]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ByName')]
            [string[]]
            # The names of the components to uninstall/disable.  Feature names are case-sensitive.  To get a list, run `Get-CWindowsFeature`.
            [Alias('Features')]
            $Name,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls IIS.
            $Iis,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls IIS's HTTP redirection feature.
            $IisHttpRedirection,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls MSMQ.
            $Msmq,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls MSMQ HTTP support.
            $MsmqHttpSupport,

            [Parameter(ParameterSetName='ByFlag')]
            [Switch]
            # Uninstalls MSMQ Active Directory Integration.
            $MsmqActiveDirectoryIntegration
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                      -NewCommandName 'Uninstall-WindowsFeature' `
                                      -NewModuleName 'ServerManager'

        if( -not (Assert-WindowsFeatureFunctionsSupported) )
        {
            return
        }

        if( $pscmdlet.ParameterSetName -eq 'ByFlag' )
        {
            $Name = Resolve-WindowsFeatureName -Name $PSBoundParameters.Keys
        }

        $featuresToUninstall = $Name |
                                    ForEach-Object {
                                        if( (Test-CWindowsFeature -Name $_) )
                                        {
                                            $_
                                        }
                                        else
                                        {
                                            Write-Error ('Windows feature ''{0}'' not found.' -f $_)
                                        }
                                    } |
                                    Where-Object { Test-CWindowsFeature -Name $_ -Installed }

        if( -not $featuresToUninstall -or $featuresToUninstall.Length -eq 0 )
        {
            return
        }

        if( $pscmdlet.ShouldProcess( "Windows feature(s) '$featuresToUninstall'", "uninstall" ) )
        {
            if( $useServerManager )
            {
                & servermanagercmd.exe -remove $featuresToUninstall
            }
            else
            {
                $featuresArg = $featuresToUninstall -join ';'
                & ocsetup.exe $featuresArg /uninstall
                $ocsetup = Get-Process 'ocsetup' -ErrorAction SilentlyContinue
                if( -not $ocsetup )
                {
                    Write-Error "Unable to find process 'ocsetup'.  It looks like the Windows Optional Component setup program didn't start."
                    return
                }
                $ocsetup.WaitForExit()
            }
        }
    }

    Set-Alias -Name 'Uninstall-WindowsFeatures' -Value 'Uninstall-CWindowsFeature'
    Set-Alias -Name 'Uninstall-WindowsFeature' -Value 'Uninstall-CWindowsFeature'
}



filter Unprotect-CString
{
    <#
    .SYNOPSIS
    Decrypts a string.

    .DESCRIPTION
    `Unprotect-CString` decrypts a string encrypted via the Data Protection API (DPAPI), RSA, or AES. It uses the DP/RSA APIs to decrypted the secret into an array of bytes, which is then converted to a UTF8 string. Beginning with Carbon 2.0, after conversion, the decrypted array of bytes is cleared in memory.

    Also beginning in Carbon 2.0, use the `AsSecureString` switch to cause `Unprotect-CString` to return the decrypted string as a `System.Security.SecureString`, thus preventing your secret from hanging out in memory. When converting to a secure string, the secret is decrypted to an array of bytes, and then converted to an array of characters. Each character is appended to the secure string, after which it is cleared in memory. When the conversion is complete, the decrypted byte array is also cleared out in memory.

    `Unprotect-CString` can decrypt using the following techniques.

    ## DPAPI

    This is the default. The string must have also been encrypted with the DPAPI. The string must have been encrypted at the current user's scope or the local machine scope.

    ## RSA

    RSA is an assymetric encryption/decryption algorithm, which requires a public/private key pair. It uses a private key to decrypt a secret encrypted with the public key. Only the private key can decrypt secrets. `Protect-CString` decrypts with .NET's `System.Security.Cryptography.RSACryptoServiceProvider` class.

    You can specify the private key in three ways:

     * with a `System.Security.Cryptography.X509Certificates.X509Certificate2` object, via the `Certificate` parameter
     * with a certificate in one of the Windows certificate stores, passing its unique thumbprint via the `Thumbprint` parameter, or via the `PrivateKeyPath` parameter, which can be a certificat provider path, e.g. it starts with `cert:\`.
     * with an X509 certificate file, via the `PrivateKeyPath` parameter

    ## AES

    AES is a symmetric encryption/decryption algorithm. You supply a 16-, 24-, or 32-byte key, password, or passphrase with the `Key` parameter, and that key is used to decrypt. You must decrypt with the same key you used to encrypt. `Unprotect-CString` decrypts with .NET's `System.Security.Cryptography.AesCryptoServiceProvider` class.

    Symmetric encryption requires a random, unique initialization vector (i.e. IV) everytime you encrypt something. If you encrypted your original string with Carbon's `Protect-CString` function, that IV was pre-pended to the encrypted secret. If you encrypted the secret yourself, you'll need to ensure the original IV is pre-pended to the protected string.

    The help topic for `Protect-CString` demonstrates how to generate an AES key and how to encode it as a base-64 string.

    The ability to decrypt with AES was added in Carbon 2.3.0.

    .LINK
    New-CRsaKeyPair

    .LINK
    Protect-CString

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.protecteddata.aspx

    .EXAMPLE
    PS> $password = Unprotect-CString -ProtectedString  $encryptedPassword

    Decrypts a protected string which was encrypted at the current user or default scopes using the DPAPI. The secret must have been encrypted at the current user's scope or at the local computer's scope.

    .EXAMPLE
    Protect-CString -String 'NotSoSecretSecret' -ForUser | Unprotect-CString

    Demonstrates how Unprotect-CString takes input from the pipeline.  Adds 'NotSoSecretSecret' to the pipeline.

    .EXAMPLE
    Unprotect-CString -ProtectedString $ciphertext -Certificate $myCert

    Demonstrates how to encrypt a secret using RSA with a `System.Security.Cryptography.X509Certificates.X509Certificate2` object. You're responsible for creating/loading it. The `New-CRsaKeyPair` function will create a key pair for you, if you've got a Windows SDK installed.

    .EXAMPLE
    Unprotect-CString -ProtectedString $ciphertext -Thumbprint '44A7C27F3353BC53F82318C14490D7E2500B6D9E'

    Demonstrates how to decrypt a secret using RSA with a certificate in one of the Windows certificate stores. All local machine and user stores are searched. The current user must have permission/access to the certificate's private key.

    .EXAMPLE
    Unprotect -ProtectedString $ciphertext -PrivateKeyPath 'C:\Projects\Security\publickey.cer'

    Demonstrates how to encrypt a secret using RSA with a certificate file. The file must be loadable by the `System.Security.Cryptography.X509Certificates.X509Certificate` class.

    .EXAMPLE
    Unprotect -ProtectedString $ciphertext -PrivateKeyPath 'cert:\LocalMachine\My\44A7C27F3353BC53F82318C14490D7E2500B6D9E'

    Demonstrates how to encrypt a secret using RSA with a certificate in the store, giving its exact path.

    .EXAMPLE
    Unprotect-CString -ProtectedString 'dNC+yiKdSMAsG2Y3DA6Jzozesie3ZToQT24jB4CU/9eCGEozpiS5MR7R8s3L+PWV' -Key 'gT4XPfvcJmHkQ5tYjY3fNgi7uwG4FB9j'

    Demonstrates how to decrypt a secret that was encrypted with a key, password, or passphrase. In this case, we are decrypting with a plaintext password. This functionality was added in Carbon 2.3.0.

    .EXAMPLE
    Unprotect-CString -ProtectedString '19hNiwW0mmYHRlbk65GnSH2VX7tEziazZsEXvOzZIyCT69pp9HLf03YBVYGfg788' -Key (Read-Host -Prompt 'Enter password (must be 16, 24, or 32 characters long):' -AsSecureString)

    Demonstrates how to decrypt a secret that was encrypted with a key, password, or passphrase. In this case, we are prompting the user for the password. This functionality was added in Carbon 2.3.0.

    .EXAMPLE
    Unprotect-CString -ProtectedString 'Mpu90IhBq9NseOld7VO3akcJX+nCIZmJv8rz8qfyn7M9m26owetJVzAfhFr0w0Vj' -Key ([byte[]]@(163,163,185,174,205,55,157,219,121,146,251,116,43,203,63,38,73,154,230,112,82,112,151,29,189,135,254,187,164,104,45,30))

    Demonstrates how to decrypt a secret that was encrypted with a key, password, or passphrase as an array of bytes. This functionality was added in Carbon 2.3.0.
    #>
    [CmdletBinding(DefaultParameterSetName='DPAPI')]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingPlainTextForPassword', 'Password')]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        # The text to decrypt.
        [String]$ProtectedString,

        [Parameter(Mandatory, ParameterSetName='RSAByCertificate')]
        # The private key to use for decrypting.
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(Mandatory, ParameterSetName='RSAByThumbprint')]
        # The thumbprint of the certificate, found in one of the Windows certificate stores, to use when decrypting. All certificate stores are searched. The current user must have permission to the private key.
        [String]$Thumbprint,

        [Parameter(Mandatory, ParameterSetName='RSAByPath')]
        # The path to the private key to use for encrypting. Must be to an `X509Certificate2` file or a certificate in a certificate store.
        [String]$PrivateKeyPath,

        [Parameter(ParameterSetName='RSAByPath')]
        # The password for the private key, if it has one. It really should. Can be a `[string]` or a `[securestring]`.
        $Password,

        [Parameter(ParameterSetName='RSAByCertificate')]
        [Parameter(ParameterSetName='RSAByThumbprint')]
        [Parameter(ParameterSetName='RSAByPath')]
        # If true, uses Direct Encryption (PKCS#1 v1.5) padding. Otherwise (the default), uses OAEP (PKCS#1 v2) padding. See [Encrypt](http://msdn.microsoft.com/en-us/library/system.security.cryptography.rsacryptoserviceprovider.encrypt(v=vs.110).aspx) for information.
        [switch]$UseDirectEncryptionPadding,

        [Parameter(Mandatory, ParameterSetName='Symmetric')]
        # The key to use to decrypt the secret. Must be a `SecureString`, `string`, or an array of bytes.
        [Object]$Key,

        # Returns the unprotected string as a secure string. The original decrypted bytes are zeroed out to limit the memory exposure of the decrypted secret, i.e. the decrypted secret will never be in a `string` object.
        [switch]$AsSecureString,

        [switch]$NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Cryptography'
    }

    Add-Type -AssemblyName 'System.Security'

    [byte[]]$encryptedBytes = [Convert]::FromBase64String($ProtectedString)
    if( $PSCmdlet.ParameterSetName -eq 'DPAPI' )
    {
        $decryptedBytes = [Security.Cryptography.ProtectedData]::Unprotect( $encryptedBytes, $null, 0 )
    }
    elseif( $PSCmdlet.ParameterSetName -like 'RSA*' )
    {
        if( $PSCmdlet.ParameterSetName -like '*ByPath' )
        {
            $passwordParam = @{ }
            if( $Password )
            {
                $passwordParam = @{ Password = $Password }
            }
            $Certificate = Get-CCertificate -Path $PrivateKeyPath @passwordParam -NoWarn
            if( -not $Certificate )
            {
                return
            }
        }
        elseif( $PSCmdlet.ParameterSetName -like '*ByThumbprint' )
        {
            $certificates = Get-Item -Path ('cert:\*\*\{0}' -f $Thumbprint)
            if( -not $certificates )
            {
                Write-Error ('Certificate "{0}" not found.' -f $Thumbprint)
                return
            }

            $Certificate = $certificates | Where-Object { $_.HasPrivateKey } | Select-Object -First 1
            if( -not $Certificate )
            {
                Write-Error ('Certificate "{0}" ({1}) doesn''t have a private key.' -f $certificates[0].Subject, $Thumbprint)
                return
            }
        }

        if( -not $Certificate.HasPrivateKey )
        {
            Write-Error ('Certificate "{0}" ({1}) doesn''t have a private key. When decrypting with RSA, secrets are encrypted with the public key, and decrypted with a private key.' -f $Certificate.Subject,$Certificate.Thumbprint)
            return
        }

        if( -not $Certificate.PrivateKey )
        {
            Write-Error ('Certificate "{0}" ({1}) has a private key, but it is currently null or not set. This usually means your certificate was imported or generated incorrectly. Make sure you''ve generated an RSA public/private key pair and are using the private key. If the private key is in the Windows certificate stores, make sure it was imported correctly (`Get-ChildItem $pathToCert | Select-Object -Expand PrivateKey` isn''t null).' -f $Certificate.Subject,$Certificate.Thumbprint)
            return
        }

        [Security.Cryptography.RSA]$privateKey = $null
        $privateKeyType = $Certificate.PrivateKey.GetType()
        $isRsa = $privateKeyType.IsSubclassOf([Security.Cryptography.RSA])
        if( -not $isRsa )
        {
            Write-Error ('Certificate "{0}" ("{1}") is not an RSA key. Found a private key of type "{2}", but expected type "{3}".' -f $Certificate.Subject,$Certificate.Thumbprint,$privateKeyType.FullName,[Security.Cryptography.RSA].FullName)
            return
        }

        $padding = [Security.Cryptography.RSAEncryptionPadding]::OaepSHA1
        if( $UseDirectEncryptionPadding )
        {
            $padding = [Security.Cryptography.RSAEncryptionPadding]::Pkcs1
        }
        try
        {
            $privateKey = $Certificate.PrivateKey
            $decryptedBytes = $privateKey.Decrypt($encryptedBytes, $padding)
        }
        catch
        {
            [int]$maxLengthGuess = ($privateKey.KeySize - (2 * 160 - 2)) / 8
            Write-Error (@'
Failed to decrypt string using certificate "{0}" ({1}). This can happen when:
 * The string to decrypt is too long because the original string you encrypted was at or near the maximum allowed by your key's size, which is {2} bits. We estimate the maximum string size you can encrypt is {3} bytes. You may get this error even if the original encrypted string is within a couple bytes of that maximum.
 * The string was encrypted with a different key.
 * The string isn't encrypted.
 * The padding algorithm used when encrypting/decrypting is different. Check the `-UseDirectEncryptionPadding` switch is the same for both calls to `Protect-CString` and `Unprotect-CString`.

{4}: {5}
'@ -f $Certificate.Subject, $Certificate.Thumbprint, $privateKey.KeySize, $maxLengthGuess, $_.Exception.GetType().FullName, $_.Exception.Message)
            return
        }
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'Symmetric' )
    {
        $Key = ConvertTo-Key -InputObject $Key -From 'Unprotect-CString'
        if( -not $Key )
        {
            return
        }

        $aes = [Security.Cryptography.Aes]::Create()
        try
        {
            $aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
            $aes.KeySize = $Key.Length * 8
            $aes.Key = $Key
            $iv = New-Object 'Byte[]' $aes.IV.Length
            [Array]::Copy($encryptedBytes,$iv,16)

            $encryptedBytes = $encryptedBytes[16..($encryptedBytes.Length - 1)]
            $encryptedStream = New-Object 'IO.MemoryStream' (,$encryptedBytes)
            try
            {
                $decryptor = $aes.CreateDecryptor($aes.Key, $iv)
                try
                {
                    $cryptoStream = New-Object 'Security.Cryptography.CryptoStream' $encryptedStream,$decryptor,([Security.Cryptography.CryptoStreamMode]::Read)
                    try
                    {
                        $streamReader = New-Object 'IO.StreamReader' $cryptoStream
                        try
                        {
                            [byte[]]$decryptedBytes = [Text.Encoding]::UTF8.GetBytes($streamReader.ReadToEnd())
                        }
                        finally
                        {
                            $streamReader.Dispose()
                        }
                    }
                    finally
                    {
                        $cryptoStream.Dispose()
                    }
                }
                finally
                {
                    $decryptor.Dispose()
                }
            }
            finally
            {
                $encryptedStream.Dispose()
            }
        }
        finally
        {
            $aes.Dispose()
        }
    }

    try
    {
        if( $AsSecureString )
        {
            $secureString = New-Object 'Security.SecureString'
            [char[]]$chars = [Text.Encoding]::UTF8.GetChars( $decryptedBytes )
            for( $idx = 0; $idx -lt $chars.Count ; $idx++ )
            {
                $secureString.AppendChar( $chars[$idx] )
                $chars[$idx] = 0
            }

            $secureString.MakeReadOnly()
            return $secureString
        }
        else
        {
            [Text.Encoding]::UTF8.GetString( $decryptedBytes )
        }
    }
    finally
    {
        [Array]::Clear( $decryptedBytes, 0, $decryptedBytes.Length )
    }
}
