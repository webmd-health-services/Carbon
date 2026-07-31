


function Add-CGroupMember
{
    <#
    .SYNOPSIS
    Adds a users or groups to a *local* group.

    .DESCRIPTION
    You would think it's pretty easy and straight-forward to add users/groups to a local group, but you would be wrong.  The quick solution is to use `net localgroup`, but that won't accept user/group names longer than 24 characters.  This means you have to use the .NET Directory Services APIs.  How do you reliably add both users *and* groups?  What if those users are in a domain?  What if they're in another domain?  What about built-in users?  Fortunately, you're brain hasn't exploded.

    So, this function adds users and groups to a *local* group.

    If the members are already part of the group, nothing happens.

    The user running this function must have access to the directory where each principal in the `Member` parameter and the directory where each of the group's current members are located.

    .EXAMPLE
    Add-CGroupMember -Name Administrators -Member EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Adds Darth Vader, Emperor Palpatine and Luke Skywalker to the local administrators group.

    .EXAMPLE
    Add-CGroupMember -Name TieFighters -Member NetworkService

    Adds the local NetworkService account to the local TieFighters group.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The group name.
        $Name,

        [Parameter(Mandatory=$true)]
        [string[]]
        # The users/groups to add to a group.
		[Alias('Members')]
        $Member,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Install-CLocalGroupMember' `
                                    -NoWarn:$NoWarn

    [DirectoryServices.AccountManagement.GroupPrincipal]$group = Get-CGroup -Name $Name -NoWarn
    if( -not $group )
    {
        return
    }

    try
    {
        foreach( $_member in $Member )
        {
            $identity = Resolve-CIdentity -Name $_member -NoWarn
            if( -not $identity )
            {
                continue
            }

            if( (Test-CGroupMember -GroupName $group.Name -Member $_member) )
            {
                continue
            }

            Write-Verbose -Message ('[{0}] Members       -> {1}' -f $Name,$identity.FullName)
            if( -not $PSCmdlet.ShouldProcess(('adding ''{0}'' to local group ''{1}''' -f $identity.FullName, $group.Name), $null, $null) )
            {
                continue
            }

            try
            {
                $identity.AddToLocalGroup( $group.Name )
            }
            catch
            {
                Write-Error ('Failed to add ''{0}'' to group ''{1}'': {2}.' -f $identity,$group.Name,$_)
            }
        }
    }
    finally
    {
        $group.Dispose()
    }
}

Set-Alias -Name 'Add-GroupMembers' -Value 'Add-CGroupMember'


function Assert-CAdminPrivilege
{
    <#
    .SYNOPSIS
    Writes an error and returns false if the user doesn't have administrator privileges.

    .DESCRIPTION
    Many scripts and functions require the user to be running as an administrator.  This function checks if the user is running as an administrator or with administrator privileges and writes an error if the user doesn't.

    .LINK
    Test-CAdminPrivilege

    .EXAMPLE
    Assert-CAdminPrivilege

    Writes an error that the user doesn't have administrator privileges.
    #>
    [CmdletBinding()]
    param(
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Assert-CRunAsElevated' `
                                    -NoWarn:$NoWarn

    if( -not (Test-CAdminPrivilege -NoWarn) )
    {
        Write-Error "You are not currently running with administrative privileges.  Please re-start PowerShell as an administrator (right-click the PowerShell application, and choose ""Run as Administrator"")."
        return $false
    }
    return $true
}

Set-Alias -Name 'Assert-AdminPrivileges' -Value 'Assert-CAdminPrivilege'

function Assert-CService
{
    <#
    .SYNOPSIS
    Checks if a service exists, and writes an error if it doesn't.

    .DESCRIPTION
    Also returns `True` if the service exists, `False` if it doesn't.

    .OUTPUTS
    System.Boolean.

    .LINK
    Test-CService

    .EXAMPLE
    Assert-CService -Name 'Drivetrain'

    Writes an error if the `Drivetrain` service doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    if( -not (Test-CService $Name -NoWarn) )
    {
        Write-Error ('Service {0} not found.' -f $Name)
        return $false
    }

    return $true
}


function Clear-CDscLocalResourceCache
{
    <#
    .SYNOPSIS
    Clears the local DSC resource cache.

    .DESCRIPTION
    DSC caches resources. This is painful when developing, since you're constantly updating your resources. This function allows you to clear the DSC resource cache on the local computer. What this function really does, is kill the DSC host process running DSC.

    `Clear-CDscLocalResourceCache` is new in Carbon 2.0.

    .EXAMPLE
    Clear-CDscLocalResourceCache
    #>
    [CmdletBinding()]
    param(
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    Get-CCimInstance -Class 'msft_providers' |
        Where-Object {$_.provider -like 'dsccore'} |
        Select-Object -ExpandProperty HostProcessIdentifier |
        ForEach-Object { Get-Process -ID $_ } |
        Stop-Process -Force
}


function Clear-CMofAuthoringMetadata
{
    <#
    .SYNOPSIS
    Removes authoring metadata from .mof files.

    .DESCRIPTION
    Everytime PowerShell generates a .mof file, it includes authoring metadata: who created the file, on what computer, and at what date/time. This means a .mof file's checksum will change everytime a new one is generated, even if the configuration in that file didn't change. This makes it hard to know when a configuration in a .mof file has truly changed, and makes its change history noisy. This function strips/removes all authoring metadata from a .mof file.

    When given a path to a file, all authoring metadata is removed from that file. When given the path to a directory, removes authoring metadata from all `*.mof` files in that directory.

    Essentially, these blocks from each .mof file:

        /*
        @TargetNode='********'
        @GeneratedBy=********
        @GenerationDate=08/19/2014 13:29:15
        @GenerationHost=********
        */

        /* ...snip... */


        instance of OMI_ConfigurationDocument
        {
         Version="1.0.0";
         Author="********;
         GenerationDate="08/19/2014 13:29:15";
         GenerationHost="********";
        };

    Would be changed to:

        /*
        @TargetNode='JSWEB01L-WHS-08'
        */

        /* ...snip... */

        instance of OMI_ConfigurationDocument
        {
         Version="1.0.0";
        };


    `Clear-CMofAuthoringMetadata` is new in Carbon 2.0.

    .EXAMPLE
    Clear-CMofAuthoringMetadata -Path 'C:\Projects\DSC\localhost.mof'

    Demonstrates how to clear the authoring data from a specific file.

    .EXAMPLE
    Clear-CMofAuthoringMetadata -Path 'C:\Projects\DSC'

    Demonstrates how to clear the authoring data from all .mof files in a specific directory.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the file/directory whose .mof files should be operated on.
        $Path,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    $tempDir = New-CTempDirectory -Prefix ('Carbon+ClearMofAuthoringMetadata+') -WhatIf:$false

    foreach( $item in (Get-ChildItem -Path $Path -Filter '*.mof') )
    {
        Write-Verbose ('Clearing authoring metadata from ''{0}''.' -f $item.FullName)
        $tempItem = Copy-Item -Path $item.FullName -Destination $tempDir -PassThru -WhatIf:$false
        $inComment = $false
        $inAuthoringComment = $false
        $inConfigBlock = $false;
        Get-Content -Path $tempItem |
            Where-Object {
                $line = $_

                if( $line -like '/`**' )
                {
                    if( $line -like '*`*/' )
                    {
                        return $true
                    }
                    $inComment = $true
                    return $true
                }

                if( $inComment )
                {
                    if( $line -like '*`*/' )
                    {
                        $inComment = $false
                        $inAuthoringComment = $false
                        return $true
                    }

                    if( $line -like '@TargetNode=*' )
                    {
                        $inAuthoringComment = $true
                        return $true
                    }

                    if( $inAuthoringComment )
                    {
                        return ( $line -notmatch '^@(GeneratedBy|Generation(Host|Date))' )
                    }

                    return $true
                }

                if( $line -eq 'instance of OMI_ConfigurationDocument' )
                {
                    $inConfigBlock = $true
                    return $true
                }

                if( $inConfigBlock )
                {
                    if( $line -like '};' )
                    {
                        $inConfigBlock = $false;
                        return $true
                    }

                    return ($line -notmatch '(Author|(Generation(Date|Host)))=');
                }

                return $true

            } |
            Set-Content -Path $item.FullName
    }
}

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

function ConvertTo-CArgValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [String] $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $InputObject)
        {
            # args.exe returns what you pass it. If it returns nothing, PowerShell isn't passing an empty string as
            # an argument, so force it to by using double-quotes.
            if (-not (& $script:argsExePath $InputObject | Measure-Object).Count)
            {
                return '""'
            }

            return $InputObject
        }

        if ($InputObject -eq (& $script:argsExePath $InputObject))
        {
            return $InputObject
        }

        return $InputObject -replace '"', '\"'
    }
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



function ConvertTo-CContainerInheritanceFlags
{
    <#
    .SYNOPSIS
    Converts a combination of InheritanceFlags Propagation Flags into a Carbon.Security.ContainerInheritanceFlags enumeration value.

    .DESCRIPTION
    `Grant-CPermission`, `Test-CPermission`, and `Get-CPermission` all take an `ApplyTo` parameter, which is a `Carbon.Security.ContainerInheritanceFlags` enumeration value. This enumeration is then converted to the appropriate `System.Security.AccessControl.InheritanceFlags` and `System.Security.AccessControl.PropagationFlags` values for getting/granting/testing permissions. If you prefer to speak in terms of `InheritanceFlags` and `PropagationFlags`, use this function to convert them to a `ContainerInheritanceFlags` value.

    If your combination doesn't result in a valid combination, `$null` is returned.

    For detailed description of inheritance and propagation flags, see the help for `Grant-CPermission`.

    .OUTPUTS
    Carbon.Security.ContainerInheritanceFlags.

    .LINK
    Grant-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    ConvertTo-CContainerInheritanceFlags -InheritanceFlags 'ContainerInherit' -PropagationFlags 'None'

    Demonstrates how to convert `InheritanceFlags` and `PropagationFlags` enumeration values into a `ContainerInheritanceFlags`. In this case, `[Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainers` is returned.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Security.ContainerInheritanceFlags])]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Security.AccessControl.InheritanceFlags]
        # The inheritance flags to convert.
        $InheritanceFlags,

        [Parameter(Mandatory=$true,Position=1)]
        [Security.AccessControl.PropagationFlags]
        # The propagation flags to convert.
        $PropagationFlags,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name
    }

    $propFlagsNone = $PropagationFlags -eq [Security.AccessControl.PropagationFlags]::None
    $propFlagsInheritOnly = $PropagationFlags -eq [Security.AccessControl.PropagationFlags]::InheritOnly
    $propFlagsInheritOnlyNoPropagate = $PropagationFlags -eq ([Security.AccessControl.PropagationFlags]::InheritOnly -bor [Security.AccessControl.PropagationFlags]::NoPropagateInherit)
    $propFlagsNoPropagate = $PropagationFlags -eq [Security.AccessControl.PropagationFlags]::NoPropagateInherit

    if( $InheritanceFlags -eq [Security.AccessControl.InheritanceFlags]::None )
    {
        return [Carbon.Security.ContainerInheritanceFlags]::Container
    }
    elseif( $InheritanceFlags -eq [Security.AccessControl.InheritanceFlags]::ContainerInherit )
    {
        if( $propFlagsInheritOnly )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::SubContainers
        }
        elseif( $propFlagsInheritOnlyNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ChildContainers
        }
        elseif( $propFlagsNone )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainers
        }
        elseif( $propFlagsNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndChildContainers
        }
    }
    elseif( $InheritanceFlags -eq [Security.AccessControl.InheritanceFlags]::ObjectInherit )
    {
        if( $propFlagsInheritOnly )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::Leaves
        }
        elseif( $propFlagsInheritOnlyNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ChildLeaves
        }
        elseif( $propFlagsNone )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndLeaves
        }
        elseif( $propFlagsNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndChildLeaves
        }
    }
    elseif( $InheritanceFlags -eq ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit ) )
    {
        if( $propFlagsInheritOnly )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::SubContainersAndLeaves
        }
        elseif( $propFlagsInheritOnlyNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ChildContainersAndChildLeaves
        }
        elseif( $propFlagsNone )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainersAndLeaves
        }
        elseif( $propFlagsNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndChildContainersAndChildLeaves
        }
    }
}



function ConvertTo-CInheritanceFlag
{
    <#
    .SYNOPSIS
    Converts a `Carbon.Security.ContainerInheritanceFlags` value to a `System.Security.AccessControl.InheritanceFlags` value.

    .DESCRIPTION
    The `Carbon.Security.ContainerInheritanceFlags` enumeration encapsulates oth `System.Security.AccessControl.InheritanceFlags` and `System.Security.AccessControl.PropagationFlags`.  Make sure you also call `ConvertTo-CPropagationFlag` to get the propagation value.

    .OUTPUTS
    System.Security.AccessControl.InheritanceFlags.

    .LINK
    ConvertTo-CPropagationFlag

    .LINK
    Grant-CPermission

    .EXAMPLE
    ConvertTo-CInheritanceFlag -ContainerInheritanceFlag ContainerAndSubContainersAndLeaves

    Returns `InheritanceFlags.ContainerInherit|InheritanceFlags.ObjectInherit`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Security.ContainerInheritanceFlags]
        # The value to convert to an `InheritanceFlags` value.
		[Alias('ContainerInheritanceFlags')]
        $ContainerInheritanceFlag,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name
    }

    $Flags = [Security.AccessControl.InheritanceFlags]
    $map = @{
        'Container' =                                  $Flags::None;
        'SubContainers' =                              $Flags::ContainerInherit;
        'Leaves' =                                     $Flags::ObjectInherit;
        'ChildContainers' =                            $Flags::ContainerInherit;
        'ChildLeaves' =                                $Flags::ObjectInherit;
        'ContainerAndSubContainers' =                  $Flags::ContainerInherit;
        'ContainerAndLeaves' =                         $Flags::ObjectInherit;
        'SubContainersAndLeaves' =                    ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ContainerAndChildContainers' =                $Flags::ContainerInherit;
        'ContainerAndChildLeaves' =                    $Flags::ObjectInherit;
        'ContainerAndChildContainersAndChildLeaves' = ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ContainerAndSubContainersAndLeaves' =        ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ChildContainersAndChildLeaves' =             ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
    }
    $key = $ContainerInheritanceFlag.ToString()
    if( $map.ContainsKey( $key) )
    {
        return $map[$key]
    }

    Write-Error ('Unknown Carbon.Security.ContainerInheritanceFlags enumeration value {0}.' -f $ContainerInheritanceFlag)
}

Set-Alias -Name 'ConvertTo-InheritanceFlags' -Value 'ConvertTo-CInheritanceFlag'



function ConvertTo-CPropagationFlag
{
    <#
    .SYNOPSIS
    Converts a `Carbon.Security.ContainerInheritanceFlags` value to a `System.Security.AccessControl.PropagationFlags` value.

    .DESCRIPTION
    The `Carbon.Security.ContainerInheritanceFlags` enumeration encapsulates oth `System.Security.AccessControl.PropagationFlags` and `System.Security.AccessControl.InheritanceFlags`.  Make sure you also call `ConvertTo-InheritancewFlags` to get the inheritance value.

    .OUTPUTS
    System.Security.AccessControl.PropagationFlags.

    .LINK
    ConvertTo-CInheritanceFlag

    .LINK
    Grant-CPermission

    .EXAMPLE
    ConvertTo-CPropagationFlag -ContainerInheritanceFlag ContainerAndSubContainersAndLeaves

    Returns `PropagationFlags.None`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Security.ContainerInheritanceFlags]
        # The value to convert to an `PropagationFlags` value.
		[Alias('ContainerInheritanceFlags')]
        $ContainerInheritanceFlag,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name
    }

    $Flags = [Security.AccessControl.PropagationFlags]
    $map = @{
        'Container' =                                  $Flags::None;
        'SubContainers' =                              $Flags::InheritOnly;
        'Leaves' =                                     $Flags::InheritOnly;
        'ChildContainers' =                           ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
        'ChildLeaves' =                               ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
        'ContainerAndSubContainers' =                  $Flags::None;
        'ContainerAndLeaves' =                         $Flags::None;
        'SubContainersAndLeaves' =                     $Flags::InheritOnly;
        'ContainerAndChildContainers' =                $Flags::NoPropagateInherit;
        'ContainerAndChildLeaves' =                    $Flags::NoPropagateInherit;
        'ContainerAndChildContainersAndChildLeaves' =  $Flags::NoPropagateInherit;
        'ContainerAndSubContainersAndLeaves' =         $Flags::None;
        'ChildContainersAndChildLeaves' =             ($Flags::InheritOnly -bor $Flags::NoPropagateInherit);
    }
    $key = $ContainerInheritanceFlag.ToString()
    if( $map.ContainsKey( $key ) )
    {
        return $map[$key]
    }

    Write-Error ('Unknown Carbon.Security.ContainerInheritanceFlags enumeration value {0}.' -f $ContainerInheritanceFlag)
}

Set-Alias -Name 'ConvertTo-PropagationFlags' -Value 'ConvertTo-CPropagationFlag'



function ConvertTo-CSecurityIdentifier
{
    <#
    .SYNOPSIS
    Converts a string or byte array security identifier into a `System.Security.Principal.SecurityIdentifier` object.

    .DESCRIPTION
    `ConvertTo-CSecurityIdentifier` converts a SID in SDDL form (as a string), in binary form (as a byte array) into a `System.Security.Principal.SecurityIdentifier` object. It also accepts `System.Security.Principal.SecurityIdentifier` objects, and returns them back to you.

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

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter. The SID you passed in will be returned to you unchanged.

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        # The SID to convert to a `System.Security.Principal.SecurityIdentifier`. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
        $SID,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
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



function ConvertTo-ProviderAccessControlRights
{
    <#
    .SYNOPSIS
    Converts strings into the appropriate access control rights for a PowerShell provider (e.g. FileSystemRights or
    RegistryRights).

    .DESCRIPTION
    This is an internal Carbon function, so you're not getting anything more than the synopsis.

    .EXAMPLE
    ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read','Write'

    Demonstrates how to convert `Read` and `Write` into a `System.Security.AccessControl.FileSystemRights` value.
    #>
    [CmdletBinding()]
    param(
        # The provider name.
        [Parameter(Mandatory)]
        [ValidateSet('FileSystem', 'Registry', 'CryptoKey')]
        [String] $ProviderName,

        # The values to convert.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $toFS = $ProviderName -eq 'FileSystem'
        $rightTypeName = 'Security.AccessControl.{0}Rights' -f $ProviderName

        # CryptoKey does not exist in .NET standard/core so we will have to use FileSystem instead
        if ($ProviderName -eq 'CryptoKey' -and -not (Test-CCryptoKeyAvailable))
        {
            $toFS = $true
            $rightTypeName = 'Security.AccessControl.FileSystemRights'
        }

        $rights = 0 -as $rightTypeName

        $foundInvalidRight = $false

        $genericToFSMap = @{
            GenericAll = 'FullControl';
            GenericExecute = 'ExecuteFile';
            GenericWrite = 'Write';
            GenericRead = 'Read';
        }
        Write-Debug "[ConvertTo-ProviderAccessControlRights]"
    }

    process
    {
        Write-Debug "  ${InputObject}"
        foreach ($value in $InputObject)
        {
            if ($toFS -and $genericToFSMap.ContainsKey($value))
            {
                $value = $genericToFSMap[$value]
            }

            $right = $value -as $rightTypeName
            if (-not $right)
            {
                $allowedValues = [Enum]::GetNames($rightTypeName)
                Write-Error ("System.Security.AccessControl.{0}Rights value '{1}' not found.  Must be one of: {2}." -f $providerName,$_,($allowedValues -join ' '))
                $foundInvalidRight = $true
                return
            }
            Write-Debug "    ${value} → ${right}/0x$($right.ToString('x'))"
            $rights = $rights -bor $right
        }
    }

    end
    {
        if( $foundInvalidRight )
        {
            Write-Debug "  null"
            return $null
        }
        else
        {
            Write-Debug "  ${rights}/0x$($rights.ToString('x'))"
            $rights
        }
        Write-Debug "[ConvertTo-ProviderAccessControlRights]"
    }
}



function ConvertTo-Key
{
    param(
        $From,
        $InputObject
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $InputObject -isnot [byte[]] )
    {
        if( $InputObject -is [SecureString] )
        {
            $InputObject = Convert-CSecureStringToString -SecureString $InputObject -NoWarn
        }
        elseif( $InputObject -isnot [string] )
        {
            Write-Error -Message ('Encryption key must be a SecureString, a string, or an array of bytes not a {0}. If you are passing an array of bytes, make sure you explicitly cast it as a `byte[]`, e.g. `([byte[]])@( ... )`.' -f $InputObject.GetType().FullName)
            return
        }

        $Key = [Text.Encoding]::UTF8.GetBytes($InputObject)
    }
    else
    {
        $Key = $InputObject
    }

    if( $Key.Length -ne 128/8 -and $Key.Length -ne 192/8 -and $Key.Length -ne 256/8 )
    {
        Write-Error -Message ('Key is the wrong length. {0} is using AES, which requires a 128-bit, 192-bit, or 256-bit key (16, 24, or 32 bytes, respectively). You passed a key of {1} bits ({2} bytes).' -f $From,($Key.Length*8),$Key.Length)
        return
    }

    return $Key
}



function ConvertTo-ProviderAccessControlRights
{
    <#
    .SYNOPSIS
    Converts strings into the appropriate access control rights for a PowerShell provider (e.g. FileSystemRights or
    RegistryRights).

    .DESCRIPTION
    This is an internal Carbon function, so you're not getting anything more than the synopsis.

    .EXAMPLE
    ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read','Write'

    Demonstrates how to convert `Read` and `Write` into a `System.Security.AccessControl.FileSystemRights` value.
    #>
    [CmdletBinding()]
    param(
        # The provider name.
        [Parameter(Mandatory)]
        [ValidateSet('FileSystem', 'Registry', 'CryptoKey')]
        [String] $ProviderName,

        # The values to convert.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $toFS = $ProviderName -eq 'FileSystem'
        $rightTypeName = 'Security.AccessControl.{0}Rights' -f $ProviderName

        # CryptoKey does not exist in .NET standard/core so we will have to use FileSystem instead
        if ($ProviderName -eq 'CryptoKey' -and -not (Test-CCryptoKeyAvailable))
        {
            $toFS = $true
            $rightTypeName = 'Security.AccessControl.FileSystemRights'
        }

        $rights = 0 -as $rightTypeName

        $foundInvalidRight = $false

        $genericToFSMap = @{
            GenericAll = 'FullControl';
            GenericExecute = 'ExecuteFile';
            GenericWrite = 'Write';
            GenericRead = 'Read';
        }
        Write-Debug "[ConvertTo-ProviderAccessControlRights]"
    }

    process
    {
        Write-Debug "  ${InputObject}"
        foreach ($value in $InputObject)
        {
            if ($toFS -and $genericToFSMap.ContainsKey($value))
            {
                $value = $genericToFSMap[$value]
            }

            $right = $value -as $rightTypeName
            if (-not $right)
            {
                $allowedValues = [Enum]::GetNames($rightTypeName)
                Write-Error ("System.Security.AccessControl.{0}Rights value '{1}' not found.  Must be one of: {2}." -f $providerName,$_,($allowedValues -join ' '))
                $foundInvalidRight = $true
                return
            }
            Write-Debug "    ${value} → ${right}/0x$($right.ToString('x'))"
            $rights = $rights -bor $right
        }
    }

    end
    {
        if( $foundInvalidRight )
        {
            Write-Debug "  null"
            return $null
        }
        else
        {
            Write-Debug "  ${rights}/0x$($rights.ToString('x'))"
            $rights
        }
        Write-Debug "[ConvertTo-ProviderAccessControlRights]"
    }
}


function Copy-CDscResource
{
    <#
    .SYNOPSIS
    Copies DSC resources.

    .DESCRIPTION
    This function copies a DSC resource or a directory of DSC resources to a DSC pull server share/website. All files under `$Path` are copied.

    DSC requires all files have a checksum file (e.g. `localhost.mof.checksum`), which this function generates for you (in a temporary location).

    Only new files, or files whose checksums have changed, are copied. You can force all files to be copied with the `Force` switch.

    `Copy-CDscResource` is new in Carbon 2.0.

    .EXAMPLE
    Copy-CDscResource -Path 'localhost.mof' -Destination '\\dscserver\DscResources'

    Demonstrates how to copy a single resource to a resources SMB share. `localhost.mof` will only be copied if its checksum is different than what is in `\\dscserver\DscResources`.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources'

    Demonstrates how to copy a directory of resources. Only files in the directory are copied. Every file in the source must have a `.checksum` file. Only files whose checksums are different between source and destination will be copied.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources' -Recurse

    Demonstrates how to recursively copy files.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources' -Force

    Demonstrates how to copy all files, even if their `.checksum` files are the  same.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources' -PassThru

    Demonstrates how to get `System.IO.FileInfo` objects for all resources copied to the destination. If all files are up-to-date, nothing is copied, and no objects are returned.
    #>
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the DSC resource to copy. If a directory is given, all files in that directory are copied. Wildcards supported.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The directory where the resources should be copied.
        $Destination,

        [Switch]
        # Recursively copy files from the source directory.
        $Recurse,

        [Switch]
        # Returns `IO.FileInfo` objects for each item copied to `Destination`.
        $PassThru,

        [Switch]
        # Copy resources, even if they are the same on the destination server.
        $Force,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    $tempDir = New-CTempDirectory -Prefix 'Carbon+Copy-CDscResource+'

    try
    {
        foreach( $item in (Get-ChildItem -Path $Path -Exclude '*.checksum') )
        {
            $destinationPath = Join-Path -Path $Destination -ChildPath $item.Name
            if( $item.PSIsContainer )
            {
                if( $Recurse )
                {
                    if( -not (Test-Path -Path $destinationPath -PathType Container) )
                    {
                        New-Item -Path $destinationPath -ItemType 'Directory' | Out-Null
                    }
                    Copy-CDscResource -Path $item.FullName -Destination $destinationPath -Recurse -Force:$Force -PassThru:$PassThru
                }
                continue
            }

            $sourceChecksumPath = '{0}.checksum' -f $item.Name
            $sourceChecksumPath = Join-Path -Path $tempDir -ChildPath $sourceChecksumPath
            $sourceChecksum = Get-FileHash -Path $item.FullName | Select-Object -ExpandProperty 'Hash'
            # hash files can't have any newline characters, so we can't use Set-Content
            [IO.File]::WriteAllText($sourceChecksumPath, $sourceChecksum)

            $destinationChecksum = ''

            $destinationChecksumPath = '{0}.checksum' -f $destinationPath
            if( (Test-Path -Path $destinationChecksumPath -PathType Leaf) )
            {
                $destinationChecksum = Get-Content -TotalCount 1 -Path $destinationChecksumPath
            }

            if( $Force -or -not (Test-Path -Path $destinationPath -PathType Leaf) -or ($sourceChecksum -ne $destinationChecksum) )
            {
                Copy-Item -Path $item -Destination $Destination -PassThru:$PassThru
                Copy-Item -Path $sourceChecksumPath -Destination $Destination -PassThru:$PassThru
            }
            else
            {
                Write-Verbose ('File ''{0}'' already up-to-date.' -f $destinationPath)
            }
        }
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Ignore
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



function Get-CDscError
{
    <#
    .SYNOPSIS
    Gets DSC errors from a computer's event log.

    .DESCRIPTION
    The DSC Local Configuration Manager (LCM) writes any errors it encounters to the `Microsoft-Windows-DSC/Operational` event log, in addition to some error messages that report that encountered an error. This function gets just the important error log messages, skipping the superflous ones that won't help you track down where the problem is.

    By default, errors on the local computer are returned. You can return errors from another computer via the `ComputerName` parameter.

    You can filter the results further with the `StartTime` and `EndTime` parameters. `StartTime` will return entries after the given time. `EndTime` will return entries before the given time.

    If no items are found, nothing is returned.

    It can take several seconds for event log entries to get written to the log, so you might not get results back. If you want to wait for entries to come back, use the `-Wait` switch. You can control how long to wait (in seconds) via the `WaitTimeoutSeconds` parameter. The default is 10 seconds.

    When getting errors on a remote computer, that computer must have Remote Event Log Management firewall rules enabled. To enable them, run

        Get-CFirewallRule -Name '*Remove Event Log Management*' |
            ForEach-Object { netsh advfirewall firewall set rule name= $_.Name new enable=yes }

    `Get-CDscError` is new in Carbon 2.0.

    .OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

    .LINK
    Write-CDscError

    .EXAMPLE
    Get-CDscWinEvent

    Demonstrates how to get all the DSC errors from the local computer.

    .EXAMPLE
    Get-CDscError -ComputerName 10.1.2.3

    Demonstrates how to get all the DSC errors from a specific computer.

    .EXAMPLE
    Get-CDscError -StartTime '8/1/2014 0:00'

    Demonstrates how to get errors that occurred *after* a given time.

    .EXAMPLE
    Get-CDscError -EndTime '8/30/2014 11:59:59'

    Demonstrates how to get errors that occurred *before* a given time.

    .EXAMPLE
    Get-CDscError -StartTime '8/1/2014 2:58 PM' -Wait -WaitTimeoutSeconds 5

    Demonstrates how to wait for entries that match the specified criteria to appear in the event log. It can take several seconds between the time a log entry is written to when you can read it.
    #>
    [CmdletBinding(DefaultParameterSetName='NoWait')]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [string[]]
        # The computer whose DSC errors to return.
        $ComputerName,

        [DateTime]
        # Get errors that occurred after this date/time.
        $StartTime,

        [DateTime]
        # Get errors that occurred before this date/time.
        $EndTime,

        [Parameter(Mandatory=$true,ParameterSetName='Wait')]
        [Switch]
        # Wait for entries to appear, as it can sometimes take several seconds for entries to get written to the event log.
        $Wait,

        [Parameter(ParameterSetName='Wait')]
        [uint32]
        # The time to wait for entries to appear before giving up. Default is 10 seconds. There is no way to wait an infinite amount of time.
        $WaitTimeoutSeconds = 10,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    Get-CDscWinEvent @PSBoundParameters -ID 4103 -Level ([Diagnostics.Eventing.Reader.StandardEventLevel]::Error)
}


function Get-CDscWinEvent
{
    <#
    .SYNOPSIS
    Gets events from the DSC Windows event log.

    .DESCRIPTION
    Thie `Get-CDscWinEvent` function gets log entries from the `Microsoft-Windows-DSC/Operational` event log, where the Local Configuration Manager writes events. By default, entries on the local computer are returned. You can return entries from another computer via the `ComputerName` parameter.

    You can filter the results further with the `ID`, `Level`, `StartTime` and `EndTime` parameters. `ID` will get events with the specific ID. `Level` will get events at the specified level. `StartTime` will return entries after the given time. `EndTime` will return entries before the given time.

    If no items are found, nothing is returned.

    It can take several seconds for event log entries to get written to the log, so you might not get results back. If you want to wait for entries to come back, use the `-Wait` switch. You can control how long to wait (in seconds) via the `WaitTimeoutSeconds` parameter. The default is 10 seconds.

    When getting errors on a remote computer, that computer must have Remote Event Log Management firewall rules enabled. To enable them, run

        Get-CFirewallRule -Name '*Remove Event Log Management*' |
            ForEach-Object { netsh advfirewall firewall set rule name= $_.Name new enable=yes }

    `Get-CDscWinEvent` is new in Carbon 2.0.

    .OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

    .LINK
    Write-CDscError

    .LINK
    Get-CDscWinEvent

    .EXAMPLE
    Get-CDscWinEvent

    Demonstrates how to get all the DSC errors from the local computer.

    .EXAMPLE
    Get-CDscWinEvent -ComputerName 10.1.2.3

    Demonstrates how to get all the DSC errors from a specific computer.

    .EXAMPLE
    Get-CDscWinEvent -StartTime '8/1/2014 0:00'

    Demonstrates how to get errors that occurred *after* a given time.

    .EXAMPLE
    Get-CDscWinEvent -EndTime '8/30/2014 11:59:59'

    Demonstrates how to get errors that occurred *before* a given time.

    .EXAMPLE
    Get-CDscWinEvent -StartTime '8/1/2014 2:58 PM' -Wait -WaitTimeoutSeconds 5

    Demonstrates how to wait for entries that match the specified criteria to appear in the event log. It can take several seconds between the time a log entry is written to when you can read it.

    .EXAMPLE
    Get-CDscWinEvent -Level ([Diagnostics.Eventing.Reader.StandardEventLevel]::Error)

    Demonstrates how to get events at a specific level, in this case, only error level entries will be returned.

    .EXAMPLE
    Get-CDscWinEvent -ID 4103

    Demonstrates how to get events with a specific ID, in this case `4103`.
    #>
    [CmdletBinding(DefaultParameterSetName='NoWait')]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [string[]]
        # The computer whose DSC errors to return.
        $ComputerName,

        [int]
        # The event ID. Only events with this ID will be returned.
        $ID,

        [int]
        # The level. Only events at this level will be returned.
        $Level,

        [DateTime]
        # Get errors that occurred after this date/time.
        $StartTime,

        [DateTime]
        # Get errors that occurred before this date/time.
        $EndTime,

        [Parameter(Mandatory=$true,ParameterSetName='Wait')]
        [Switch]
        # Wait for entries to appear, as it can sometimes take several seconds for entries to get written to the event log.
        $Wait,

        [Parameter(ParameterSetName='Wait')]
        [uint32]
        # The time to wait for entries to appear before giving up. Default is 10 seconds. There is no way to wait an infinite amount of time.
        $WaitTimeoutSeconds = 10,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    $filter = @{
                    LogName = 'Microsoft-Windows-DSC/Operational';
              }

    if( $ID )
    {
        $filter['ID'] = $ID
    }

    if( $Level )
    {
        $filter['Level'] = $Level
    }

    if( $StartTime )
    {
        $filter['StartTime'] = $StartTime
    }

    if( $EndTime )
    {
        $filter['EndTime'] = $EndTime
    }

    function Invoke-GetWinEvent
    {
        param(
            [string]
            $ComputerName
        )

        Set-StrictMode -Version 'Latest'

        $startedAt = Get-Date
        $computerNameParam = @{ }
        if( $ComputerName )
        {
            $computerNameParam['ComputerName'] = $ComputerName
        }

        try
        {
            $events = @()
            while( -not ($events = Get-WinEvent @computerNameParam -FilterHashtable $filter -ErrorAction Ignore -Verbose:$false) )
            {
                if( $PSCmdlet.ParameterSetName -ne 'Wait' )
                {
                    break
                }

                Start-Sleep -Milliseconds 100

                [timespan]$duration = (Get-Date) - $startedAt
                if( $duration.TotalSeconds -gt $WaitTimeoutSeconds )
                {
                    break
                }
            }
            return $events
        }
        catch
        {
            if( $_.Exception.Message -eq 'The RPC server is unavailable' )
            {
                Write-Error -Message ("Unable to connect to '{0}': it looks like Remote Event Log Management isn't running or is blocked by the computer's firewall. To allow this traffic through the firewall, run the following command on '{0}':`n`tGet-FirewallRule -Name '*Remove Event Log Management*' |`n`t`t ForEach-Object {{ netsh advfirewall firewall set rule name= `$_.Name new enable=yes }}." -f $ComputerName)
            }
            else
            {
                Write-Error -Exception $_.Exception
            }
        }
    }

    if( $ComputerName )
    {
        $ComputerName = $ComputerName |
                            Where-Object {
                                # Get just the computers that exist.
                                if( (Test-Connection -ComputerName $ComputerName -Quiet) )
                                {
                                    return $true
                                }
                                else
                                {
                                    Write-Error -Message ('Computer ''{0}'' not found.' -f $ComputerName)
                                    return $false
                                }
                            }

        if( -not $ComputerName )
        {
            return
        }

        $ComputerName | ForEach-Object { Invoke-GetWinEvent -ComputerName $_ }
    }
    else
    {
        Invoke-GetWinEvent
    }
}

function Get-CFileShare
{
    <#
    .SYNOPSIS
    Gets the file/SMB shares on the local computer.

    .DESCRIPTION
    The `Get-CFileShare` function uses WMI to get the file/SMB shares on the current/local computer. The returned objects are `Win32_Share` WMI objects.

    Use the `Name` paramter to get a specific file share by its name. If a share with the given name doesn't exist, an error is written and nothing is returned.

    The `Name` parameter supports wildcards. If you're using wildcards to find a share, and no shares are found, no error is written and nothing is returned.

    `Get-CFileShare` was added in Carbon 2.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa394435.aspx

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Test-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Get-CFileShare

    Demonstrates how to get all the file shares on the local computer.

    .EXAMPLE
    Get-CFileShare -Name 'Build'

    Demonstrates how to get a specific file share.

    .EXAMPLE
    Get-CFileShare -Name 'Carbon*'

    Demonstrates that you can use wildcards to find all shares that match a wildcard pattern.
    #>
    [CmdletBinding()]
    param(
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters,
        # you'll need to escape them.
        [String] $Name,

        # Force the returned object to be a WMI object, not a CIM object.
        [switch] $AsWmiObject,

        # Hide the warning that this command is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                  -NewCommandName 'Get-SmbShare' `
                                  -NewModuleName 'SmbShare' `
                                  -NewCommandBuiltin `
                                  -NoWarn:$NoWarn

    $filter = '(Type = 0 or Type = 2147483648)'
    $wildcardSearch = [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
    if( $Name -and -not $wildcardSearch)
    {
        $filter = '{0} and Name = ''{1}''' -f $filter,$Name
    }

    $shares = Get-CCimInstance -Class 'Win32_Share' -Filter $filter -AsWmiObject:$AsWmiObject |
                    Where-Object {
                        if( -not $wildcardSearch )
                        {
                            return $true
                        }

                        return $_.Name -like $Name
                    }

    if( $Name -and -not $shares -and -not $wildcardSearch )
    {
        Write-Error ('Share ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
    }

    $shares
}


function Get-CFileSharePermission
{
    <#
    .SYNOPSIS
    Gets the sharing permissions on a file/SMB share.

    .DESCRIPTION
    The `Get-CFileSharePermission` function uses WMI to get the sharing permission on a file/SMB share. It returns the permissions as a `Carbon.Security.ShareAccessRule` object, which has the following properties:

     * ShareRights: the rights the user/group has on the share.
     * IdentityReference: an `Security.Principal.NTAccount` for the user/group who has permission.
     * AccessControlType: the type of access control being granted: Allow or Deny.

    The `ShareRights` are values from the `Carbon.Security.ShareRights` enumeration. There are four values:

     * Read
     * Change
     * FullControl
     * Synchronize

    If the share doesn't exist, nothing is returned and an error is written.

    Use the `Identity` parameter to get a specific user/group's permissions. Wildcards are supported.

    `Get-CFileSharePermission` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Install-CFileShare

    .LINK
    Test-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Get-CFileSharePermission -Name 'Build'

    Demonstrates how to get all the permissions on the `Build` share.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Security.ShareAccessRule])]
    param(
        # The share's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # Get permissions for a specific identity. Wildcards supported.
        [String] $Identity,

        # Hide the warning that this command is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                  -NewCommandName 'Get-SmbShareAccess' `
                                  -NewModuleName 'SmbShare' `
                                  -NewCommandBuiltin `
                                  -NoWarn:$NoWarn

    $sd = Get-CFileShareSecurityDescriptor -Name $Name
    if( -not $sd -or -not $sd.DACL )
    {
        return
    }

    if( $Identity )
    {
        if( -not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters( $Identity ) )
        {
            $Identity = Resolve-CIdentityName -Name $Identity -NoWarn -ErrorAction $ErrorActionPreference
            if( -not $Identity )
            {
                return
            }
        }
    }

    foreach($ace in $SD.DACL)
    {
        if( -not $ace -or -not $ace.Trustee )
        {
            continue
        }

        [Carbon.Identity]$rId = [Carbon.Identity]::FindBySid( $ace.Trustee.SIDString )
        if( $Identity -and  (-not $rId -or $rId.FullName -notlike $Identity) )
        {
            continue
        }

        if( $rId )
        {
            $aceId = New-Object 'Security.Principal.NTAccount' $rId.FullName
        }
        else
        {
            $aceId = New-Object 'Security.Principal.SecurityIdentifier' $ace.Trustee.SIDString
        }

        New-Object 'Carbon.Security.ShareAccessRule' $aceId, $ace.AccessMask, $ace.AceType
    }
}


function Get-CFileShareSecurityDescriptor
{
    <#
    .SYNOPSIS
    INTERNAL

    .DESCRIPTION
    INTERNAL

    .EXAMPLE
    INTERNAL
    #>
    [CmdletBinding()]
    param(
        # The share's name.
        [Parameter(Mandatory=$true)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name $Name -NoWarn
    if( -not $share )
    {
        return
    }

    $lsss = Get-CCimInstance -Class 'Win32_LogicalShareSecuritySetting' -Filter "name='$($Name)'"
    if( -not $lsss )
    {
        return
    }

    if( Test-CCimAvailable )
    {
        $result = Invoke-CimMethod -InputObject $lsss -MethodName 'GetSecurityDescriptor'
    }
    else
    {
        $result = $lsss.GetSecurityDescriptor()
    }

    if( -not $result )
    {
        return
    }

    if( $result.ReturnValue )
    {
        $win32lsssErrors = @{
            [uint32]2 = 'Access Denied';
            [uint32]8 = 'Unknown Failure';
            [uint32]9 = 'Privilege Missing';
            [uint32]21 = 'Invalid Parameter';
        }

        $msg = "Failed to get ""$($Name)"" share''s security descriptor: WMI error code $($result.ReturnValue): " +
               "$($win32lsssErrors[$result.ReturnValue])."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result.Descriptor
}


function Get-CGroup
{
    <#
    .SYNOPSIS
    Gets *local* groups.

    .DESCRIPTION
    `Get-CGroup` gets all *local* groups or a specific group by its name.

    The objects returned, `DirectoryServices.AccountManagement.GroupPrincipal`, use external resources, which means they don't clean up propertly when garbage collected, resulting in memory leaks. You should call `Dispose()` on the objects you receieve from this function when you're done using them so these external resources can be cleaned up correctly.

    `Get-CGroup` is new in Carbon 2.0.

    .OUTPUTS
    System.DirectoryServices.AccountManagement.GroupPrincipal.

    .LINK
    Get-CUser

    .EXAMPLE
    Get-CGroup

    Demonstrates how to get all local groups.

    .EXAMPLE
    Get-CGroup -Name RebelAlliance

    Demonstrates how to get a specific group.
    #>
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        # The name of the group to return.
        [string]$Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Get-CLocalGroup' `
                                    -NoWarn:$NoWarn

    Write-Timing ('Get-CGroup')

    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $query = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
    try
    {
        $groups = Get-CPrincipal -Principal $query -Filter {
            if( $Name )
            {
                return $_.Name -eq $Name
            }
            return $true
        }

        if( $Name )
        {
            $groupCount = $groups | Measure-Object | Select-Object -ExpandProperty 'Count'
            if( $groupCount -gt 1 )
            {
                Write-Error -Message ('Found {0} groups named "{1}".' -f $groupCount,$Name) -ErrorAction:$ErrorActionPreference
                return
            }

            if( $groupCount -eq 0 )
            {
                Write-Error ('Local group "{0}" not found.' -f $Name) -ErrorAction:$ErrorActionPreference
                return
            }
        }

        return $groups
    }
    finally
    {
        $query.Dispose()
        Write-Timing ('Get-CGroup')
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

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Core' -NoWarn:$NoWarn

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



# Leave these here so that when Get-CPermission moves to its own module, these go with it.
Add-CTypeData -Type IO.DirectoryInfo `
              -MemberName 'GetAccessControl' `
              -MemberType ScriptMethod `
              -Value {
                    [CmdletBinding()]
                    param(
                        [Security.AccessControl.AccessControlSections] $IncludeSections =
                            [Security.AccessControl.AccessControlSections]::All
                    )

                    return [IO.FileSystemAclExtensions]::GetAccessControl($this, $IncludeSections)
                }

Add-CTypeData -Type IO.FileInfo `
              -MemberName 'GetAccessControl' `
              -MemberType ScriptMethod `
              -Value {
                    [CmdletBinding()]
                    param(
                        [Security.AccessControl.AccessControlSections]$IncludeSections =
                            [Security.AccessControl.AccessControlSections]::All
                    )

                    return [IO.FileSystemAclExtensions]::GetAccessControl($this, $IncludeSections)
                }

function Get-CPermission
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a file, directory, registry key, or certificate's private key/key
    container.

    .DESCRIPTION
    Permissions for a specific identity can also be returned.  Access control entries are for a path's discretionary
    access control list.

    To return inherited permissions, use the `Inherited` switch.  Otherwise, only non-inherited (i.e. explicit)
    permissions are returned.

    Certificate permissions are only returned if a certificate has a private key/key container. If a certificate doesn't
    have a private key, `$null` is returned.

    .OUTPUTS
    System.Security.AccessControl.AccessRule.

    .LINK
    Disable-CAclInheritance

    .LINK
    Enable-CAclInheritance

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    Get-CPermission -Path 'C:\Windows'

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on
    `C:\windows`.

    .EXAMPLE
    Get-CPermission -Path 'hklm:\Software' -Inherited

    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on
    `hklm:\software`.

    .EXAMPLE
    Get-CPermission -Path 'C:\Windows' -Idenity Administrators

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on
    `C:\windows`.

    .EXAMPLE
    Get-CPermission -Path 'Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678'

    Returns `System.Security.AccessControl.CryptoKeyAccesRule` objects for certificate's
    `Cert:\LocalMachine\1234567890ABCDEF1234567890ABCDEF12345678` private key/key container. If it doesn't have a
    private key, `$null` is returned.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.AccessRule])]
    param(
        # The path whose permissions (i.e. access control rules) to return. File system, registry, or certificate paths
        # supported. Wildcards supported.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity whose permissiosn (i.e. access control rules) to return.
        [String] $Identity,

        # Return inherited permissions in addition to explicit permissions.
        [switch] $Inherited,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        $msg = "Carbon's $($MyInvocation.MyCommand.Name) function moved to the Carbon.Cryptography, " +
               'Carbon.FileSystem, and Carbon.Registry modules as Get-CPrivateKeyPermission, Get-CNtfsPermission, ' +
               "and Get-CRegistryPermission, respectively. The $($MyInvocation.MyCommand.Name) function will be " +
               'removed from the next major version of Carbon. Please switch to the new functions and modules, ' +
               'available on the PowerShell Gallery.'
        Write-CWarningOnce -Message $msg
    }

    $account = $null
    if( $Identity )
    {
        $account = Test-CIdentity -Name $Identity -PassThru -NoWarn
        if( $account )
        {
            $Identity = $account.FullName
        }
    }

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $Path)
        return
    }

    & {
            foreach ($item in (Get-Item -Path $Path -Force))
            {
                if( $item.PSProvider.Name -ne 'Certificate' )
                {
                    $item.GetAccessControl([Security.AccessControl.AccessControlSections]::Access) | Write-Output
                    continue
                }

                if (-not $item.HasPrivateKey)
                {
                    continue
                }

                if ($item.PrivateKey -and ($item.PrivateKey | Get-Member 'CspKeyContainerInfo'))
                {
                    $item.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity | Write-Output
                    continue
                }

                $item | Resolve-CPrivateKeyPath | Get-Acl | Write-Output
            }
        } |
        Select-Object -ExpandProperty 'Access' |
        Where-Object {
            if( $Inherited )
            {
                return $true
            }
            return (-not $_.IsInherited)
        } |
        Where-Object {
            if( $Identity )
            {
                return ($_.IdentityReference.Value -eq $Identity)
            }

            return $true
        }
}

Set-Alias -Name 'Get-Permissions' -Value 'Get-CPermission'


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



function Get-CPrivilege
{
    <#
    .SYNOPSIS
    Gets an identity's privileges.

    .DESCRIPTION
    These privileges are usually managed by Group Policy and control the system operations and types of logons a user/group can perform.

    Note: if a computer is not on a domain, this function won't work.

    .OUTPUTS
    System.String

    .LINK
    Grant-CPrivilege

    .LINK
    Revoke-Prvileges

    .LINK
    Test-CPrivilege

    .EXAMPLE
    Get-CPrivilege -Identity TheBeast

    Gets `TheBeast`'s privileges as an array of strings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose privileges to return.
        $Identity,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Security'
    }

    [Carbon.Security.Privilege]::GetPrivileges( $Identity )
}

Set-Alias -Name 'Get-Privileges' -Value 'Get-CPrivilege'




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
        [string] $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Windows.Installer' `
                                    -NewCommandName 'Get-CInstalledProgram' `
                                    -NoWarn:$NoWarn

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



# Leave this here so when Get-CScheduledTask moves to a Carbon.ScheduledTask module, this goes with it.
# COM object Schedule.Service
Add-CTypeData -TypeName 'System.__ComObject#{9c86f320-dee3-4dd1-b972-a303f26b061e}' `
              -MemberName 'Status' `
              -MemberType ScriptProperty `
              -Value {
                    switch( $this.State )
                    {
                        1 { return "Disabled" }
                        2 { return "Queued" }
                        3 { return "Ready" }
                        4 { return "Running" }
                        default { return "Unknown" }
                    }
                }

function Get-CScheduledTask
{
    <#
    .SYNOPSIS
    Gets the scheduled tasks for the current computer.

    .DESCRIPTION
    The `Get-CScheduledTask` function gets the scheduled tasks on the current computer. It returns `Carbon.TaskScheduler.TaskInfo` objects for each one.

    With no parameters, `Get-CScheduledTask` returns all scheduled tasks. To get a specific scheduled task, use the `Name` parameter, which must be the full name of the task, i.e. path plus name. The name parameter accepts wildcards. If a scheduled task with the given name isn't found, an error is written.

    By default, `Get-CScheduledTask` uses the `schtasks.exe` application to get scheduled task information. Beginning in Carbon 2.8.0, you can return `RegisteredTask` objects from the `Schedule.Service` COM API with the `AsComObject` switch. Using this switch is an order of magnitude faster. In the next major version of Carbon, this will become the default behavior.

    Before Carbon 2.7.0, this function has the same name as the built-in `Get-ScheduledTask` function that comes on Windows 2012/8 and later. It returns objects with the same properties, but if you want to use the built-in function, use the `ScheduledTasks` qualifier, e.g. `ScheduledTasks\Get-ScheduledTask`.

    .LINK
    Test-CScheduledTask

    .EXAMPLE
    Get-CScheduledTask

    Demonstrates how to get all scheduled tasks.

    .EXAMPLE
    Get-CScheduledTask -Name 'AutoUpdateMyApp'

    Demonstrates how to get a specific task.

    .EXAMPLE
    Get-CScheduledTask -Name '*Microsoft*'

    Demonstrates how to get all tasks that match a wildcard pattern.

    .EXAMPLE
    ScheduledTasks\Get-CScheduledTask

    Demonstrates how to call the `Get-CScheduledTask` function in the `ScheduledTasks` module which ships on Windows 2012/8 and later.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.TaskScheduler.TaskInfo])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to return. Wildcards supported. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [Switch]
        # Return the scheduled task as a [RegisteredTask Windows COM object](https://docs.microsoft.com/en-us/windows/desktop/taskschd/registeredtask), using the `Schedule.Service` COM API. This is faster and more reliable. See [Task Scheduler Reference](https://docs.microsoft.com/en-us/windows/desktop/taskschd/task-scheduler-reference) for more information.
        #
        # This parameter was introduced in Carbon 2.8.0.
        $AsComObject,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.ScheduledTasks'
    }

    function ConvertFrom-DurationSpec
    {
        param(
            $Duration
        )

        if( $Duration -match '^P((\d+)D)?T((\d+)H)?((\d+)M)?((\d+)S)?$' )
        {
            return New-Object 'TimeSpan' $Matches[2],$Matches[4],$Matches[6],$Matches[8]
        }
    }

    function ConvertFrom-RepetitionElement
    {
        param(
            [Xml.XmlElement]
            $TriggerElement
        )

        Set-StrictMode -Version 'Latest'

        [Carbon.TaskScheduler.ScheduleType]$scheduleType = [Carbon.TaskScheduler.ScheduleType]::Unknown
        $interval = $null
        $modifier = $null
        $duration = $null
        $stopAtEnd = $false
        [TimeSpan]$delay = [TimeSpan]::Zero

        if( $TriggerElement.GetElementsByTagName('Repetition').Count -gt 0 )
        {
            $repetition = $TriggerElement.Repetition

            $interval = $repetition.Interval
            if( $interval -match 'PT(\d+)(.*)$' )
            {
                $modifier = $Matches[1]
                $unit = $Matches[2]

                $hour = 0
                $minute = 0
                $second = 0
                switch( $unit )
                {
                    'H' { $hour = $modifier }
                    'M' { $minute = $modifier }
                }

                $scheduleTypes = @{
                                        'H' = 'Hourly';
                                        'M' = 'Minute';
                                  }
                if( $scheduleTypes.ContainsKey( $unit ) )
                {
                    $scheduleType = $scheduleTypes[$unit]
                }
                $timespan = New-Object 'TimeSpan' $hour,$minute,$second
                switch( $scheduleType )
                {
                    'Hourly' { $modifier = $timespan.TotalHours }
                    'Minute' { $modifier = $timespan.TotalMinutes }
                }
            }

            if( $repetition | Get-Member -Name 'Duration' )
            {
                $duration = $repetition.Duration
                $durationAsTimeSpan = ConvertFrom-DurationSpec -Duration $repetition.Duration
                if( $durationAsTimeSpan -ne $null )
                {
                    $duration = $durationAsTimeSpan
                }
            }

            if( $repetition | Get-Member -Name 'StopAtDurationEnd' )
            {
                $stopAtEnd = ($repetition.StopAtDurationEnd -eq 'true')
            }
        }

        if( $TriggerElement | Get-Member -Name 'Delay' )
        {
            $delayAsTimeSpan = ConvertFrom-DurationSpec -Duration $TriggerElement.Delay
            if( $delayAsTimeSpan -ne $null )
            {
                $delay = $delayAsTimeSpan
            }
        }

        return $scheduleType,$modifier,$duration,$stopAtEnd,$delay
    }

    $optionalArgs = @()
    $wildcardSearch = $false
    if( $Name )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name) )
        {
            $wildcardSearch = $true
        }
        else
        {
            $Name = Join-Path -Path '\' -ChildPath $Name
            $optionalArgs = @( '/tn', $Name )
        }
    }

    if( $AsComObject )
    {
        $taskScheduler = New-Object -ComObject 'Schedule.Service'
        $taskScheduler.Connect()


        function Get-Tasks
        {
            param(
                $Folder
            )

            $getHiddenTasks = 1

            $Folder.GetTasks($getHiddenTasks) | ForEach-Object { $_ }

            foreach( $subFolder in $Folder.GetFolders($getHiddenTasks) )
            {
                Get-Tasks -Folder $subFolder
            }
        }

        $tasks = Get-Tasks -Folder $taskScheduler.GetFolder("\") |
                    Where-Object {
                        if( -not $Name )
                        {
                            return $true
                        }

                        return $_.Path -like $Name
                    }

        if( -not $wildcardSearch -and -not $tasks )
        {
            Write-Error -Message ('Scheduled task "{0}" not found.' -f $Name) -ErrorAction $ErrorActionPreference
            return
        }

        return $tasks
    }

    $originalErrPreference = $ErrorActionPreference
    $originalEncoding = [Console]::OutputEncoding
    # Some tasks from Intel have special characters in them.
    $OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(1252)
    $ErrorActionPreference = 'Continue'
    [object[]]$output = $null
    $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Get-CScheduledTask+{0}' -f [IO.Path]::GetRandomFileName())
    try
    {
        $output = schtasks /query /v /fo csv $optionalArgs 2> $errFile |
                    ConvertFrom-Csv |
                    Where-Object { $_.HostName -ne 'HostName' }
    }
    finally
    {
        $ErrorActionPreference = $originalErrPreference
        $OutputEncoding = [Console]::OutputEncoding = $originalEncoding
    }

    if( $LASTEXITCODE )
    {
        if( (Test-Path -Path $errFile -PathType Leaf) )
        {
            $error = (Get-Content -Path $errFile) -join ([Environment]::NewLine)
            try
            {
                if( $error -match 'The\ system\ cannot\ find\ the\ (file|path)\ specified\.' )
                {
                    Write-Error ('Scheduled task ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
                }
                else
                {
                    Write-Error ($error) -ErrorAction $ErrorActionPreference
                }
            }
            finally
            {
                Remove-Item -Path $errFile
            }
        }
        return
    }

    if( -not $output )
    {
        return
    }

    $comTasks = Get-CScheduledTask -AsComObject -NoWarn

    for( $idx = 0; $idx -lt $output.Count; ++$idx )
    {
        $csvTask = $output[$idx]

        $comTask = $comTasks | Where-Object { $_.Path -eq $csvTask.TaskName }
        if( $comTask )
        {
            $xmlDoc = [xml]$comTask.Xml
        }
        else
        {
            $xml = schtasks /query /tn $csvTask.TaskName /xml | Where-Object { $_ }
            $xml = $xml -join ([Environment]::NewLine)
            $xmlDoc = [xml]$xml
        }

        $taskPath = Split-Path -Parent -Path $csvTask.TaskName
        # Get-CScheduledTask on Win2012/8 has a trailing slash so we include it here.
        if( $taskPath -ne '\' )
        {
            $taskPath = '{0}\' -f $taskPath
        }
        $taskName = Split-Path -Leaf -Path $csvTask.TaskName

        if( -not ($xmlDoc | Get-Member -Name 'Task') )
        {
            Write-Error -Message ('Unable to get information for scheduled task "{0}": XML task information is missing the "Task" element.' -f $csvTask.TaskName) -ErrorAction $ErrorActionPreference
            continue
        }

        $xmlTask = $xmlDoc.Task
        $principal = $xmlTask.Principals.Principal
        $isInteractive = $false
        $noPassword = $false
        if( $principal | Get-Member 'LogonType' )
        {
            $isInteractive = $principal.LogonType -eq 'InteractiveTokenOrPassword'
            $noPassword = $principal.LogonType -eq 'S4U'
        }

        $highestRunLevel = $false
        if( $principal | Get-Member 'RunLevel' )
        {
            $highestRunLevel = ($principal.RunLevel -eq 'HighestAvailable')
        }

        $createDate = [DateTime]::MinValue
        if( $xmlTask | Get-Member -Name 'RegistrationInfo' )
        {
            $regInfo = $xmlTask.RegistrationInfo
            if( $regInfo | Get-Member -Name 'Date' )
            {
                $createDate = [datetime]$regInfo.Date
            }
        }

        $taskToRun = $csvTask.'Task To Run'
        if( ($xmlTask | Get-Member -Name 'Actions') -and $xmlTask.Actions.ChildNodes.Count -eq 1 )
        {
            $actions = $xmlTask.Actions
            if( ($actions | Get-Member -Name 'Exec') -and ($actions.Exec | Measure-Object | Select-Object -ExpandProperty 'Count') -eq 1)
            {
                $exec = $actions.Exec

                if( $exec | Get-Member -Name 'Command' )
                {
                    $taskToRun = $exec.Command
                }

                if( $exec | Get-Member -Name 'Arguments' )
                {
                    $taskToRun = '{0} {1}' -f $taskToRun,$exec.Arguments
                }
            }
        }

        $ctorArgs = @(
                        $csvTask.HostName,
                        $taskPath,
                        $taskName,
                        $csvTask.'Next Run Time',
                        $csvTask.Status,
                        $csvTask.'Logon Mode',
                        $csvTask.'Last Run Time',
                        $csvTask.Author,
                        $createDate,
                        $taskToRun,
                        $csvTask.'Start In',
                        $csvTask.Comment,
                        $csvTask.'Scheduled Task State',
                        $csvTask.'Idle Time',
                        $csvTask.'Power Management',
                        $csvTask.'Run As User',
                        $isInteractive,
                        $noPassword,
                        $highestRunLevel,
                        $csvTask.'Delete Task If Not Rescheduled'
                    )

        $task = New-Object -TypeName 'Carbon.TaskScheduler.TaskInfo' -ArgumentList $ctorArgs

        $scheduleIdx = 0
        while( $idx -lt $output.Count -and $output[$idx].TaskName -eq $csvTask.TaskName )
        {
            $csvTask = $output[$idx++]
            [Carbon.TaskScheduler.ScheduleType]$scheduleType = [Carbon.TaskScheduler.ScheduleType]::Unknown

            [int[]]$days = @()
            [int]$csvDay = 0
            if( [int]::TryParse($csvTask.Days, [ref]$csvDay) )
            {
                $days = @( $csvDay )
            }

            $duration = $csvTask.'Repeat: Until: Duration'
            [Carbon.TaskScheduler.Month[]]$months = @()
            $modifier = $null
            $stopAtEnd = $false
            [int]$interval = 0
            [TimeSpan]$endTime = [TimeSpan]::Zero
            [DayOfWeek[]]$daysOfWeek = @()
            [TimeSpan]$delay = [TimeSpan]::Zero
            [int]$idleTime = 0
            $eventChannelName = $null

            $triggers = $xmlTask.GetElementsByTagName('Triggers') | Select-Object -First 1
            if( -not $triggers -or $triggers.ChildNodes.Count -eq 0 )
            {
                $scheduleType = [Carbon.TaskScheduler.ScheduleType]::OnDemand
            }
            elseif( $triggers.ChildNodes.Count -gt 0 )
            {
                [Xml.XmlElement]$trigger = $triggers.ChildNodes.Item($scheduleIdx++)
                if( $trigger | Get-Member -Name 'EndBoundary' )
                {
                    $endDateTime = [datetime]$trigger.EndBoundary
                    $endTime = New-TimeSpan -Hours $endDateTime.Hour -Minutes $endDateTime.Minute -Seconds $endDateTime.Second
                }

                $scheduleType,$modifier,$duration,$stopAtEnd,$delay = ConvertFrom-RepetitionElement $trigger
                if( $trigger.Name -eq 'TimeTrigger' )
                {
                    $days = @( )
                    if( $csvTask.'Schedule Type' -eq 'One Time Only' )
                    {
                        $scheduleType = 'Once'
                        $interval = $modifier
                        $modifier = $null
                    }
                }
                elseif( $trigger.Name -eq 'LogonTrigger' )
                {
                    $scheduleType = 'OnLogon'
                    $interval = 0
                    $modifier = $null
                }
                elseif( $trigger.Name -eq 'BootTrigger' )
                {
                    $scheduleType = 'OnStart'
                    $interval = 0
                    $modifier = $null
                }
                elseif( $trigger.Name -eq 'IdleTrigger' )
                {
                    $scheduleType = 'OnIdle'
                    $interval = 0
                    $modifier = $null
                    $settingsNode = $xmlTask.Settings
                    if( $settingsNode | Get-Member 'IdleSettings' )
                    {
                        $idleSettingsNode = $settingsNode.IdleSettings
                        if( $idleSettingsNode | Get-Member 'Duration' )
                        {
                            $idleTimeAsTimeSpan = ConvertFrom-DurationSpec -Duration $xmlTask.Settings.IdleSettings.Duration
                            if( $idleTimeAsTimeSpan -ne $null )
                            {
                                $idleTime = $idleTimeAsTimeSpan.TotalMinutes
                            }
                        }
                    }
                }
                elseif( $trigger.Name -eq 'EventTrigger' )
                {
                    $scheduleType = 'OnEvent'
                    $subscription = [xml]$trigger.Subscription
                    $selectNode = $subscription.QueryList.Query.Select
                    $modifier = $selectNode.InnerText
                    $eventChannelName = $selectNode.GetAttribute('Path')
                }
                elseif( $trigger.Name -eq 'SessionStateChangeTrigger' )
                {
                    $scheduleType = [Carbon.TaskScheduler.ScheduleType]::SessionStateChange
                }
                elseif( $trigger.Name -eq 'RegistrationTrigger' )
                {
                    $scheduleType = [Carbon.TaskScheduler.ScheduleType]::Registration
                }
                elseif( $trigger.Name -eq 'CalendarTrigger' )
                {
                    if( $trigger.GetElementsByTagName('ScheduleByDay').Count -eq 1 )
                    {
                        $scheduleType = 'Daily'
                        $modifier = $trigger.ScheduleByDay.DaysInterval
                        $null,$interval,$null,$null = ConvertFrom-RepetitionElement $trigger
                    }
                    elseif( $trigger.GetElementsByTagName('ScheduleByWeek').Count -eq 1 )
                    {
                        $scheduleType = 'Weekly'
                        $interval = $modifier
                        $modifier = $trigger.ScheduleByWeek.WeeksInterval
                        $days = @( )
                        $daysOfWeek = $trigger.ScheduleByWeek.DaysOfWeek.ChildNodes | ForEach-Object { [DayOfWeek]$_.Name }
                    }
                    elseif( $trigger.GetElementsByTagName('ScheduleByMonth').Count -eq 1 )
                    {
                        $scheduleType = 'Monthly'
                        $monthsNode = $trigger.ScheduleByMonth.Months
                        $daysOfMonth = $trigger.ScheduleByMonth.DaysOfMonth.ChildNodes | ForEach-Object { $_.InnerText }
                        if( $daysOfMonth -eq 'Last' )
                        {
                            $interval = $modifier
                            $modifier = 'LastDay'
                            $days = @()
                        }
                        else
                        {
                            $days = $daysOfMonth | ForEach-Object { [int]$_ }
                            $interval = $modifier
                            # Monthly tasks.
                            if( $monthsNode.ChildNodes.Count -eq 12 )
                            {
                                $modifier = 1
                            }
                            else
                            {
                                # Non-monthly tasks.
                                $modifier = $null
                            }
                        }

                        [Carbon.TaskScheduler.Month[]]$months = $monthsNode.ChildNodes | ForEach-Object { ([Carbon.TaskScheduler.Month]$_.Name) }
                    }
                    elseif( $triggers.GetElementsByTagName('ScheduleByMonthDayOfWeek').Count -eq 1 )
                    {
                        $scheduleType = 'Monthly'
                        $interval = $modifier
                        $scheduleNode = $trigger.ScheduleByMonthDayOfWeek
                        $daysOfWeek = $scheduleNode.DaysOfWeek.ChildNodes | ForEach-Object { [DayOfWeek]$_.Name }
                        $months = $scheduleNode.Months.ChildNodes | ForEach-Object { ([Carbon.TaskScheduler.Month]$_.Name) }
                        switch( $scheduleNode.Weeks.Week )
                        {
                            1 { $modifier = 'First' }
                            2 { $modifier = 'Second' }
                            3 { $modifier = 'Third' }
                            4 { $modifier = 'Fourth' }
                            'Last' { $modifier = 'Last' }
                        }
                    }
                }
            }

            function ConvertFrom-SchtasksDate
            {
                param(
                    [Parameter(Mandatory=$true)]
                    [string]
                    $SchtasksDate,

                    [Parameter(Mandatory=$true)]
                    [DateTime]
                    $DefaultValue
                )

                Set-StrictMode -Version 'Latest'

                [DateTime]$dateTime = $DefaultValue
                if( -not [DateTime]::TryParse( $SchtasksDate, [ref] $dateTime ) )
                {
                    return $DefaultValue
                }
                return New-Object 'DateTime' $dateTime.Year,$dateTime.Month,$dateTime.Day
            }

            function ConvertFrom-SchtasksTime
            {
                param(
                    [Parameter(Mandatory=$true)]
                    [string]
                    $SchtasksTime
                )

                Set-StrictMode -Version 'Latest'

                [TimeSpan]$timespan = [TimeSpan]::Zero
                [DateTime]$dateTime = New-Object 'DateTime' 2015,11,6
                $schtasksTime = '{0} {1}' -f (Get-Date).ToString('d'),$SchtasksTime
                if( -not [DateTime]::TryParse( $SchtasksTime, [ref] $dateTime ) )
                {
                    return $timespan
                }

                return New-Object 'TimeSpan' $dateTime.Hour,$dateTime.Minute,$dateTime.Second
            }

            $startDate = ConvertFrom-SchtasksDate $csvTask.'Start Date' -DefaultValue ([DateTime]::MinValue)
            $startTime = ConvertFrom-SchtasksTime $csvTask.'Start Time'
            $endDate = ConvertFrom-SchtasksDate $csvTask.'End Date' -DefaultValue ([DateTime]::MaxValue)

            $scheduleCtorArgs = @(
                                    $csvTask.'Last Result',
                                    $csvTask.'Stop Task If Runs X Hours And X Mins',
                                    $scheduleType,
                                    $modifier,
                                    $interval,
                                    $startTime,
                                    $startDate,
                                    $endTime,
                                    $endDate,
                                    $daysOfWeek,
                                    $days,
                                    $months,
                                    $csvTask.'Repeat: Every',
                                    $csvTask.'Repeat: Until: Time',
                                    $duration,
                                    $csvTask.'Repeat: Stop If Still Running',
                                    $stopAtEnd,
                                    $delay,
                                    $idleTime,
                                    $eventChannelName
                                )

            $schedule = New-Object -TypeName 'Carbon.TaskScheduler.ScheduleInfo' -ArgumentList $scheduleCtorArgs
            $task.Schedules.Add( $schedule )
        }
        --$idx;

        if( -not $wildcardSearch -or $task.FullName -like $Name )
        {
            $task
        }
    }

}

function Get-CServiceAcl
{
    <#
    .SYNOPSIS
    Gets the discretionary access control list (i.e. DACL) for a service.

    .DESCRIPTION
    You wanted it, you got it!  You probably want to use `Get-CServicePermission` instead.  If you want to chagne a service's permissions, use `Grant-CServicePermission` or `Revoke-ServicePermissions`.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .LINK
    Revoke-CServicePermission

    .EXAMPLE
    Get-CServiceAcl -Name Hyperdrive

    Gets the `Hyperdrive` service's DACL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service whose DACL to return.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $rawSD = Get-CServiceSecurityDescriptor -Name $Name -NoWarn
    $rawDacl = $rawSD.DiscretionaryAcl
    New-Object Security.AccessControl.DiscretionaryAcl $false,$false,$rawDacl
}


# This extended type data should move to the Carbon.Service module if/when it gets created.
Add-CTypeData -Type ServiceProcess.ServiceController `
              -MemberName 'GetServiceConfigProperty' `
              -MemberType ScriptMethod `
              -Value {
                    param(
                        [Parameter(Mandatory)]
                        # The name of the property to retrieve.
                        [String] $Name
                    )

                    Set-StrictMode -Version 'Latest'

                    $svcName = $this.ServiceName
                    $svcMachineName = $this.MachineName

                    if( -not ($this | Get-Member -Name 'Configuration') )
                    {
                        $value = $null
                        try
                        {
                            $value = New-Object 'Carbon.Service.ServiceInfo' $svcName,$svcMachineName
                        }
                        catch
                        {
                            $ex = $_.Exception
                            while( $ex.InnerException )
                            {
                                $ex = $ex.InnerException
                            }
                            if( $Global:Error.Count -gt 0 )
                            {
                                $Global:Error.RemoveAt(0)
                            }
                            $msg = "Failed to load extended service information for service ""$($svcName)"" on " +
                                   """$($svcMachineName)"": $($ex.Message)"
                            Write-Error $msg
                        }
                        Add-Member -InputObject $this -MemberType NoteProperty -Name 'Configuration' -Value $value
                    }

                    if( -not $this.Configuration )
                    {
                        return
                    }

                    if( -not ($this.Configuration | Get-Member -Name $Name) )
                    {
                        return
                    }

                    return $this.Configuration.$Name
                }

$svcControllerPropertyNames = @(
    'DelayedAutoStart',
    'Description',
    'ErrorControl',
    'FailureProgram',
    'FirstFailure',
    'LoadOrderGroup',
    'Path',
    'RebootDelay',
    'RebootDelayMinutes',
    'RebootMessage',
    'ResetPeriod',
    'ResetPeriodDays',
    'RestartDelay',
    'RestartDelayMinutes',
    'RunCommandDelay',
    'RunCommandDelayMinutes',
    'SecondFailure',
    'StartType',
    'TagID',
    'ThirdFailure',
    'UserName'
)
foreach( $propertyName in $svcControllerPropertyNames )
{
    Add-CTypeData -Type ServiceProcess.ServiceController `
                  -MemberName $propertyName `
                  -MemberType ScriptProperty `
                  -Value ([scriptblock]::Create("`$this.GetServiceConfigProperty('$($propertyName)')"))
}

Add-CTypeData -Type ServiceProcess.ServiceController `
              -MemberName 'StartMode' `
              -MemberType ScriptProperty `
              -Value {
                    $startType = $this.GetServiceConfigProperty( 'StartType' )
                    if( $startType -ne $null )
                    {
                        [ServiceProcess.ServiceStartMode][int]$startType
                    }
                }

function Get-CServiceConfiguration
{
    <#
    .SYNOPSIS
    Gets a service's full configuration, e.g. username, path, failure actions, etc.

    .DESCRIPTION
    The .NET `ServiceController` object only returns basic information about a service. This function returns all the other service configuration as a `Carbon.Service.ServiceInfo` object, which has the following properties:

    * `DelayedAutoStart`: A boolean value indicating if the service starts automically delayed. This property was added in Carbon 2.5.
    * `Description`: The service's description.
    * `ErrorControl`: A `Carbon.Service.ErrorControl` value that indicates the severity of the error when the service fails to start.
    * `FailureProgram`: The program to run when the service fails.
    * `FirstFailure`: A `Carbon.Service.FailureAction` value indicating what will happen after the service's first failure.
    * `LoadOrderGroup`: The name of the load order group this service loads in.
    * `Name`: The name of the service.
    * `Path`: The path to the service executable (with arguments).
    * `RebootDelay`: The number of milliseconds after boot to wait before the service starts.
    * `RebootDelayMinutes`: `RebootDelay` expressed in minutes.
    * `ResetPeriod`: How often, in seconds, to reset the service's failure count to 0.
    * `ResetPeriodDays`: `ResetPeriod` expressed in number of days.
    * `RestartDelay`: The number of milliseconds to wait before restarting the service after it fails.
    * `RestartDelayMinutes`: `RestartDelay` expressed in minutes.
    * `RunCommandDelay`: The number of milliseconds to wait after a service fails before running the failure program.
    * `RunCommandDelayMinutes`: `RunCommandDelay` as expressed/converted in minutes.
    * `SecondFailure`: A `Carbon.Service.FailureAction` value indicating what will happen after the service's second failure.
    * `StartType`: A `Carbon.Service.StartType` value indicating how and when the service should be started.
    * `TagID`: The service's tag ID. This is the order the service will start in its load group.
    * `ThirdFailure`: A `Carbon.Service.FailureAction` value indicating what will happen after the service's third failure.
    * `UserName`: The name of the identity the service runs as.

    You can load a specific service using its name, or pipe in `ServiceController` objects.

    In addition to this function, Carbon also adds this information as extended type data properties onto the `ServiceController` class. To see it,

        Get-Service | Get-Member

    The user running this function must have `QueryConfig`, `QueryStatus`, and `EnumerateDependents` permissions on the service. Use `Grant-CServicePermission` to grant these permissions.

    This function is new in Carbon 1.8.

    .LINK
    Grant-CServicePermission

    .EXAMPLE
    Get-Service | Get-CServiceConfiguration

    Demonstrates how you can pipe in a `ServiceController` object to load the service. This works for services on remote computers as well.

    .EXAMPLE
    Get-CServiceConfiguration -Name  'w3svc'

    Demonstrates how you can get a specific service's configuration.

    .EXAMPLE
    Get-CServiceConfiguration -Name 'w3svc' -ComputerName 'enterprise'

    Demonstrates how to get service configuration for a service on a remote computer.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Service.ServiceInfo])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string]
        # The name of the service.
        $Name,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias('MachineName')]
        [string]
        # The name of the computer where the service lives.
        $ComputerName,

        [switch] $NoWarn
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                            -ModuleName 'Carbon.Windows.Service'
        }
    }

    process
    {
        $optionalParams = @{ }
        if( $ComputerName )
        {
            # ComputerName parameter does not exists under PowerShell Core.
            if( -not (Get-Command -Name 'Get-Service' -ParameterName 'ComputerName' -ErrorAction Ignore) )
            {
                $msg = "Unable to get service ""$($Name)"" on computer ""$($ComputerName)"": this version " +
                       'of PowerShell doesn''t support services on remote computers.'
                Write-Error $msg -ErrorAction $ErrorActionPreference
                return
            }
            $optionalParams['ComputerName'] = $ComputerName
        }

        if( -not (Get-Service -Name $Name @optionalParams -ErrorAction $ErrorActionPreference) )
        {
            return
        }

        New-Object 'Carbon.Service.ServiceInfo' $Name,$ComputerName
    }
}


function Get-CServicePermission
{
    <#
    .SYNOPSIS
    Gets the permissions for a service.

    .DESCRIPTION
    Uses the Win32 advapi32 API to query the permissions for a service.  Returns `Carbon.ServiceAccessRule` objects for each.  The two relavant properties on this object are

     * IdentityReference - The identity of the permission.
     * ServiceAccessRights - The permissions the user has.

    .OUTPUTS
    Carbon.Security.ServiceAccessRule.

    .LINK
    Grant-ServicePermissions

    .LINK
    Revoke-ServicePermissions

    .EXAMPLE
    Get-CServicePermission -Name 'Hyperdrive'

    Gets the access rules for the `Hyperdrive` service.

    .EXAMPLE
    Get-CServicePermission -Name 'Hyperdrive' -Identity FALCON\HSolo

    Gets just Han's permissions to control the `Hyperdrive` service.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service whose permissions to return.
        $Name,

        [string]
        # The specific identity whose permissions to get.
        $Identity,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $dacl = Get-CServiceAcl -Name $Name -NoWarn

    $account = $null
    if( $Identity )
    {
        $account = Resolve-CIdentity -Name $Identity -NoWarn
        if( -not $account )
        {
            return
        }
    }

    $dacl |
        ForEach-Object {
            $ace = $_

            $aceSid = $ace.SecurityIdentifier;
            if( $aceSid.IsValidTargetType([Security.Principal.NTAccount]) )
            {
                try
                {
                    $aceSid = $aceSid.Translate([Security.Principal.NTAccount])
                }
                catch [Security.Principal.IdentityNotMappedException]
                {
                    # user doesn't exist anymore.  So sad.
                }
            }

            if ($ace.AceType -eq [Security.AccessControl.AceType]::AccessAllowed)
            {
                $ruleType = [Security.AccessControl.AccessControlType]::Allow
            }
            elseif ($ace.AceType -eq [Security.AccessControl.AceType]::AccessDenied)
            {
                $ruleType = [Security.AccessControl.AccessControlType]::Deny
            }
            else
            {
                Write-Error ("Unsupported aceType {0}." -f $ace.AceType)
                return
            }
            New-Object Carbon.Security.ServiceAccessRule $aceSid,$ace.AccessMask,$ruleType
        } |
        Where-Object {
            if( $account )
            {
                return ($_.IdentityReference.Value -eq $account.FullName)
            }
            return $_
        }
}

Set-Alias -Name 'Get-ServicePermissions' -Value 'Get-CServicePermission'

function Get-CServiceSecurityDescriptor
{
    <#
    .SYNOPSIS
    Gets the raw security descriptor for a service.

    .DESCRIPTION
    You probably don't want to mess with the raw security descriptor.  Try `Get-CServicePermission` instead.  Much more useful.

    .OUTPUTS
    System.Security.AccessControl.RawSecurityDescriptor.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-ServicePermissions

    .LINK
    Revoke-ServicePermissions

    .EXAMPLE
    Get-CServiceSecurityDescriptor -Name 'Hyperdrive'

    Gets the hyperdrive service's raw security descriptor.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service whose permissions to return.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $sdBytes = [Carbon.Service.ServiceSecurity]::GetServiceSecurityDescriptor($Name)
    New-Object Security.AccessControl.RawSecurityDescriptor $sdBytes,0
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



function Grant-CPermission
{
    <#
    .SYNOPSIS
    Grants permission on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    The `Grant-CPermission` functions grants permissions to files, directories, registry keys, and certificate private key/key containers. It detects what you are setting permissions on by inspecting the path of the item. If the path is relative, it uses the current location to determine if file system, registry, or private keys permissions should be set.

    The `Permissions` attribute should be a list of [FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx), [RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx), or [CryptoKeyRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx), for files/directories, registry keys, and certificate private keys, respectively. These commands will show you the values for the appropriate permissions for your object:

        [Enum]::GetValues([Security.AccessControl.FileSystemRights])
        [Enum]::GetValues([Security.AccessControl.RegistryRights])
        [Enum]::GetValues([Security.AccessControl.CryptoKeyRights])

    Beginning with Carbon 2.0, permissions are only granted if they don't exist on an item (inherited permissions are ignored).  If you always want to grant permissions, use the `Force` switch.

    Before Carbon 2.0, this function returned any new/updated access rules set on `Path`. In Carbon 2.0 and later, use the `PassThru` switch to get an access rule object back (you'll always get one regardless if the permissions changed or not).

    By default, permissions allowing access are granted. Beginning in Carbon 2.3.0, you can grant permissions denying access by passing `Deny` as the value of the `Type` parameter.

    Beginning in Carbon 2.7, you can append/add rules instead or replacing existing rules on files, directories, or registry items with the `Append` switch.

    ## Directories and Registry Keys

    When setting permissions on a container (directory/registry key) you can control inheritance and propagation flags using the `ApplyTo` parameter. This parameter is designed to hide the complexities of the Windows' inheritance and propagation flags. There are 13 possible combinations.

    Given this tree

            C
           / \
          CC CL
         /  \
        GC  GL

    where

     * C is the **C**ontainer permissions are getting set on
     * CC is a **C**hild **C**ontainer
     * CL is a **C**hild **L**eaf
     * GC is a **G**randchild **C**ontainer and includes all sub-containers below it
     * GL is a **G**randchild **L**eaf

    The `ApplyTo` parameter takes one of the following 13 values and applies permissions to:

     * **Container** - The container itself and nothing below it.
     * **SubContainers** - All sub-containers under the container, e.g. CC and GC.
     * **Leaves** - All leaves under the container, e.g. CL and GL.
     * **ChildContainers** - Just the container's child containers, e.g. CC.
     * **ChildLeaves** - Just the container's child leaves, e.g. CL.
     * **ContainerAndSubContainers** - The container and all its sub-containers, e.g. C, CC, and GC.
     * **ContainerAndLeaves** - The container and all leaves under it, e.g. C and CL.
     * **SubContainerAndLeaves** - All sub-containers and leaves, but not the container itself, e.g. CC, CL, GC, and GL.
     * **ContainerAndChildContainers** - The container and all just its child containers, e.g. C and CC.
     * **ContainerAndChildLeaves** - The container and just its child leaves, e.g. C and CL.
     * **ContainerAndChildContainersAndChildLeaves** - The container and just its child containers/leaves, e.g. C, CC, and CL.
     * **ContainerAndSubContainersAndLeaves** - Everything, full inheritance/propogation, e.g. C, CC, GC, GL.  **This is the default.**
     * **ChildContainersAndChildLeaves**  - Just the container's child containers/leaves, e.g. CC and CL.

    The following table maps `ContainerInheritanceFlags` values to the actual `InheritanceFlags` and `PropagationFlags` values used:

        ContainerInheritanceFlags                   InheritanceFlags                 PropagationFlags
        -------------------------                   ----------------                 ----------------
        Container                                   None                             None
        SubContainers                               ContainerInherit                 InheritOnly
        Leaves                                      ObjectInherit                    InheritOnly
        ChildContainers                             ContainerInherit                 InheritOnly,
                                                                                     NoPropagateInherit
        ChildLeaves                                 ObjectInherit                    InheritOnly
        ContainerAndSubContainers                   ContainerInherit                 None
        ContainerAndLeaves                          ObjectInherit                    None
        SubContainerAndLeaves                       ContainerInherit,ObjectInherit   InheritOnly
        ContainerAndChildContainers                 ContainerInherit                 None
        ContainerAndChildLeaves                     ObjectInherit                    None
        ContainerAndChildContainersAndChildLeaves   ContainerInherit,ObjectInherit   NoPropagateInherit
        ContainerAndSubContainersAndLeaves          ContainerInherit,ObjectInherit   None
        ChildContainersAndChildLeaves               ContainerInherit,ObjectInherit   InheritOnly

    The above information adapated from [Manage Access to Windows Objects with ACLs and the .NET Framework](http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3), published in the November 2004 copy of *MSDN Magazine*.

    If you prefer to speak in `InheritanceFlags` or `PropagationFlags`, you can use the `ConvertTo-ContainerInheritaceFlags` function to convert your flags into Carbon's flags.

    ## Certificate Private Keys/Key Containers

    When setting permissions on a certificate's private key/key container, if a certificate doesn't have a private key, it is ignored and no permissions are set. Since certificate's are always leaves, the `ApplyTo` parameter is ignored.

    When using the `-Clear` switch, note that the local `Administrators` account will always remain. In testing on Windows 2012 R2, we noticed that when `Administrators` access was removed, you couldn't read the key anymore.

    .OUTPUTS
    System.Security.AccessControl.AccessRule. When setting permissions on a file or directory, a `System.Security.AccessControl.FileSystemAccessRule` is returned. When setting permissions on a registry key, a `System.Security.AccessControl.RegistryAccessRule` returned. When setting permissions on a private key, a `System.Security.AccessControl.CryptoKeyAccessRule` object is returned.

    .LINK
    ConvertTo-CContainerInheritanceFlags

    .LINK
    Disable-CAclInheritance

    .LINK
    Enable-CAclInheritance

    .LINK
    Get-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    Test-CPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom

    Grants the Enterprise's engineering group full control on the engine room.  Very important if you want to get anywhere.

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Interns -Permission ReadKey,QueryValues,EnumerateSubKeys -Path rklm:\system\WarpDrive

    Grants the Enterprise's interns access to read about the warp drive.  They need to learn someday, but at least they can't change anything.

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom -Clear

    Grants the Enterprise's engineering group full control on the engine room.  Any non-inherited, existing access rules are removed from `C:\EngineRoom`.

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'

    Grants the Enterprise's engineering group full control on the `1234567890ABCDEF1234567890ABCDEF12345678` certificate's private key/key container.

    .EXAMPLE
    Grant-CPermission -Identity BORG\Locutus -Permission FullControl -Path 'C:\EngineRoom' -Type Deny

    Demonstrates how to grant deny permissions on an objecy with the `Type` parameter.

    .EXAMPLE
    Grant-CPermission -Path C:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Read' -ApplyTo ContainerAndSubContainersAndLeaves -Append
    Grant-CPermission -Path C:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Write' -ApplyTo ContainerAndLeaves -Append

    Demonstrates how to grant multiple access rules to a single identity with the `Append` switch. In this case, `ENTERPRISE\Wesley` will be able to read everything in `C:\Bridge` and write only in the `C:\Bridge` directory, not to any sub-directory.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Security.AccessControl.AccessRule])]
    param(
        [Parameter(Mandatory)]
        # The path on which the permissions should be granted.  Can be a file system, registry, or certificate path.
        [String]$Path,

        [Parameter(Mandatory)]
        # The user or group getting the permissions.
        [String]$Identity,

        [Parameter(Mandatory)]
		[Alias('Permissions')]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        [String[]]$Permission,

        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        [Carbon.Security.ContainerInheritanceFlags]$ApplyTo = ([Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainersAndLeaves),

        # The type of rule to apply, either `Allow` or `Deny`. The default is `Allow`, which will allow access to the item. The other option is `Deny`, which will deny access to the item.
        #
        # This parameter was added in Carbon 2.3.0.
        [Security.AccessControl.AccessControlType]$Type = [Security.AccessControl.AccessControlType]::Allow,

        # Removes all non-inherited permissions on the item.
        [switch]$Clear,

        # Returns an object representing the permission created or set on the `Path`. The returned object will have a `Path` propery added to it so it can be piped to any cmdlet that uses a path.
        #
        # The `PassThru` switch is new in Carbon 2.0.
        [switch]$PassThru,

        # Grants permissions, even if they are already present.
        [switch]$Force,

        # When granting permissions on files, directories, or registry items, add the permissions as a new access rule instead of replacing any existing access rules. This switch is ignored when setting permissions on certificates.
        #
        # This switch was added in Carbon 2.7.
        [switch]$Append,

        # ***Internal.*** Do not use.
        [String] $Description,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        $msg = "Carbon's $($MyInvocation.MyCommand.Name) function moved to the Carbon.Cryptography, " +
               'Carbon.FileSystem, and Carbon.Registry modules as Grant-CPrivateKeyPermission, ' +
               'Grant-CNtfsPermission, and Grant-CRegistryPermission, respectively. The ' +
               "$($MyInvocation.MyCommand.Name) function will be removed from the next major version of Carbon. " +
               'Please switch to the new functions and modules, available on the PowerShell Gallery.'
        Write-CWarningOnce -Message $msg
    }

    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-CPathProvider -Path $Path -NoWarn | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
    }

    if( $providerName -ne 'Registry' -and $providerName -ne 'FileSystem' -and $providerName -ne 'CryptoKey' )
    {
        Write-Error "Unsupported path: '$Path' belongs to the '$providerName' provider.  Only file system, registry, and certificate paths are supported."
        return
    }

    $rights = $Permission | ConvertTo-ProviderAccessControlRights -ProviderName $providerName
    if (-not $rights)
    {
        Write-Error ('Unable to grant {0} {1} permissions on {2}: received an unknown permission.' -f $Identity,($Permission -join ','),$Path)
        return
    }

    if( -not (Test-CIdentity -Name $Identity -NoWarn) )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $Identity)
        return
    }

    $Identity = Resolve-CIdentityName -Name $Identity -NoWarn

    if ($providerName -eq 'CryptoKey')
    {
        foreach ($certificate in (Get-Item -Path $Path))
        {
            $certPath = Join-Path -Path 'cert:' -ChildPath ($certificate.PSPath | Split-Path -NoQualifier)
            $subject = $certificate.Subject
            $thumbprint = $certificate.Thumbprint
            if( -not $certificate.HasPrivateKey )
            {
                $msg = "Unable to grant permission to ${subject} (thumbprint: ${thumbprint}; path ${certPath}) " +
                       'certificate''s private key because that certificate doesn''t have a private key.'
                Write-Warning $msg
                return
            }

            if (-not $Description)
            {
                $Description = "${certPath} ${subject}"
            }

            if (-not $certificate.PrivateKey -or `
                -not ($certificate.PrivateKey | Get-Member -Name 'CspKeyContainerInfo'))
            {
                $privateKeyFilePaths = $certificate | Resolve-CPrivateKeyPath
                if( -not $privateKeyFilePaths )
                {
                    # Resolve-CPrivateKeyPath writes an appropriately detailed error message.
                    continue
                }

                $grantPermArgs = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [Object]]' `
                                            -ArgumentList $PSBoundParameters
                [void]$grantPermArgs.Remove('Path')
                [void]$grantPermArgs.Remove('Permission')

                foreach ($privateKeyFile in $privateKeyFilePaths)
                {
                    Grant-CPermission -Path $privateKeyFile `
                                      -Permission $rights `
                                      @grantPermArgs `
                                      -Description $Description `
                                      -NoWarn
                }
                continue
            }

            [Security.AccessControl.CryptoKeySecurity]$keySecurity =
                $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity
            if (-not $keySecurity)
            {
                $msg = "Failed to grant permission to ${subject} (thumbprint: ${thumbprint}; path: ${certPath}) " +
                       'certificate''s private key because the private key has no security information.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            $rulesToRemove = @()
            if ($Clear)
            {
                $rulesToRemove =
                    $keySecurity.Access |
                    Where-Object { $_.IdentityReference.Value -ne $Identity } |
                    # Don't remove Administrators access.
                    Where-Object { $_.IdentityReference.Value -ne 'BUILTIN\Administrators' }
                if ($rulesToRemove)
                {
                    foreach ($ruleToRemove in $rulesToRemove)
                    {
                        $rmIdentity = $ruleToRemove.IdentityReference.ToString()
                        $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                        $rmRights = $ruleToRemove.CryptoKeyRights
                        Write-Information "${Description}  ${rmIdentity}  - ${rmType} ${rmRights}"
                        if (-not $keySecurity.RemoveAccessRule($ruleToRemove))
                        {
                            $msg = "Failed to remove ""${rmIdentity}"" identity's ${rmType} ""${rmRights}"" " +
                                   "permissions to ${subject} (thumbprint: ${thumbprint}; path: ${certPath}) " +
                                   'certificates''s private key.'
                            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                            continue
                        }
                    }
                }
            }

            $accessRule =
                New-Object -TypeName 'Security.AccessControl.CryptoKeyAccessRule' `
                           -ArgumentList $Identity, $rights, $Type |
                Add-Member -MemberType NoteProperty -Name 'Path' -Value $certPath -PassThru

            if ($Force -or `
                $rulesToRemove -or `
                -not (Test-CPermission -Path $certPath -Identity $Identity -Permission $Permission -Exact -NoWarn))
            {
                $currentPerm = Get-CPermission -Path $certPath -Identity $Identity -NoWarn
                if ($currentPerm)
                {
                    $curType = $currentPerm.AccessControlType.ToString().ToLowerInvariant()
                    $curRights = $currentPerm."$($providerName)Rights"
                    Write-Information "${Description}  ${Identity}  - ${curType} ${curRights}"
                }
                $newType = $Type.ToString().ToLowerInvariant()
                Write-Information "${Description}  ${Identity}  + ${newType} ${rights}"
                $keySecurity.SetAccessRule($accessRule)
                $action = "grant ""${Identity} ${newType} ${rights} permission(s)"
                Set-CryptoKeySecurity -Certificate $certificate -CryptoKeySecurity $keySecurity -Action $action
            }

            if( $PassThru )
            {
                return $accessRule
            }
        }
        return
    }

    # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information. When
    # passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security
    # descriptor. See
    # http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
    $currentAcl = (Get-Item -Path $Path -Force).GetAccessControl([Security.AccessControl.AccessControlSections]::Access)

    $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    $testPermissionParams = @{ }
    if( Test-Path $Path -PathType Container )
    {
        $inheritanceFlags = ConvertTo-CInheritanceFlag -ContainerInheritanceFlag $ApplyTo -NoWarn
        $propagationFlags = ConvertTo-CPropagationFlag -ContainerInheritanceFlag $ApplyTo -NoWarn
        $testPermissionParams.ApplyTo = $ApplyTo
    }
    else
    {
        if( $PSBoundParameters.ContainsKey( 'ApplyTo' ) )
        {
            Write-Warning "Can't apply inheritance/propagation rules to a leaf. Please omit `ApplyTo` parameter when `Path` is a leaf."
        }
    }

    if (-not $Description)
    {
        $Description = $Path
    }

    $rulesToRemove = $null
    $Identity = Resolve-CIdentity -Name $Identity -NoWarn
    if( $Clear )
    {
        $rulesToRemove = $currentAcl.Access |
                            Where-Object { $_.IdentityReference.Value -ne $Identity } |
                            # Don't remove Administrators access.
                            Where-Object { $_.IdentityReference.Value -ne 'BUILTIN\Administrators' } |
                            Where-Object { -not $_.IsInherited }

        if( $rulesToRemove )
        {
            foreach( $ruleToRemove in $rulesToRemove )
            {
                $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                $rmRights = $ruleToRemove."${providerName}Rights"
                Write-Information "${Description}  ${Identity}  - ${rmType} ${rmRights}"
                [void]$currentAcl.RemoveAccessRule( $ruleToRemove )
            }
        }
    }

    $accessRule =
        New-Object -TypeName "Security.AccessControl.$($providerName)AccessRule" `
                   -ArgumentList $Identity,$rights,$inheritanceFlags,$propagationFlags,$Type |
        Add-Member -MemberType NoteProperty -Name 'Path' -Value $Path -PassThru

    $missingPermission =
        -not (Test-CPermission -Path $Path `
                               -Identity $Identity `
                               -Permission $Permission `
                               @testPermissionParams `
                               -Exact `
                               -NoWarn)

    $setAccessRule = ($Force -or $missingPermission)
    if( $setAccessRule )
    {
        if( $Append )
        {
            $currentAcl.AddAccessRule( $accessRule )
        }
        else
        {
            $currentAcl.SetAccessRule( $accessRule )
        }
    }

    if ($rulesToRemove -or $setAccessRule)
    {
        $currentPerm = Get-CPermission -Path $Path -Identity $Identity -NoWarn
        $curRights = 0
        $curType = ''
        $curIdentity = $Identity
        if ($currentPerm)
        {
            $curType = $currentPerm.AccessControlType.ToString().ToLowerInvariant()
            $curRights = $currentPerm."$($providerName)Rights"
            $curIdentity = $currentPerm.IdentityReference
        }
        $newType = $accessRule.AccessControlType.ToString().ToLowerInvariant()
        $newRights = $accessRule."${providerName}Rights"
        $newIdentity = $accessRule.IdentityReference
        if ($Append)
        {
            Write-Information "${Description}  ${newIdentity}  + ${newType} ${newRights}"
        }
        else
        {
            if ($currentPerm)
            {
                Write-Information "${Description}  ${curIdentity}  - ${curType} ${curRights}"
            }
            Write-Information "${Description}  ${newIdentity}  + ${newType} ${newRights}"
        }
        Set-Acl -Path $Path -AclObject $currentAcl
    }

    if( $PassThru )
    {
        return $accessRule
    }
}

Set-Alias -Name 'Grant-Permissions' -Value 'Grant-CPermission'




function Grant-CPrivilege
{
    <#
    .SYNOPSIS
    Grants an identity priveleges to perform system operations.

    .DESCRIPTION
    *Privilege names are **case-sensitive**.* Valid privileges are documented on Microsoft's website: [Privilege Constants](http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx) and [Account Right Constants](http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx). Here is the most current list, as of August 2014:

     * SeAssignPrimaryTokenPrivilege
     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeBatchLogonRight
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
     * SeCreateSymbolicLinkPrivilege
     * SeCreateTokenPrivilege
     * SeDebugPrivilege
     * SeDenyBatchLogonRight
     * SeDenyInteractiveLogonRight
     * SeDenyNetworkLogonRight
     * SeDenyRemoteInteractiveLogonRight
     * SeDenyServiceLogonRight
     * SeEnableDelegationPrivilege
     * SeImpersonatePrivilege
     * SeIncreaseBasePriorityPrivilege
     * SeIncreaseQuotaPrivilege
     * SeIncreaseWorkingSetPrivilege
     * SeInteractiveLogonRight
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeNetworkLogonRight
     * SeProfileSingleProcessPrivilege
     * SeRelabelPrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeRestorePrivilege
     * SeSecurityPrivilege
     * SeServiceLogonRight
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTimeZonePrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    .LINK
    Get-CPrivilege

    .LINK
    Revoke-CPrivilege

    .LINK
    Test-CPrivilege

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx

    .EXAMPLE
    Grant-CPrivilege -Identity Batcomputer -Privilege SeServiceLogonRight

    Grants the Batcomputer account the ability to logon as a service. *Privilege names are **case-sensitive**.*
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity to grant a privilege.
        $Identity,

        [Parameter(Mandatory=$true)]
        [string[]]
        # The privileges to grant. *Privilege names are **case-sensitive**.*
        $Privilege,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Security'
    }

    $account = Resolve-CIdentity -Name $Identity -NoWarn
    if( -not $account )
    {
        return
    }

    try
    {
        [Carbon.Security.Privilege]::GrantPrivileges( $account.FullName, $Privilege )
    }
    catch
    {
        $ex = $_.Exception
        do
        {
            if( $ex -is [ComponentModel.Win32Exception] -and $ex.Message -eq 'No such privilege. Indicates a specified privilege does not exist.' )
            {
                $msg = 'Failed to grant {0} {1} privilege(s): {2}  *Privilege names are **case-sensitive**.*' -f `
                        $account.FullName,($Privilege -join ','),$ex.Message
                Write-Error -Message $msg
                return
            }
            else
            {
                $ex = $ex.InnerException
            }
        }
        while( $ex )

        $ex = $_.Exception
        Write-Error -Message ('Failed to grant {0} {1} privilege(s): {2}' -f $account.FullName,($Privilege -join ', '),$ex.Message)

        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}

function Grant-CServiceControlPermission
{
    <#
    .SYNOPSIS
    Grants a user/group permission to start/stop (i.e. use PowerShell's `*-Service` cmdlets) a service.

    .DESCRIPTION
    By default, only Administrators are allowed to control a service. You may notice that when running the `Stop-Service`, `Start-Service`, or `Restart-Service` cmdlets as a non-Administrator, you get permissions errors. That's because you need to correct permissions.  This function grants just the permissions needed to use PowerShell's `Stop-Service`, `Start-Service`, and `Restart-Service` cmdlets to control a service.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .LINK
    Revoke-CServicePermission

    .EXAMPLE
    Grant-CServiceControlPermission -ServiceName CCService -Identity INITRODE\Builders

    Grants the INITRODE\Builders group permission to control the CruiseControl.NET service.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $ServiceName,

        [Parameter(Mandatory=$true)]
        [string]
        # The user/group name being given access.
        $Identity,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    if( $pscmdlet.ShouldProcess( $ServiceName, "grant control service permissions to '$Identity'" ) )
    {
        Grant-CServicePermission -Name $ServiceName -Identity $Identity -QueryStatus -EnumerateDependents -Start -Stop -NoWarn
    }
}


function Grant-CServicePermission
{
    <#
    .SYNOPSIS
    Grants permissions for an identity against a service.

    .DESCRIPTION
    By default, only Administators are allowed to manage a service.  Use this function to grant specific identities permissions to manage a specific service.

    If you just want to grant a user the ability to start/stop/restart a service using PowerShell's `Start-Service`, `Stop-Service`, or `Restart-Service` cmdlets, use the `Grant-ServiceControlPermissions` function instead.

    Any previous permissions are replaced.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-ServiceControlPermissions

    .EXAMPLE
    Grant-CServicePermission -Identity FALCON\Chewbacca -Name Hyperdrive -QueryStatus -EnumerateDependents -Start -Stop

    Grants Chewbacca the permissions to query, enumerate dependents, start, and stop the `Hyperdrive` service.  Coincedentally, these are the permissions that Chewbacca nees to run `Start-Service`, `Stop-Service`, `Restart-Service`, and `Get-Service` cmdlets against the `Hyperdrive` service.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service to grant permissions to.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The identity to grant permissions for.
        $Identity,

        [Parameter(Mandatory=$true,ParameterSetName='FullControl')]
        [Switch]
        # Grant full control on the service
        $FullControl,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to query the service's configuration.
        $QueryConfig,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to change the service's permission.
        $ChangeConfig,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to query the service's status.
        $QueryStatus,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permissionto enumerate the service's dependent services.
        $EnumerateDependents,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to start the service.
        $Start,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to stop the service.
        $Stop,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to pause/continue the service.
        $PauseContinue,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to interrogate the service (i.e. ask it to report its status immediately).
        $Interrogate,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to run the service's user-defined control.
        $UserDefinedControl,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to delete the service.
        $Delete,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to query the service's security descriptor.
        $ReadControl,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to set the service's discretionary access list.
        $WriteDac,

        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        # Grants permission to modify the group and owner of a service.
        $WriteOwner,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $account = Resolve-CIdentity -Name $Identity -NoWarn
    if( -not $account )
    {
        return
    }

    if( -not (Assert-CService -Name $Name -NoWarn) )
    {
        return
    }

    $accessRights = [Carbon.Security.ServiceAccessRights]::FullControl
    if( $pscmdlet.ParameterSetName -eq 'PartialControl' )
    {
        $accessRights = 0
        [Enum]::GetValues( [Carbon.Security.ServiceAccessRights] ) |
            Where-Object { $PSBoundParameters.ContainsKey( $_ ) } |
            ForEach-Object { $accessRights = $accessRights -bor [Carbon.Security.ServiceAccessRights]::$_ }
    }

    $dacl = Get-CServiceAcl -Name $Name -NoWarn
    $dacl.SetAccess( [Security.AccessControl.AccessControlType]::Allow, $account.Sid, $accessRights, 'None', 'None' )

    Set-CServiceAcl -Name $Name -DACL $dacl -NoWarn
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


function Install-CDirectory
{
    <#
    .SYNOPSIS
    Creates a directory, if it doesn't exist.

    .DESCRIPTION
    The `Install-CDirectory` function creates a directory. If the directory already exists, it does nothing. If any parent directories don't exist, they are created, too.

    `Install-CDirectory` was added in Carbon 2.1.0.

    .EXAMPLE
    Install-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to use create a directory. In this case, the directories `C:\Projects` and `C:\Projects\Carbon` will be created if they don't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the directory to create.
        $Path,

        # Hide the warning that this function is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.FileSystem' `
                                    -NoWarn:$NoWarn

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        New-Item -Path $Path -ItemType 'Directory' | Out-String | Write-Verbose
    }
}


function Install-CFileShare
{
    <#
    .SYNOPSIS
    Installs a file/SMB share.

    .DESCRIPTION
    The `Install-CFileShare` function installs a new file/SMB share. If the share doesn't exist, it is created. In
    Carbon 2.0, if a share does exist, its properties and permissions are updated in place, unless the share's path
    needs to change. Changing a share's path requires deleting and re-creating. Before Carbon 2.0, shares were always
    deleted and re-created.

    Use the `FullAccess`, `ChangeAccess`, and `ReadAccess` parameters to grant full, change, and read sharing
    permissions on the share. Each parameter takes a list of user/group names. If you don't supply any permissions,
    `Everyone` will get `Read` access. Permissions on existing shares are cleared before permissions are granted.
    Permissions don't apply to the file system, only to the share. Use the Carbon.FileSystem module's
    `Grant-CNtfsPermission` function to grant file system permissions.

    Before Carbon 2.0, this function was called `Install-SmbShare`.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Test-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Install-Share -Name TopSecretDocuments -Path C:\TopSecret -Description 'Share for our top secret documents.' -ReadAccess "Everyone" -FullAccess "Analysts"

    Shares the C:\TopSecret directory as `TopSecretDocuments` and grants `Everyone` read access and `Analysts` full
    control.
    #>
    [CmdletBinding()]
    param(
        # The share's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The path to the share.
        [Parameter(Mandatory)]
        [String] $Path,

        # A description of the share
        [String] $Description = '',

        # The identities who have full access to the share.
        [String[]] $FullAccess = @(),

        # The identities who have change access to the share.
        [String[]] $ChangeAccess = @(),

        # The identities who have read access to the share
        [String[]] $ReadAccess = @(),

        # Deletes the share and re-creates it, if it exists. Preserves default beheavior in Carbon before 2.0.
        #
        # The `Force` switch is new in Carbon 2.0.
        [switch] $Force,

        # Hide the warning that this function is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.SmbShare' `
                                    -NewCommandName 'Install-CSmbShare' `
                                    -NoWarn:$NoWarn

    if (-not (Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore))
    {
        # No. Seriously. The CIM cmdlets have no way of creating Win32_SecurityDescriptor
        $msg = "$($PSCmdlet.MyInvocation.MyCommand.Name) is not supported because the Get-WmiObject cmdlet does not " +
               'exist.'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    function New-ShareAce
    {
        param(
            # The identity
            [Parameter(Mandatory)]
            [AllowEmptyCollection()]
            [String[]] $Identity,

            # The rights to grant to Identity.
            [Carbon.Security.ShareRights] $ShareRight
        )

        Set-StrictMode -Version 'Latest'

        foreach( $identityName in $Identity )
        {
            $trustee = ([wmiclass]'Win32_Trustee').CreateInstance()
            [Security.Principal.SecurityIdentifier]$sid =
                Resolve-CIdentity -Name $identityName -NoWarn | Select-Object -ExpandProperty 'Sid'
            if( -not $sid )
            {
                continue
            }

            $sidBytes = New-Object 'byte[]' $sid.BinaryLength
            $sid.GetBinaryForm( $sidBytes, 0)

            $trustee.Sid = $sidBytes

            $ace = ([wmiclass]'Win32_Ace').CreateInstance()
            $ace.AccessMask = $ShareRight
            $ace.AceFlags = 0
            $ace.AceType = 0
            $ace.Trustee = $trustee

            $ace
        }
    }

    $Path = Resolve-CFullPath -Path $Path -NoWarn
    $Path = $Path.Trim('\\')
    # When sharing drives, path must end with \. Otherwise, it shouldn't.
    if( $Path -eq (Split-Path -Qualifier -Path $Path ) )
    {
        $Path = Join-Path -Path $Path -ChildPath '\'
    }

    $changeMsgPrefix = "  "
    $changeMsgs = [Collections.Generic.List[String]]::New()
    $action = 'Creating'

    if( (Test-CFileShare -Name $Name -NoWarn) )
    {
        $share = Get-CFileShare -Name $Name -NoWarn
        [bool]$delete = $false

        if( $Force )
        {
            $delete = $true
        }

        if ($share.Path -ne $Path)
        {
            $action = 'Updating'
            $delete = $true
        }

        if( $delete )
        {
            Uninstall-CFileShare -Name $Name -InformationAction SilentlyContinue -NoWarn
        }
    }

    $createdShare = $false
    if (-not (Test-CFileShare -Name $Name -NoWarn))
    {
        Install-CDirectory -Path $Path -NoWarn

        Write-Information -Message "$($action) SMB file share ""$($Name)""."
        if ($action -eq 'Creating')
        {
            Write-Information "$($changeMsgPrefix)Path         $($Path)"
            if ($Description)
            {
                Write-Information "$($changeMsgPrefix)Description  $($Description)"
            }
        }
        elseif ($action -eq 'Updating' -and $share.Path -ne $Path)
        {
            WRite-Information "$($changeMsgPrefix)Path         $($share.Path) -> $($Path)"
        }

        $createArgs = [ordered]@{
            Path = [String]$Path;
            Name = [String]$Name;
            Type = [UInt32]0;
            MaximumAllowed = $null;
            Description = $Description;
        }
        Invoke-CCimMethod -ClassName 'Win32_Share' -Name 'Create' -Arguments $createArgs
        $createdShare = $true
    }

    $share = Get-CFileShare -Name $Name -AsWmiObject -NoWarn
    $updateShare = $false

    if ($share.Description -ne $Description)
    {
        $changeMsgs.Add("$($changeMsgPrefix)Description  $($share.Description) -> $($Description)")
        $updateShare = $true
    }

    $shareAces = Invoke-Command -ScriptBlock {
            if (-not $FullAccess -and -not $ChangeAccess -and -not $ReadAccess)
            {
                return New-ShareAce -Identity 'Everyone' -ShareRight Read
            }

            New-ShareAce -Identity $FullAccess -ShareRight FullControl
            New-ShareAce -Identity $ChangeAccess -ShareRight Change
            New-ShareAce -Identity $ReadAccess -ShareRight Read
        }

    # Check if the share is missing any of the new ACEs.
    foreach ($ace in $shareAces)
    {
        $identityName = Resolve-CIdentityName -SID $ace.Trustee.SID -NoWarn
        $accessMsgPrefix = "$($changeMsgPrefix)Access       $($identityName)  "
        $permission = Get-CFileSharePermission -Name $Name -Identity $identityName -NoWarn

        $newPerm = [Carbon.Security.ShareRights]$ace.AccessMask
        if (-not $permission)
        {
            $changeMsgs.Add("$($accessMsgPrefix)+ $($newPerm)")
            $updateShare = $true
        }
        elseif ([int]$permission.ShareRights -ne $ace.AccessMask)
        {
            $changeMsgs.Add("$($accessMsgPrefix)  $($permission.ShareRights) -> $($newPerm)")
            $updateShare = $true
        }
    }

    $existingAces = Get-CFileSharePermission -Name $Name -NoWarn
    foreach ($ace in $existingAces)
    {
        $identityName = $ace.IdentityReference.Value

        $existingAce = $ace
        if ($shareAces)
        {
            $existingAce =
                $shareAces |
                Where-Object {
                        $newIdentityName = Resolve-CIdentityName -SID $_.Trustee.SID -NoWarn
                        return ( $newIdentityName -eq $ace.IdentityReference.Value )
                    }
        }

        if (-not $existingAce)
        {
            $changeMsgs.Add("$($changeMsgPrefix)Access       $($identityName)  - $($ace.ShareRights)")
            $updateShare = $true
        }
    }

    if ($updateShare)
    {
        $currentSD = Get-CFileShareSecurityDescriptor -Name $Name
        $newSD = ([wmiclass]'Win32_SecurityDescriptor').CreateInstance()
        $newSD.DACL = $shareAces
        $newSD.ControlFlags = "0x4"
        $newSD.Group = $currentSD.Group
        $newSD.Owner = $currentSD.Owner
        $newSD.SACL = $currentSD.SACL

        if (-not $createdShare)
        {
            Write-Information -Message "Updating SMB file share ""$($Name)""."
        }
        foreach ($msg in $changeMsgs)
        {
            Write-Information $msg
        }

        $result = $share.SetShareInfo($share.MaximumAllowed, $Description, $newSD)
        Write-CCimError -Message "Failed to update ""$($Name)"" SMB file share" -Result $result
    }
}

Set-Alias -Name 'Install-SmbShare' -Value 'Install-CFileShare'



function Install-CGroup
{
    <#
    .SYNOPSIS
    Creates a new local group, or updates the settings for an existing group.

    .DESCRIPTION
    `Install-CGroup` creates a local group, or, updates a group that already exists.

    YOu can get a `System.DirectoryServices.AccountManagement.GroupPrincipal` object representing the group returned to you by using the `PassThru` switch. This object implements the `IDisposable` interface, which means it uses external resources that don't get garbage collected. When you're done using the object, make sure you call `Dispose()` to free those resources, otherwise you'll leak memory. All over the place.

    .EXAMPLE
    Install-CGroup -Name TIEFighters -Description 'Users allowed to be TIE fighter pilots.' -Members EMPIRE\Pilots,EMPIRE\DarthVader

    If the TIE fighters group doesn't exist, it is created with the given description and default members.  If it already exists, its description is updated and the given members are added to it.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group.
        $Name,

        [string]
        # A description of the group.
        $Description = '',

        [Alias('Members')]
        [string[]]
        # Members of the group.
        $Member = @(),

        [Switch]
        # Return the group as a `System.DirectoryServices.AccountManagement.GroupPrincipal`.
        #
        # This object uses external resources that don't get cleaned up by .NET's garbage collector. In order to avoid memory leaks, make sure you call its `Dispose()` method when you're done with it.
        $PassThru,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Get-CLocalGroup' `
                                    -NoWarn:$NoWarn

    $group = Get-CGroup -Name $Name -NoWarn -ErrorAction Ignore

    if( $group )
    {
        $ctx = $group.Context
    }
    else
    {
        $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    }

    $operation = 'update'
    $save = $false
    $new = $false
    if( -not $group )
    {
        $operation = 'create'
        $new = $true
        $group = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
        $group.Name = $Name
        $group.Description = $Description
        $save = $true
    }
    else
    {
        # We only update the description if one or the other has a value. This guards against setting description to $null from empty string and vice-versa.
        if( $group.Description -ne $Description -and ($group.Description -or $Description) )
        {
            Write-Verbose -Message ('[{0}] Description  {1} -> {2}' -f $Name,$group.Description,$Description)
            $group.Description = $Description
            $save = $true
        }
    }

    try
    {

        if( $save -and $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), $operation ) )
        {
            if( $new )
            {
                Write-Verbose -Message ('[{0}]              +' -f $Name)
            }
            $group.Save()
        }

        if( $Member -and $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), 'adding members' ) )
        {
            Add-CGroupMember -Name $Name -Member $Member -NoWarn
        }

        if( $PassThru )
        {
            return $group
        }
    }
    finally
    {
        if( -not $PassThru )
        {
            $group.Dispose()
            $ctx.Dispose()
        }

    }
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



# Leave this here so that when we move this function to its own module, these go with it.
Add-CTypeData -Type Carbon.TaskScheduler.TaskInfo -MemberType AliasProperty -MemberName 'State' -Value 'Status'
Add-CTypeData -Type Carbon.TaskScheduler.TaskInfo `
              -MemberType ScriptProperty `
              -MemberName 'FullName' `
              -Value { return Join-Path -Path $this.TaskPath -ChildPath $this.TaskName }

function Install-CScheduledTask
{
    <#
    .SYNOPSIS
    Installs a scheduled task on the current computer.

    .DESCRIPTION
    The `Install-CScheduledTask` function uses `schtasks.exe` to install a scheduled task on the current computer. If a task with the same name already exists, the existing task is left in place. Use the `-Force` switch to force `Install-CScheduledTask` to delete any existing tasks before installation.

    If a new task is created, a `Carbon.TaskScheduler.TaskInfo` object is returned.

    The `schtasks.exe` command line application is pretty limited in the kind of tasks it will create. If you need a scheduled task created with options not supported by `Install-CScheduledTask`, you can create an XML file using the [Task Scheduler Schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) or create a task with the Task Scheduler MMC then export that task as XML with the `schtasks.exe /query /xml /tn <TaskName>`. Pass the XML file (or the raw XML) with the `TaskXmlFilePath` or `TaskXml` parameters, respectively.

    .LINK
    Get-CScheduledTask

    .LINK
    Test-CScheduledTask

    .LINK
    Uninstall-CScheduledTask

    .LINK
    http://technet.microsoft.com/en-us/library/cc725744.aspx#BKMK_create

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'C:\Windows\system32\notepad.exe' -Minute 5

    Creates a scheduled task "CarbonSample" to run notepad.exe every five minutes. No credential or principal is provided, so the task will run as `System`.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'C:\Windows\system32\notepad.exe' -Minute 1 -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to run a task every minute as a specific user with the `TaskCredential` parameter.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'C:\Windows\system32\notepad.exe' -Minute 1 -Principal LocalService

    Demonstrates how to run a task every minute as a built-in principal, in this case `Local Service`.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'calc.exe' -Minute 5 -StartTime '12:00' -EndTime '14:00' -StartDate '6/6/2006' -EndDate '6/6/2006'

    Demonstrates how to run a task every 5 minutes between the given start date/time and end date/time. In this case, the task will run between noon and 2 pm on `6/6/2006`.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad' -Hourly 1

    Creates a scheduled task `CarbonSample` which runs `notepad.exe` every hour as the `LocalService` user.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Weekly 1

    Demonstrates how to run a task ever *N* weeks, in this case every week.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Monthly

    Demonstrates how to run a task the 1st of every month.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Monthly -DayOfMonth 15

    Demonstrates how to run a monthly task on a specific day of the month.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Month 1,4,7,10 -DayOfMonth 5

    Demonstrates how to run a task on specific months of the year on a specific day of the month.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -WeekOfMonth First -DayOfWeek Sunday

    Demonstrates how to run a task on a specific week of each month. In this case, the task will run the first Sunday of every month.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Month 1,5,9 -WeekOfMonth First -DayOfWeek Sunday

    Demonstrates how to run a task on a specific week of specific months. In this case, the task will run the first Sunday of January, May, and September.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -LastDayOfMonth

    Demonstrates how to run a task the last day of every month.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -LastDayOfMonth -Month 1,6

    Demonstrates how to run a task the last day of specific months. In this case, the task will run the last day of January and June.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -Once -StartTime '0:00'

    Demonstrates how to run a task once. In this case, the task will run at midnight of today (which means it probably won't run since it is always past midnight).

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnStart

    Demonstrates how to run a task when the computer starts up.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnStart -Delay '0:30'

    Demonstrates how to run a task when the computer starts up after a certain amount of time passes. In this case, the task will run 30 minutes after the computer starts.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnLogon -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to run a task when the user running the task logs on. Usually you want to pass a credential when setting up a logon task, since the built-in users never log in.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnLogon -Delay '1:45' -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to run a task after a certain amount of time passes after a user logs in. In this case, the task will run after 1 hour and 45 minutes after `runasuser` logs in.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnIdle

    Demonstrates how to run a task when the computer is idle.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -OnIdle -Delay '0:05'

    Demonstrates how to run a task when the computer has been idle for a desired amount of time. In this case, the task will run after the computer has been idle for 5 minutes.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'wevtvwr.msc' -OnEvent -EventChannelName System -EventXPathQuery '*[Sytem/EventID=101]'

    Demonstrates how to run an event when certain events are written to the event log. In this case, wevtvwr.msc will run whenever an event with ID `101` is published in the System event channel.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXmlFilePath $taskXmlPath

    Demonstrates how to create a task using the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that runs as a built-in principal. You can export task XML with the `schtasks /query /xml /tn <Name>` command.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXmlFilePath $taskXmlPath -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to create a task using the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that will run as a specific user. The username in the XML file should match the username in the credential.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXml $taskXml

    Demonstrates how to create a task using raw XML that conforms to the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that will run as a built-in principal. In this case, `$taskXml` should be an XML document.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonSample' -TaskToRun 'notepad.exe' -TaskXml $taskXml -TaskCredential (Get-Credential 'runasuser')

    Demonstrates how to create a task using raw XML that conforms to the [Task Scheduler XML schema](http://msdn.microsoft.com/en-us/library/windows/desktop/aa383609.aspx) for a task that will run as a specific user. In this case, `$taskXml` should be an XML document.  The username in the XML document should match the username in the credential.

    .EXAMPLE
    Install-CScheduledTask -Name 'CarbonTasks\CarbonSample' -TaskToRun 'notepad.exe' -Monthly

    Demonstrates how to create tasks under a folder/directory: use a path for the `Name` parameter.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.TaskScheduler.TaskInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,238)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to create. Paths are allowed to create tasks under folders.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='Minute')]
        [Parameter(Mandatory=$true,ParameterSetName='Hourly')]
        [Parameter(Mandatory=$true,ParameterSetName='Daily')]
        [Parameter(Mandatory=$true,ParameterSetName='Weekly')]
        [Parameter(Mandatory=$true,ParameterSetName='Monthly')]
        [Parameter(Mandatory=$true,ParameterSetName='Month')]
        [Parameter(Mandatory=$true,ParameterSetName='LastDayOfMonth')]
        [Parameter(Mandatory=$true,ParameterSetName='WeekOfMonth')]
        [Parameter(Mandatory=$true,ParameterSetName='Once')]
        [Parameter(Mandatory=$true,ParameterSetName='OnStart')]
        [Parameter(Mandatory=$true,ParameterSetName='OnLogon')]
        [Parameter(Mandatory=$true,ParameterSetName='OnIdle')]
        [Parameter(Mandatory=$true,ParameterSetName='OnEvent')]
        [ValidateLength(1,262)]
        [string]
        # The task/program to execute, including arguments/parameters.
        $TaskToRun,

        [Parameter(ParameterSetName='Minute',Mandatory=$true)]
        [ValidateRange(1,1439)]
        [int]
        # Create a scheduled task that runs every N minutes.
        $Minute,

        [Parameter(ParameterSetName='Hourly',Mandatory=$true)]
        [ValidateRange(1,23)]
        [int]
        # Create a scheduled task that runs every N hours.
        $Hourly,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Switch]
        # Stops the task at the `EndTime` or `Duration` if it is still running.
        $StopAtEnd,

        [Parameter(ParameterSetName='Daily',Mandatory=$true)]
        [ValidateRange(1,365)]
        [int]
        # Creates a scheduled task that runs every N days.
        $Daily,

        [Parameter(ParameterSetName='Weekly',Mandatory=$true)]
        [ValidateRange(1,52)]
        [int]
        # Creates a scheduled task that runs every N weeks.
        $Weekly,

        [Parameter(ParameterSetName='Monthly',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs every month.
        $Monthly,

        [Parameter(ParameterSetName='LastDayOfMonth',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs on the last day of every month. To run on specific months, specify the `Month` parameter.
        $LastDayOfMonth,

        [Parameter(ParameterSetName='Month',Mandatory=$true)]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Carbon.TaskScheduler.Month[]]
        # Create a scheduled task that runs on specific months. To create a monthly task, use the `Monthly` switch.
        $Month,

        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month',Mandatory=$true)]
        [ValidateRange(1,31)]
        [int]
        # The day of the month to run a monthly task.
        $DayOfMonth,

        [Parameter(ParameterSetName='WeekOfMonth',Mandatory=$true)]
        [Carbon.TaskScheduler.WeekOfMonth]
        # Create a scheduled task that runs a particular week of the month.
        $WeekOfMonth,

        [Parameter(ParameterSetName='WeekOfMonth',Mandatory=$true)]
        [Parameter(ParameterSetName='Weekly')]
        [DayOfWeek[]]
        # The day of the week to run the task. Default is today.
        $DayOfWeek,

        [Parameter(ParameterSetName='Once',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs once.
        $Once,

        [Parameter(ParameterSetName='OnStart',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs at startup.
        $OnStart,

        [Parameter(ParameterSetName='OnLogon',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs when the user running the task logs on.  Requires the `TaskCredential` parameter.
        $OnLogon,

        [Parameter(ParameterSetName='OnIdle',Mandatory=$true)]
        [ValidateRange(1,999)]
        [int]
        # Create a scheduled task that runs when the computer is idle for N minutes.
        $OnIdle,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [Switch]
        # Create a scheduled task that runs when events appear in the Windows event log.
        $OnEvent,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        # The name of the event channel to look at.
        $EventChannelName,

        [Parameter(ParameterSetName='OnEvent',Mandatory=$true)]
        [string]
        # The XPath event query to use to determine when to fire `OnEvent` tasks.
        $EventXPathQuery,

        [Parameter(Mandatory=$true,ParameterSetName='XmlFile')]
        [string]
        # Install the task from this XML path.
        $TaskXmlFilePath,

        [Parameter(Mandatory=$true,ParameterSetName='Xml')]
        [xml]
        # Install the task from this XML.
        $TaskXml,

        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [ValidateRange(1,599940)]
        [int]
        # Re-run the task every N minutes.
        $Interval,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [DateTime]
        # The date the task can start running.
        $StartDate,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once',Mandatory=$true)]
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        # The start time to run the task. Must be less than `24:00`.
        $StartTime,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [TimeSpan]
        # The duration to run the task. Usually used with `Interval` to repeatedly run a task over a given time span. By default, re-runs for an hour. Can't be used with `EndTime`.
        $Duration,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [DateTime]
        # The last date the task should run.
        $EndDate,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [ValidateScript({ $_ -lt [timespan]'1' })]
        [TimeSpan]
        # The end time to run the task. Must be less than `24:00`. Can't be used with `Duration`.
        $EndTime,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        # Enables the task to run interactively only if the user is currently logged on at the time the job runs. The task will only run if the user is logged on. Must be used with `TaskCredential` parameter.
        $Interactive,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        # No password is stored. The task runs non-interactively as the given user, who must be logged in. Only local resources are available. Must be used with `TaskCredential` parameter.
        $NoPassword,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [Switch]
        # If the user is an administrator, runs the task with full administrator rights. The default is to run with limited administrative privileges.
        #
        # If UAC is enabled, an administrator has two security tokens: a filtered token that gets used by default and grants standard user rights and a full token that grants administrative rights that is only used when a program is "Run as administrator". Using this switch runs the scheduled task with the adminisrators full token. (Information taken from [How does "Run with the highest privileges" really work in Task Scheduler ?](https://social.technet.microsoft.com/Forums/windows/en-US/7167bb31-f375-4f77-b430-0339092e16b9/how-does-run-with-the-highest-privileges-really-work-in-task-scheduler-).)
        $HighestAvailableRunLevel,

        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateScript({ $_ -lt '6.22:40:00'})]
        [timespan]
        # The wait time to delay the running of the task after the trigger is fired.  Must be less than 10,000 minutes (6 days, 22 hours, and 40 minutes).
        $Delay,

        [Management.Automation.PSCredential]
        # The principal the task should run as. Use `Principal` parameter to run as a built-in security principal. Required if `Interactive` or `NoPassword` switches are used.
        $TaskCredential,

        [Parameter(ParameterSetName='Minute')]
        [Parameter(ParameterSetName='Hourly')]
        [Parameter(ParameterSetName='Daily')]
        [Parameter(ParameterSetName='Weekly')]
        [Parameter(ParameterSetName='Monthly')]
        [Parameter(ParameterSetName='Month')]
        [Parameter(ParameterSetName='LastDayOfMonth')]
        [Parameter(ParameterSetName='WeekOfMonth')]
        [Parameter(ParameterSetName='Once')]
        [Parameter(ParameterSetName='OnStart')]
        [Parameter(ParameterSetName='OnLogon')]
        [Parameter(ParameterSetName='OnIdle')]
        [Parameter(ParameterSetName='OnEvent')]
        [ValidateSet('System','LocalService','NetworkService')]
        [string]
        # The built-in identity to use. The default is `System`. Use the `TaskCredential` parameter to run as non-built-in security principal.
        $Principal = 'System',

        [Switch]
        # Create the task even if a task with the same name already exists (i.e. delete any task with the same name before installation).
        $Force,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.ScheduledTasks'
    }

    if( (Test-CScheduledTask -Name $Name -NoWarn) )
    {
        if( $Force )
        {
            Uninstall-CScheduledTask -Name $Name -NoWarn
        }
        else
        {
            Write-Verbose ('Scheduled task ''{0}'' already exists. Use -Force switch to re-create it.' -f $Name)
            return
        }
    }

    $parameters = New-Object 'Collections.ArrayList'

    if( $TaskCredential )
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( $TaskCredential.UserName )
        [void]$parameters.Add( '/RP' )
        [void]$parameters.Add( $TaskCredential.GetNetworkCredential().Password )
        Grant-CPrivilege -Identity $TaskCredential.UserName -Privilege 'SeBatchLogonRight' -NoWarn
    }
    elseif( $PSCmdlet.ParameterSetName -notlike 'Xml*' )
    {
        [void]$parameters.Add( '/RU' )
        [void]$parameters.Add( (Resolve-CIdentityName -Name $Principal -NoWarn) )
    }

    function ConvertTo-SchtasksCalendarNameList
    {
        param(
            [Parameter(Mandatory=$true)]
            [object[]]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $list = $InputObject | ForEach-Object { $_.ToString().Substring(0,3).ToUpperInvariant() }
        return $list -join ','
    }

    $scheduleType = $PSCmdlet.ParameterSetName.ToUpperInvariant()
    $modifier = $null
    switch -Wildcard ( $PSCmdlet.ParameterSetName )
    {
        'Minute'
        {
            $modifier = $Minute
        }
        'Hourly'
        {
            $modifier = $Hourly
        }
        'Daily'
        {
            $modifier = $Daily
        }
        'Weekly'
        {
            $modifier = $Weekly
            if( $PSBoundParameters.ContainsKey('DayOfWeek') )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $DayOfWeek) )
            }
        }
        'Monthly'
        {
            $modifier = 1
            if( $DayOfMonth )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( ($DayOfMonth -join ',') )
            }
        }
        'Month'
        {
            $scheduleType = 'MONTHLY'
            [void]$parameters.Add( '/M' )
            [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $Month) )
            if( ($Month | Select-Object -Unique | Measure-Object).Count -eq 12 )
            {
                Write-Error ('It looks like you''re trying to schedule a monthly task, since you passed all 12 months as the `Month` parameter. Please use the `-Monthly` switch to schedule a monthly task.')
                return
            }

            if( $DayOfMonth )
            {
                [void]$parameters.Add( '/D' )
                [void]$parameters.Add( ($DayOfMonth -join ',') )
            }
        }
        'LastDayOfMonth'
        {
            $modifier = 'LASTDAY'
            $scheduleType = 'MONTHLY'
            [void]$parameters.Add( '/M' )
            if( $Month )
            {
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $Month) )
            }
            else
            {
                [void]$parameters.Add( '*' )
            }
        }
        'WeekOfMonth'
        {
            $scheduleType = 'MONTHLY'
            $modifier = $WeekOfMonth
            [void]$parameters.Add( '/D' )
            if( $DayOfWeek.Count -eq 1 -and [Enum]::IsDefined([DayOfWeek],$DayOfWeek[0]) )
            {
                [void]$parameters.Add( (ConvertTo-SchtasksCalendarNameList $DayOfWeek[0]) )
            }
            else
            {
                Write-Error ('Tasks that run during a specific week of the month can only occur on a single weekday (received {0} days: {1}). Please pass one weekday with the `-DayOfWeek` parameter.' -f $DayOfWeek.Length,($DayOfWeek -join ','))
                return
            }
        }
        'OnIdle'
        {
            $scheduleType = 'ONIDLE'
            [void]$parameters.Add( '/I' )
            [void]$parameters.Add( $OnIdle )
        }
        'OnEvent'
        {
            $modifier = $EventXPathQuery
        }
        'Xml*'
        {
            if( $PSCmdlet.ParameterSetName -eq 'Xml' )
            {
                $TaskXmlFilePath = 'Carbon+Install-CScheduledTask+{0}.xml' -f [IO.Path]::GetRandomFileName()
                $TaskXmlFilePath = Join-Path -Path $env:TEMP -ChildPath $TaskXmlFilePath
                $TaskXml.Save($TaskXmlFilePath)
            }

            $scheduleType = $null
            $TaskXmlFilePath = Resolve-Path -Path $TaskXmlFilePath
            if( -not $TaskXmlFilePath )
            {
                return
            }

            [void]$parameters.Add( '/XML' )
            [void]$parameters.Add( $TaskXmlFilePath )
        }
    }

    try
    {
        if( $modifier )
        {
            [void]$parameters.Add( '/MO' )
            [void]$parameters.Add( $modifier )
        }

        if( $PSBoundParameters.ContainsKey('TaskToRun') )
        {
            [void]$parameters.Add( '/TR' )
            [void]$parameters.Add( $TaskToRun )
        }

        if( $scheduleType )
        {
            [void]$parameters.Add( '/SC' )
            [void]$parameters.Add( $scheduleType )
        }


        $parameterNameToSchtasksMap = @{
                                            'StartTime' = '/ST';
                                            'Interval' = '/RI';
                                            'EndTime' = '/ET';
                                            'Duration' = '/DU';
                                            'StopAtEnd' = '/K';
                                            'StartDate' = '/SD';
                                            'EndDate' = '/ED';
                                            'EventChannelName' = '/EC';
                                            'Interactive' = '/IT';
                                            'NoPassword' = '/NP';
                                            'Force' = '/F';
                                            'Delay' = '/DELAY';
                                      }

        foreach( $parameterName in $parameterNameToSchtasksMap.Keys )
        {
            if( -not $PSBoundParameters.ContainsKey( $parameterName ) )
            {
                continue
            }

            $schtasksParamName = $parameterNameToSchtasksMap[$parameterName]
            $value = $PSBoundParameters[$parameterName]
            if( $value -is [timespan] )
            {
                if( $parameterName -eq 'Duration' )
                {
                    $totalHours = ($value.Days * 24) + $value.Hours
                    $value = '{0:0000}:{1:00}' -f $totalHours,$value.Minutes
                }
                elseif( $parameterName -eq 'Delay' )
                {
                    $totalMinutes = ($value.Days * 24 * 60) + ($value.Hours * 60) + $value.Minutes
                    $value = '{0:0000}:{1:00}' -f $totalMinutes,$value.Seconds
                }
                else
                {
                    $value = '{0:00}:{1:00}' -f $value.Hours,$value.Minutes
                }
            }
            elseif( $value -is [datetime] )
            {
                $value = $value.ToString('MM/dd/yyyy')
            }

            [void]$parameters.Add( $schtasksParamName )

            if( $value -isnot [switch] )
            {
                [void]$parameters.Add( $value )
            }
        }

        if( $PSBoundParameters.ContainsKey('HighestAvailableRunLevel') -and $HighestAvailableRunLevel )
        {
            [void]$parameters.Add( '/RL' )
            [void]$parameters.Add( 'HIGHEST' )
        }

        $originalEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $paramLogString = $parameters -join ' '
        if( $TaskCredential )
        {
            $paramLogString = $paramLogString -replace ([Text.RegularExpressions.Regex]::Escape($TaskCredential.GetNetworkCredential().Password)),'********'
        }
        Write-Verbose ('/TN {0} {1}' -f $Name,$paramLogString)
        # Warnings get written by schtasks to the error stream. Fortunately, errors and warnings
        # are prefixed with ERRROR and WARNING, so we can combine output/error streams and parse
        # it later. We just have to make sure we remove any errors added to the $Error variable.
        $preErrorCount = $Global:Error.Count
        $output = schtasks /create /TN $Name $parameters 2>&1
        $postErrorCount = $Global:Error.Count
        if( $postErrorCount -gt $preErrorCount )
        {
            $numToDelete = $postErrorCount - $preErrorCount
            for( $idx = 0; $idx -lt $numToDelete; ++$idx )
            {
                $Global:Error.RemoveAt(0)
            }
        }
        $ErrorActionPreference = $originalEap

        $createFailed = $false
        if( $LASTEXITCODE )
        {
            $createFailed = $true
        }

        $output | ForEach-Object {
            if( $_ -match '\bERROR\b' )
            {
                Write-Error $_
            }
            elseif( $_ -match '\bWARNING\b' )
            {
                Write-Warning ($_ -replace '^WARNING: ','')
            }
            else
            {
                Write-Verbose $_
            }
        }

        if( -not $createFailed )
        {
            Get-CScheduledTask -Name $Name -NoWarn
        }
    }
    finally
    {
        if( $PSCmdlet.ParameterSetName -eq 'Xml' -and (Test-Path -Path $TaskXmlFilePath -PathType Leaf) )
        {
            Remove-Item -Path $TaskXmlFilePath -ErrorAction SilentlyContinue
        }
    }
}

function Install-CService
{
    <#
    .SYNOPSIS
    Installs a Windows service.

    .DESCRIPTION
    `Install-CService` uses `sc.exe` to install a Windows service. If a service with the given name already exists, it
    is stopped, its configuration is updated to match the parameters passed in, and then re-started. Settings whose
    parameters are omitted are reset to their default values.

    Beginning in Carbon 2.0, use the `PassThru` switch to return a `ServiceController` object for the new/updated
    service.

    By default, the service is installed to run as `NetworkService`. Use the `Credential` parameter to run as a
    different account (if you don't have a `Credential` parameter, upgrade to Carbon 2.0 or use the `UserName` and
    `Password` parameters). This user will be granted the logon as a service right. To run as a system account other
    than `NetworkService`, provide just the account's name as the `UserName` parameter.

    The minimum required information to install a service is its name and path.

    [Managed service accounts and virtual accounts](http://technet.microsoft.com/en-us/library/dd548356.aspx) should be
    supported (we don't know how to test, so can't be sure).  Simply omit the `-Password` parameter when providing a
    custom account name with the `-Username` parameter.

    `Manual` services are not started. `Automatic` services are started after installation. If an existing manual
    service is running when configuration begins, it is re-started after re-configured. If a service is stopped when
    configuration begins, it remains stopped when configuration ends. To start the service if it is stopped, use the
    `-EnsureRunning` switch (which was added in version 2.5.0).

    The ability to provide service arguments/parameters via the `ArgumentList` parameter was added in Carbon 2.0.

    .LINK
    New-CCredential

    .LINK
    Uninstall-CService

    .LINK
    http://technet.microsoft.com/en-us/library/dd548356.aspx

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe

    Installs the Death Star service, which runs the service executable at
    `C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe`.  The service runs as `NetworkService` and will start
    automatically.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Manual

    Install the Death Star service to startup manually.  You certainly don't want the thing roaming the galaxy,
    destroying thing willy-nilly, do you?

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Automatic -Delayed

    Demonstrates how to set a service startup typemode to automatic delayed. Set the `StartupType` parameter to
    `Automatic` and provide the `Delayed` switch. This behavior was added in Carbon 2.5.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Credential $tarkinCredentials

    Installs the Death Star service to run as Grand Moff Tarkin, who is given the log on as a service right.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Username SYSTEM

    Demonstrates how to install a service to run as a system account other than `NetworkService`. Installs the
    DeathStart service to run as the local `System` account.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -OnFirstFailure RunCommand -RunCommandDelay 5000 -Command 'engage_hyperdrive.exe "Corruscant"' -OnSecondFailure Restart -RestartDelay 30000 -OnThirdFailure Reboot -RebootDelay 120000 -ResetFailureCount (60*60*24)

    Demonstrates how to control the service's failure actions. On the first failure, Windows will run the
    `engage-hyperdrive.exe "Corruscant"` command after 5 seconds (`5,000` milliseconds). On the second failure, Windows
    will restart the service after 30 seconds (`30,000` milliseconds). On the third failure, Windows will reboot after
    two minutes (`120,000` milliseconds). The failure count gets reset once a day (`60*60*24` seconds).

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -EnsureRunning

    Demonstrates how to ensure a service gets started after installation/configuration. Normally, `Install-CService`
    leaves the service in whatever state the service was in. The `EnsureRunnnig` switch will attempt to start the
    service even if it was stopped to begin with.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='NetworkServiceAccount')]
    [OutputType([ServiceProcess.ServiceController])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    param(
        # The name of the service.
        [Parameter(Mandatory)]
        [String] $Name,

        # The path to the service.
        [Parameter(Mandatory)]
        [String] $Path,

        # The arguments/startup parameters for the service. Added in Carbon 2.0.
        [String[]] $ArgumentList,

        # The startup type: automatic, manual, or disabled.  Default is automatic.
        #
        # To start the service as automatic delayed, use the `-Delayed` switch and set this parameter to `Automatic`.
        # The ability to set a service's startup type to automatic delayed was added in Carbon 2.5.
        [ServiceProcess.ServiceStartMode] $StartupType = [ServiceProcess.ServiceStartMode]::Automatic,

        # When the startup type is automatic, further configure the service start type to be automatic delayed. This
        # parameter is ignored unless `StartupType` is `Automatic`.
        #
        # This switch was added in Carbon 2.5.
        [switch] $Delayed,

        # What to do on the service's first failure.  Default is to take no action.
        [Carbon.Service.FailureAction] $OnFirstFailure = [Carbon.Service.FailureAction]::TakeNoAction,

        # What to do on the service's second failure. Default is to take no action.
        [Carbon.Service.FailureAction] $OnSecondFailure = [Carbon.Service.FailureAction]::TakeNoAction,

        # What to do on the service' third failure.  Default is to take no action.
        [Carbon.Service.FailureAction] $OnThirdFailure = [Carbon.Service.FailureAction]::TakeNoAction,

        # How many seconds after which the failure count is reset to 0.
        [int] $ResetFailureCount = 0,

        # How many milliseconds to wait before restarting the service.  Default is 60,0000, or 1 minute.
        [int] $RestartDelay = 60000,

        # How many milliseconds to wait before handling the second failure.  Default is 60,000 or 1 minute.
        [int] $RebootDelay = 60000,

        # What other services does this service depend on?
        [Alias('Dependencies')]
        [String[]] $Dependency,

        # The command to run when a service fails, including path to the command and arguments.
        [String] $Command,

        # How many milliseconds to wait before running the failure command. Default is 0, or immediately.
        [int] $RunCommandDelay = 0,

        # The service's description. If you don't supply a value, the service's existing description is preserved.
        #
        # The `Description` parameter was added in Carbon 2.0.
        [String] $Description,

        # The service's display name. If you don't supply a value, the display name will set to Name.
        #
        # The `DisplayName` parameter was added in Carbon 2.0.
        [String] $DisplayName,

        [Parameter(ParameterSetName='CustomAccount', Mandatory)]
        [string]
        # The user the service should run as. Default is `NetworkService`.
        $UserName,

        [Parameter(ParameterSetName='CustomAccount', DontShow)]
        [string]
        # OBSOLETE. The `Password` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
        $Password,

        [Parameter(ParameterSetName='CustomAccountWithCredential',Mandatory)]
        [pscredential]
        # The credential of the account the service should run as.
        #
        # The `Credential` parameter was added in Carbon 2.0.
        $Credential,

        [Switch]
        # Update the service even if there are no changes.
        $Force,

        [Switch]
        # Return a `System.ServiceProcess.ServiceController` object for the configured service.
        $PassThru,

        [Switch]
        # Start the service after install/configuration if it is not running. This parameter was added in Carbon 2.5.0.
        $EnsureRunning,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    function ConvertTo-FailureActionArg($action)
    {
        if( $action -eq 'Reboot' )
        {
            return "reboot/{0}" -f $RebootDelay
        }
        elseif( $action -eq 'Restart' )
        {
            return "restart/{0}" -f $RestartDelay
        }
        elseif( $action -eq 'RunCommand' )
        {
            return 'run/{0}' -f $RunCommandDelay
        }
        elseif( $action -eq 'TakeNoAction' )
        {
            return '""/0'
        }
        else
        {
            Write-Error "Service failure action '$action' not found/recognized."
            return ''
        }
    }

    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
    {
        if( $PSCmdlet.ParameterSetName -like '*WithCredential' )
        {
            $UserName = $Credential.UserName
        }
        elseif( $Password )
        {
            Write-CWarningOnce ('`Install-CService` function''s `Password` parameter is obsolete and will be removed in a future major version of Carbon. Please use the `Credential` parameter instead.')
            $Credential = New-CCredential -UserName $UserName -Password $Password
        }
        else
        {
            $Credential = $null
        }


        $identity = Resolve-CIdentity -Name $UserName -NoWarn

        if( -not $identity )
        {
            Write-Error ("Identity '{0}' not found." -f $UserName)
            return
        }
    }
    else
    {
        $identity = Resolve-CIdentity "NetworkService" -NoWarn
    }

    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Warning ('Service ''{0}'' executable ''{1}'' not found.' -f $Name,$Path)
    }
    else
    {
        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath
    }


    if( $ArgumentList )
    {
        $binPathArg = Invoke-Command -ScriptBlock {
                            $Path
                            $ArgumentList
                        } |
                        ForEach-Object {
                            if( $_.Contains(' ') )
                            {
                                return '"{0}"' -f $_.Trim('"')
                            }
                            return $_
                        }
        $binPathArg = $binPathArg -join ' '
    }
    else
    {
        $binPathArg = $Path
    }

    $passwordArgMsg = ''
    $passwordArgName = $null
    $passwordArgValue = $null
    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
    {
        if( $Credential )
        {
            $passwordArgName = 'password='
            $password = $Credential.GetNetworkCredential().Password
            $passwordArgValue = $password | ConvertTo-CArgValue
            $passwordArgMsg = " ${passwordArgName} $('*' * $password.Length)"
        }

        if( $PSCmdlet.ShouldProcess( $identity.FullName, "grant the log on as a service right" ) )
        {
            Grant-CPrivilege -Identity $identity.FullName -Privilege SeServiceLogonRight -NoWarn
        }
    }

    if( $PSCmdlet.ShouldProcess( $Path, ('grant {0} ReadAndExecute permissions' -f $identity.FullName) ) )
    {
        Grant-CPermission -Identity $identity.FullName -Permission ReadAndExecute -Path $Path -NoWarn
    }

    $doInstall = $false
    if( -not $Force -and (Test-CService -Name $Name -NoWarn) )
    {
        Write-Debug -Message ('Service {0} exists. Checking if configuration has changed.' -f $Name)
        $service = Get-Service -Name $Name
        $serviceConfig = Get-CServiceConfiguration -Name $Name -NoWarn
        $dependedOnServiceNames =
            $service.ServicesDependedOn | Where-Object 'Name' -NE $Name | Select-Object -ExpandProperty 'Name'

        if( $service.Path -ne $binPathArg )
        {
            Write-Verbose ('[{0}] Path              {1} -> {2}' -f $Name,$serviceConfig.Path,$binPathArg)
            $doInstall = $true
        }

        # DisplayName, if not set, defaults to the service name. This makes it a little bit tricky to update.
        # If provided, make sure display name matches.
        # If not provided, reset it to an empty/default value.
        if( $PSBoundParameters.ContainsKey('DisplayName') )
        {
            if( $service.DisplayName -ne $DisplayName )
            {
                Write-Verbose ('[{0}] DisplayName       {1} -> {2}' -f $Name,$service.DisplayName,$DisplayName)
                $doInstall = $true
            }
        }
        elseif( $service.DisplayName -ne $service.Name )
        {
            Write-Verbose ('[{0}] DisplayName       {1} -> ' -f $Name,$service.DisplayName)
            $doInstall = $true
        }

        if( $serviceConfig.FirstFailure -ne $OnFirstFailure )
        {
            Write-Verbose ('[{0}] OnFirstFailure    {1} -> {2}' -f $Name,$serviceConfig.FirstFailure,$OnFirstFailure)
            $doInstall = $true
        }

        if( $serviceConfig.SecondFailure -ne $OnSecondFailure )
        {
            Write-Verbose ('[{0}] OnSecondFailure   {1} -> {2}' -f $Name,$serviceConfig.SecondFailure,$OnSecondFailure)
            $doInstall = $true
        }

        if( $serviceConfig.ThirdFailure -ne $OnThirdFailure )
        {
            Write-Verbose ('[{0}] OnThirdFailure    {1} -> {2}' -f $Name,$serviceConfig.ThirdFailure,$OnThirdFailure)
            $doInstall = $true
        }

        if( $serviceConfig.ResetPeriod -ne $ResetFailureCount )
        {
            Write-Verbose ('[{0}] ResetFailureCount {1} -> {2}' -f $Name,$serviceConfig.ResetPeriod,$ResetFailureCount)
            $doInstall = $true
        }

        $failureActions = $OnFirstFailure,$OnSecondFailure,$OnThirdFailure
        if( ($failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::Reboot }) -and $serviceConfig.RebootDelay -ne $RebootDelay )
        {
            Write-Verbose ('[{0}] RebootDelay       {1} -> {2}' -f $Name,$serviceConfig.RebootDelay,$RebootDelay)
            $doInstall = $true
        }

        if( ($failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::Restart }) -and $serviceConfig.RestartDelay -ne $RestartDelay)
        {
            Write-Verbose ('[{0}] RestartDelay      {1} -> {2}' -f $Name,$serviceConfig.RestartDelay,$RestartDelay)
            $doInstall = $true
        }

        if( $failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::RunCommand } )
        {
            if( $serviceConfig.FailureProgram -ne $Command )
            {
                Write-Verbose ('[{0}] Command           {1} -> {2}' -f $Name,$serviceConfig.FailureProgram,$Command)
                $doInstall = $true
            }

            if( $serviceConfig.RunCommandDelay -ne $RunCommandDelay )
            {
                Write-Verbose ('[{0}] RunCommandDelay   {1} -> {2}' -f $Name,$serviceConfig.RunCommandDelay,$RunCommandDelay)
                $doInstall = $true
            }
        }

        if( $service.StartMode -ne $StartupType )
        {
            Write-Verbose ('[{0}] StartupType       {1} -> {2}' -f $Name,$serviceConfig.StartType,$StartupType)
            $doInstall = $true
        }

        if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic -and $Delayed -ne $serviceConfig.DelayedAutoStart )
        {
            Write-Verbose ('[{0}] DelayedAutoStart  {1} -> {2}' -f $Name,$service.DelayedAutoStart,$Delayed)
            $doInstall = $true
        }

        if( ($Dependency | Where-Object { $dependedOnServiceNames -notcontains $_ }) -or `
            ($dependedOnServiceNames | Where-Object { $Dependency -notcontains $_ })  )
        {
            Write-Verbose ('[{0}] Dependency        {1} -> {2}' -f $Name,($dependedOnServiceNames -join ','),($Dependency -join ','))
            $doInstall = $true
        }

        if( $Description -and $serviceConfig.Description -ne $Description )
        {
            Write-Verbose ('[{0}] Description       {1} -> {2}' -f $Name,$serviceConfig.Description,$Description)
            $doInstall = $true
        }

        $currentIdentity = Resolve-CIdentity $serviceConfig.UserName -NoWarn
        if( $currentIdentity.FullName -ne $identity.FullName )
        {
            Write-Verbose ('[{0}] UserName          {1} -> {2}' -f $Name,$currentIdentity.FullName,$identity.FullName)
            $doinstall = $true
        }
    }
    else
    {
        $doInstall = $true
    }

    try
    {
        if( -not $doInstall )
        {
            Write-Debug -Message ('Skipping {0} service configuration: settings unchanged.' -f $Name)
            return
        }

        if( $Dependency )
        {
            $missingDependencies = $false
            foreach ($dependencyName in $Dependency)
            {
                if (-not (Test-CService -Name $dependencyName -NoWarn))
                {
                    $msg = "Dependent service ""${dependencyName}"" not found."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    $missingDependencies = $true
                }
            }
            if( $missingDependencies )
            {
                return
            }
        }

        $sc = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'sc.exe' -Resolve

        $startArg = 'auto'
        if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic -and $Delayed )
        {
            $startArg = 'delayed-auto'
        }
        elseif( $StartupType -eq [ServiceProcess.ServiceStartMode]::Manual )
        {
            $startArg = 'demand'
        }
        elseif( $StartupType -eq [ServiceProcess.ServiceStartMode]::Disabled )
        {
            $startArg = 'disabled'
        }

        $service = Get-Service -Name $Name -ErrorAction Ignore

        $operation = 'create'
        $serviceIsRunningStatus = @(
                                      [ServiceProcess.ServiceControllerStatus]::Running,
                                      [ServiceProcess.ServiceControllerStatus]::StartPending
                                   )

        if( -not $EnsureRunning )
        {
            $EnsureRunning = ($StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic)
        }

        if( $service )
        {
            $EnsureRunning = ( $EnsureRunning -or ($serviceIsRunningStatus -contains $service.Status) )
            if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Disabled )
            {
                $EnsureRunning = $false
            }

            if( $service.CanStop )
            {
                Stop-Service -Name $Name -Force -ErrorAction Ignore
                if( $? )
                {
                    $service.WaitForStatus( 'Stopped' )
                }
            }

            if( -not ($service.Status -eq [ServiceProcess.ServiceControllerStatus]::Stopped) )
            {
                Write-Warning "Unable to stop service '$Name' before applying config changes.  You may need to restart this service manually for any changes to take affect."
            }
            $operation = 'config'
        }

        $dependencyArgMsg = ''
        $dependencyArgName = $null
        $dependencyArgValue = $null
        if ($Dependency -or $doInstall)
        {
            $dependencyArgName = 'depend='
            $dependencyArgValue = $Dependency -join '/' | ConvertTo-CArgValue
            $dependencyArgMsg = " ${dependencyArgName} ${dependencyArgValue}"
        }

        $displayNameArgMsg = ''
        $displayNameArgName = $null
        $displayNameArgValue = $null
        if ($DisplayName -or $doInstall)
        {
            $displayNameArgName ='DisplayName='
            $displayNameArgValue = $DisplayName | ConvertTo-CArgValue
            $displayNameArgMsg = " ${displayNameArgName} ${displayNameArgValue}"
        }

        $binPathArg = $binPathArg | ConvertTo-CArgValue
        if ($PSCmdlet.ShouldProcess( "$Name [$Path]", "$operation service" ))
        {
            $msg = "${sc} ${operation} ${Name} binPath= ${binPathArg} start= ${startArg} obj= $($identity.FullName)" +
                   "${passwordArgMsg}${dependencyArgMsg}${displayNameArgMsg}"
            Write-Information $msg
            & $sc $operation `
                  $Name `
                  binPath= $binPathArg `
                  start= $startArg `
                  obj= $identity.FullName `
                  $passwordArgName $passwordArgValue `
                  $dependencyArgName $dependencyArgValue `
                  $displayNameArgName $displayNameArgValue |
                Write-Verbose
            $scExitCode = $LASTEXITCODE
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to {0} service '{1}'. {2} returned exit code {3}: {4}" -f $operation,$Name,$sc,$scExitCode,$reason)
                return
            }

            if( $Description )
            {
                Write-Information "${sc} description ${Name} ${Description}"
                & $sc 'description' $Name ($Description | ConvertTo-CArgValue) | Write-Verbose
                $scExitCode = $LASTEXITCODE
                if( $scExitCode -ne 0 )
                {
                    $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                    Write-Error ("Failed to set {0} service's description. {1} returned exit code {2}: {3}" -f $Name,$sc,$scExitCode,$reason)
                    return
                }
            }
        }

        $firstAction = ConvertTo-FailureActionArg $OnFirstFailure
        $secondAction = ConvertTo-FailureActionArg $OnSecondFailure
        $thirdAction = ConvertTo-FailureActionArg $OnThirdFailure

        $commandArgValue = $Command | ConvertTo-CArgValue
        if ($PSCmdlet.ShouldProcess($Name, 'setting service failure actions'))
        {
            $msg = "${sc} failure ${Name} reset= ${ResetFailureCount} " +
                   "${firstAction}/${secondAction}/${thirdAction} command= ${commandArgValue}"
            Write-Information $msg
            & $sc failure `
                  $Name `
                  reset= $ResetFailureCount `
                  actions= $firstAction/$secondAction/$thirdAction `
                  command= $commandArgValue |
                Write-Verbose
            $scExitCode = $LASTEXITCODE
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to set {0} service's failure actions. {1} returned exit code {2}: {3}" -f $Name,$sc,$scExitCode,$reason)
                return
            }
        }
    }
    finally
    {
        if( $EnsureRunning )
        {
            if( $PSCmdlet.ShouldProcess( $Name, 'start service' ) )
            {
                Start-Service -Name $Name -ErrorAction $ErrorActionPreference -WarningAction SilentlyContinue
                if( (Get-Service -Name $Name).Status -ne [ServiceProcess.ServiceControllerStatus]::Running )
                {
                    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' -and -not $Credential )
                    {
                        Write-Warning ('Service ''{0}'' didn''t start and you didn''t supply a password to Install-CService.  Is ''{1}'' a managed service account or virtual account? (See http://technet.microsoft.com/en-us/library/dd548356.aspx.)  If not, please use the `Credential` parameter to pass the account''s credentials.' -f $Name,$UserName)
                    }
                    else
                    {
                        Write-Warning ('Failed to re-start service ''{0}''.' -f $Name)
                    }
                }
            }
        }
        else
        {
            Write-Verbose ('Not re-starting {0} service. Its startup type is {1} and it wasn''t running when configuration began. To always start a service after configuring it, use the -EnsureRunning switch.' -f $Name,$StartupType)
        }

        if( $PassThru )
        {
            Get-Service -Name $Name -ErrorAction Ignore
        }
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
        Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $activationConfigDir -ForProcess -NoWarn
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
                Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $originalCOMAppConfigEnvVar -ForProcess -NoWarn
            }
            else
            {
                Remove-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -ForProcess -NoWarn
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


function New-CTempDirectory
{
    <#
    .SYNOPSIS
    Creates a new temporary directory with a random name.

    .DESCRIPTION
    A new temporary directory is created in the current user's `env:TEMP` directory.  The directory's name is created using the `Path` class's [GetRandomFileName method](http://msdn.microsoft.com/en-us/library/system.io.path.getrandomfilename.aspx).

    To add a custom prefix to the directory name, use the `Prefix` parameter. If you pass in a path, only its name will be used. In this way, you can pass `$MyInvocation.MyCommand.Definition` (PowerShell 2) or `$PSCommandPath` (PowerShell 3+), which will help you identify what scripts are leaving cruft around in the temp directory.

    Added `-WhatIf` support in Carbon 2.0.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.io.path.getrandomfilename.aspx

    .EXAMPLE
    New-CTempDirectory

    Demonstrates how to create a new temporary directory, e.g. `C:\Users\ajensen\AppData\Local\Temp\5pobd3tu.5rn`.

    .EXAMPLE
    New-CTempDirectory -Prefix 'Carbon'

    Demonstrates how to create a new temporary directory with a custom prefix for its name, e.g. `C:\Users\ajensen\AppData\Local\Temp\Carbon5pobd3tu.5rn`.

    .EXAMPLE
    New-CTempDirectory -Prefix $MyInvocation.MyCommand.Definition

    Demonstrates how you can use `$MyInvocation.MyCommand.Definition` in PowerShell 2 to create a new, temporary directory, named after the currently executing scripts, e.g. `C:\Users\ajensen\AppData\Local\Temp\New-CTempDirectory.ps15pobd3tu.5rn`.

    .EXAMPLE
    New-CTempDirectory -Prefix $PSCommandPath

    Demonstrates how you can use `$PSCommandPath` in PowerShell 3+ to create a new, temporary directory, named after the currently executing scripts, e.g. `C:\Users\ajensen\AppData\Local\Temp\New-CTempDirectory.ps15pobd3tu.5rn`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([IO.DirectoryInfo])]
    param(
        [string]
        # A prefix to use, so you can more easily identify *what* created the temporary directory. If you pass in a path, it will be converted to a file name.
        $Prefix,

        # If set, hides the warning that this command is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.FileSystem' `
                                    -NoWarn:$NoWarn

    $tempDir = [IO.Path]::GetRandomFileName()
    if( $Prefix )
    {
        $Prefix = Split-Path -Leaf -Path $Prefix
        $tempDir = '{0}{1}' -f $Prefix,$tempDir
    }

    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' -Verbose:$VerbosePreference
}

Set-Alias -Name 'New-TempDir' -Value 'New-CTempDirectory'


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



function Remove-CEnvironmentVariable
{
    <#
    .SYNOPSIS
    Removes an environment variable.

    .DESCRIPTION
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to remove an environment
    variable from the Process, User, or Computer scopes.

    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running
    processes that use this environment variable should be restarted.

    Normally, you have to restart your PowerShell session/process to no longer see the variable in the `env:` drive. Use
    the `-Force` switch to also remove the variable from the `env:` drive. This functionality was added in Carbon 2.3.0.

    Beginning with Carbon 2.3.0, you can set an environment variable for a specific user by specifying the `-ForUser`
    switch and passing the user's credentials with the `-Credential` parameter. This runs a separate PowerShell process
    as that user to remove the variable.

    Beginning in Carbon 2.3.0, you can specify multiple scopes from which to remove an environment variable. In previous
    versions, you could only remove from one scope.

    .LINK
    Set-CEnvironmentVariable

    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Remove-CEnvironmentVariable -Name 'MyEnvironmentVariable' -ForProcess

    Removes the `MyEnvironmentVariable` from the process scope.

    .EXAMPLE
    Remove-CEnvironmentVariable -Name 'SomeUsersVariable' -ForUser -Credential $credential

    Demonstrates that you can remove another user's user-level environment variable by passing its credentials to the
    `Credential` parameter. This runs a separate PowerShell process as that user to remove the variable.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        # The environment variable to remove.
        [String] $Name,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Removes the environment variable for the current computer.
        [switch] $ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory, ParameterSetName='ForSpecificUser')]
        # Removes the environment variable for the current user.
        [switch] $ForUser,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Removes the environment variable for the current process.
        [switch] $ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Remove the variable from the current PowerShell session's `env:` drive, too. Normally, you have to restart
        # your session to no longer see the variable in the `env:` drive.
        #
        # This parameter was added in Carbon 2.3.0.
        [switch] $Force,

        [Parameter(Mandatory, ParameterSetName='ForSpecificUser')]
        # Remove an environment variable for a specific user.
        [pscredential] $Credential,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Environment'
    }

    if ($PSCmdlet.ParameterSetName -eq 'ForSpecificUser')
    {
        $parameters = $PSBoundParameters
        $parameters.Remove('Credential')
        $job = Start-Job -ScriptBlock {
            Import-Module -Name (Join-Path -Path $using:carbonRoot -ChildPath 'Carbon.psd1')
            $VerbosePreference = $using:VerbosePreference
            $ErrorActionPreference = $using:ErrorActionPreference
            $DebugPreference = $using:DebugPreference
            $WhatIfPreference = $using:WhatIfPreference
            Remove-CEnvironmentVariable @using:parameters
        } -Credential $Credential
        $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force -ErrorAction Ignore
        return
    }

    if (-not $ForProcess -and -not $ForUser -and -not $ForComputer)
    {
        $msg = 'Environment variable target not specified. You must supply one of the ForComputer, ForUser, or ' +
               'ForProcess switches.'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    Invoke-Command -ScriptBlock {
            if( $ForComputer )
            {
                [EnvironmentVariableTarget]::Machine
            }

            if( $ForUser )
            {
                [EnvironmentVariableTarget]::User
            }

            if( $ForProcess )
            {
                [EnvironmentVariableTarget]::Process
            }
        } |
        Where-Object { $PSCmdlet.ShouldProcess( "${_}-level environment variable ""${Name}""", "remove" ) } |
        ForEach-Object {
                $scope = $_
                [Environment]::SetEnvironmentVariable( $Name, [NullString]::Value, $scope )
                if ($Force -and $scope -ne [EnvironmentVariableTarget]::Process)
                {
                    [Environment]::SetEnvironmentVariable($Name, [NullString]::Value, 'Process')
                }
            }
}

function Remove-CGroupMember
{
    <#
    .SYNOPSIS
    Removes users or groups from a *local* group.

    .DESCRIPTION
    You would think it's pretty easy and straight-forward to remove users/groups from a local group, but you would be wrong.  The quick solution is to use `net localgroup`, but that won't accept user/group names longer than 24 characters.  This means you have to use the .NET Directory Services APIs.  How do you reliably remove both users *and* groups?  What if those users are in a domain?  What if they're in another domain?  What about built-in users?  Fortunately, your brain hasn't exploded.

    So, this function removes users or groups from a *local* group.

    If the user or group is not a member, nothing happens.

    `Remove-CGroupMember` is new in Carbon 2.0.

    .EXAMPLE
    Remove-CGroupMember -Name Administrators -Member EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Removes Darth Vader, Emperor Palpatine and Luke Skywalker from the local administrators group.

    .EXAMPLE
    Remove-CGroupMember -Name TieFighters -Member NetworkService

    Removes the local NetworkService account from the local TieFighters group.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The group name.
        $Name,

        [Parameter(Mandatory=$true)]
        [string[]]
        # The users/groups to remove from a group.
		[Alias('Members')]
        $Member,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Uninstall-CLocalGroupMember' `
                                    -NoWarn:$NoWarn

    [DirectoryServices.AccountManagement.GroupPrincipal]$group = Get-CGroup -Name $Name -NoWarn
    if( -not $group )
    {
        return
    }

    try
    {
        foreach( $_member in $Member )
        {
            $identity = Resolve-CIdentity -Name $_member -NoWarn
            if( -not $identity )
            {
                continue
            }

            if( -not (Test-CGroupMember -GroupName $group.Name -Member $_member) )
            {
                continue
            }

            Write-Verbose -Message ('[{0}] Members      {1} ->' -f $Name,$identity.FullName)
            if( -not $PSCmdlet.ShouldProcess(('removing "{0}" from local group "{1}"' -f $identity.FullName, $group.Name), $null, $null) )
            {
                continue
            }

            try
            {
                $identity.RemoveFromLocalGroup( $group.Name )
            }
            catch
            {
                Write-Error ('Failed to remove "{0}" from local group "{1}": {2}.' -f $identity,$group.Name,$_)
            }
        }
    }
    finally
    {
        $group.Dispose()
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

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Accounts'
    }

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



function Resolve-CIdentityName
{
    <#
    .SYNOPSIS
    Determines the full, NT identity name for a user or group.

    .DESCRIPTION
    `Resolve-CIdentityName` resolves a user/group name into its full, canonical name, used by the operating system. For example, the local Administrators group is actually called BUILTIN\Administrators. With a canonical username, you can unambiguously compare principals on objects that contain user/group information.

    If unable to resolve a name into an identity, `Resolve-CIdentityName` returns nothing.

    If you want to get full identity information (domain, type, sid, etc.), use `Resolve-CIdentity`.

    In Carbon 2.0, you can also resolve a SID into its identity name. The `SID` parameter accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes. If the SID no longer maps to an active account, you'll get the original SID in SDDL form (as a string) returned to you.

    .LINK
    ConvertTo-CSecurityIdentifier

    .LINK
    Resolve-CIdentity

    .LINK
    Test-CIdentity

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx

    .OUTPUTS
    string

    .EXAMPLE
    Resolve-CIdentityName -Name 'Administrators'

    Returns `BUILTIN\Administrators`, the canonical name for the local Administrators group.
    #>
    [CmdletBinding(DefaultParameterSetName='ByName')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByName',Position=0)]
        [string]
        # The name of the identity to return.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='BySid')]
        # Get an identity's name from its SID. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
        #
        # This parameter is new in Carbon 2.0.
        $SID,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -Module 'Carbon.Accounts'
    }

    if( $PSCmdlet.ParameterSetName -eq 'ByName' )
    {
        return Resolve-CIdentity -Name $Name -NoWarn -ErrorAction Ignore | Select-Object -ExpandProperty 'FullName'
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'BySid' )
    {
        $SID = ConvertTo-CSecurityIdentifier -SID $SID
        if( -not $SID )
        {
            return
        }

        $id = [Carbon.Identity]::FindBySid( $SID )
        if( $id )
        {
            return $id.FullName
        }
        else
        {
            return $SID.ToString()
        }
    }

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



function Resolve-CPrivateKeyPath
{
    <#
    .SYNOPSIS
    Finds the path to a certificate's private key.

    .DESCRIPTION
    The `Resolve-CPrivateKeyPath` function finds the path to a certificate's private key. Pipe the certificate object to
    the function (or pass one or more to the `Certificate` parameter). The function searches all the directories where
    keys are stored, [which are documented by
    Microsoft](https://learn.microsoft.com/en-us/windows/win32/seccng/key-storage-and-retrieval).

    If the certificate doesn't have a private key, have access to the private key, or no private key file exists, the
    function writes an error and returns nothing for that certificate.

    Returns the path to the private key as a string.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/seccng/key-storage-and-retrieval

    .EXAMPLE
    $cert | Resolve-CPrivateKeyPath

    Demonstrates that you can pipe X509Certificate2 objects to this function.

    .EXAMPLE
    Resolve-CPrivateKeyPath -Certificate $cert

    Demonstrates that you pass an X509Certificate2 object to the `Certificate` parameter.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        # The certificate whose private key path to get. Must have a private key and that private key must be accessible
        # by the current user.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Security.Cryptography.X509Certificates.X509Certificate2[]] $Certificate
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $searchPaths =
            & {
                $appData = [Environment]::GetFolderPath('ApplicationData')
                if ($appData)
                {
                    if ($IsWindows)
                    {
                        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
                        $sidString = $sid.ToString()

                        # CSP user private
                        Join-Path -Path $appData -ChildPath "Microsoft\Crypto\RSA\${sidString}"
                        Join-Path -Path $appData -ChildPath "Microsoft\Crypto\DSS\${sidString}"
                    }

                    # CNG user private
                    Join-Path -Path $appData -ChildPath "Microsoft\Crypto\Keys"
                }

                $commonAppDataPath = [Environment]::GetFolderPath('CommonApplicationData')
                if ($commonAppDataPath)
                {
                    # CSP local system private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\S-1-5-18'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\S-1-5-18'

                    # CNG local system private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\SystemKeys'

                    # CSP local service private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\S-1-5-19'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\S-1-5-19'

                    # CSP network service private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\S-1-5-20'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\S-1-5-20'

                    # CSP shared private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\RSA\MachineKeys'
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\DSS\MachineKeys'

                    # CNG shared private
                    Join-Path -Path $commonAppDataPath -ChildPath 'Application Data\Microsoft\Crypto\Keys'
                }

                $windowsPath = [Environment]::GetFolderPath('Windows')
                if ($windowsPath)
                {
                    # CNG local service private
                    Join-Path -Path $windowsPath -ChildPath 'ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Crypto\Keys'

                    # CNG network service private
                    Join-Path -Path $windowsPath -ChildPath 'ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Crypto\Keys'
                }
            } |
            Where-Object { $_ }

        $accessibleSearchPaths = $searchPaths | Where-Object { Test-Path -Path $_ -ErrorAction Ignore }
    }

    process
    {
        $foundOne = $false
        foreach ($cert in $Certificate)
        {
            $certErrMsg = "Failed to find the path to the ""$($certificate.Subject)"" ($($certificate.Thumbprint)) " +
                          'certificate''s private key because '
            if (-not $cert.HasPrivateKey)
            {
                $msg = "${certErrMsg}it does not have a private key."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            $privateKey = $cert.PrivateKey
            if (-not $privateKey)
            {
                try
                {
                    $privateKey =
                        [Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
                }
                catch
                {
                    $msg = "$($certErrMsg -replace ' because ', ': ') ${_}."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    continue
                }

                if (-not $privateKey)
                {
                    $msg = "${certErrMsg}the current user doesn't have permission to the private key."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    continue
                }
            }

            $fileName = ''
            if ($privateKey | Get-Member -Name 'CspKeyContainerInfo')
            {
                $fileName = $privateKey.CspKeyContainerInfo.UniqueKeyContainerName
            }
            elseif ($privateKey | Get-Member -Name 'Key')
            {
                $fileName = $privateKey.Key.UniqueName
            }

            if (-not $fileName)
            {
                $msg = "${certErrMsg}is of type [$($privateKey.GetType().FullName)], which is not currently " +
                       'supported by Carbon. [Please request support by submitting an issue on the project''s ' +
                       'GitHub issues page.](https://github.com/webmd-health-services/Carbon.Cryptography/issues/new)'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            $foundOne = $false
            $uniqueNameIsPath = $false
            if ($fileName | Split-Path)
            {
                $uniqueNameIsPath = $true
                if ((Test-Path -Path $fileName -PathType Leaf -ErrorAction Ignore))
                {
                    $foundOne = $true
                    $fileName | Write-Output
                }
            }
            else
            {
                foreach ($path in $accessibleSearchPaths)
                {
                    $fullPath = Join-Path -Path $path -ChildPath $fileName
                    if (-not (Test-Path -Path $fullPath -PathType Leaf -ErrorAction Ignore))
                    {
                        continue
                    }
                    $foundOne = $true
                    $fullPath | Write-Output
                }
            }

            if (-not $foundOne)
            {
                if ($uniqueNameIsPath)
                {
                    $msg = "${certErrMsg} its file, ""${fileName}"", doesn't exist."
                }
                else
                {
                    $msg = "${certErrMsg}its file, ""${fileName}"", doesn't exist in any of these " +
                           "directories:" + [Environment]::NewLine +
                           " " + [Environment]::NewLine +
                           "* $($searchPaths -join "$([Environment]::NewLine)* ")"
                }
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }
        }
    }
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

function Restart-CRemoteService
{
    <#
    .SYNOPSIS
    Restarts a service on a remote machine.

    .DESCRIPTION
    One of the annoying features of PowerShell is that the `Stop-Service`, `Start-Service` and `Restart-Service` cmdlets don't have `ComputerName` parameters to start/stop/restart a service on a remote computer.  You have to use `Get-Service` to get the remote service:

        $service = Get-Service -Name DeathStar -ComputerName Yavin
        $service.Stop()
        $service.Start()

        # or (and no, you can't pipe the service directly to `Restart-Service`)
        Get-Service -Name DeathStar -ComputerName Yavin |
            ForEach-Object { Restart-Service -InputObject $_ }

    This function does all this unnecessary work for you.

    You'll get an error if you attempt to restart a non-existent service.

    .EXAMPLE
    Restart-CRemoteService -Name DeathStar -ComputerName Yavin

    Restarts the `DeathStar` service on Yavin.  If the DeathStar service doesn't exist, you'll get an error.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service name to restart.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the computer where the service lives.
        $ComputerName,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $service = Get-Service -Name $name -ComputerName $computerName
    if($service)
    {
        if($pscmdlet.ShouldProcess( "$name on $computerName", "restart"))
        {
            $service.Stop()
            $service.Start()
        }
    }
    else
    {
        Write-Error "Unable to restart remote service because I could not get a reference to service $name on machine: $computerName"
    }
}

function Revoke-CPermission
{
    <#
    .SYNOPSIS
    Revokes *explicit* permissions on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Revokes all of an identity's *explicit* permissions on a file, directory, registry key, or certificate's private
    key/key container. Only explicit permissions are considered; inherited permissions are ignored.

    If the identity doesn't have permission, nothing happens, not even errors written out.

    .LINK
    Disable-CAclInheritance

    .LINK
    Enable-CAclInheritance

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Engineers -Path 'C:\EngineRoom'

    Demonstrates how to revoke all of the 'Engineers' permissions on the `C:\EngineRoom` directory.

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Interns -Path 'hklm:\system\WarpDrive'

    Demonstrates how to revoke permission on a registry key.

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Officers -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'

    Demonstrates how to revoke the Officers' permission to the
    `cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678` certificate's private key/key container.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path on which the permissions should be revoked.  Can be a file system, registry, or certificate path.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity losing permissions.
        [Parameter(Mandatory)]
        [String] $Identity,

        # ***Internal.*** Do not use.
        [String] $Description,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        $msg = "Carbon's $($MyInvocation.MyCommand.Name) function moved to the Carbon.Cryptography, " +
               'Carbon.FileSystem, and Carbon.Registry modules as Revoke-CPrivateKeyPermission, ' +
               'Revoke-CNtfsPermission, and Revoke-CRegistryPermission, respectively. The ' +
               "$($MyInvocation.MyCommand.Name) function will be removed from the next major version of Carbon. " +
               'Please switch to the new functions and modules, available on the PowerShell Gallery.'
        Write-CWarningOnce -Message $msg
    }

    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-CPathProvider -Path $Path -NoWarn | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
        if( -not (Test-CCryptoKeyAvailable) )
        {
            $providerName = 'FileSystem'
        }
    }

    $rulesToRemove = Get-CPermission -Path $Path -Identity $Identity -NoWarn
    if (-not $rulesToRemove)
    {
        return
    }

    $Identity = Resolve-CIdentityName -Name $Identity -NoWarn

    foreach ($item in (Get-Item $Path -Force))
    {
        if( $item.PSProvider.Name -ne 'Certificate' )
        {
            if (-not $Description)
            {
                $Description = $item.ToString()
            }

            # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
            # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security
            # descriptor. See
            # http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
            $currentAcl = $item.GetAccessControl('Access')

            foreach ($ruleToRemove in $rulesToRemove)
            {
                $rmIdentity = $ruleToRemove.IdentityReference
                $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                $rmRights = $ruleToRemove."${providerName}Rights"
                Write-Information "${Description}  ${rmIdentity}  - ${rmType} ${rmRights}"
                [void]$currentAcl.RemoveAccessRule($ruleToRemove)
            }
            if( $PSCmdlet.ShouldProcess( $Path, ('revoke {0}''s permissions' -f $Identity)) )
            {
                Set-Acl -Path $Path -AclObject $currentAcl
            }
            continue
        }

        $certMsg = """$($item.Subject)"" (thumbprint: $($item.Thumbprint); path: " +
                   "cert:\$($item.PSPath | Split-Path -NoQualifier)) "
        if (-not $item.HasPrivateKey)
        {
            Write-Verbose -Message "Skipping certificate ${certMsg}because it doesn't have a private key."
            continue
        }

        if (-not $Description)
        {
            $Description = "cert:\$($item.PSPath | Split-Path -NoQualifier) ($($item.Thumbprint))"
        }

        $privateKey = $item.PrivateKey
        if ($privateKey -and ($item.PrivateKey | Get-Member 'CspKeyContainerInfo'))
        {
            [Security.Cryptography.X509Certificates.X509Certificate2]$certificate = $item

            [Security.AccessControl.CryptoKeySecurity]$keySecurity =
                $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity

            foreach ($ruleToRemove in $rulesToRemove)
            {
                $rmIdentity = $ruleToRemove.IdentityReference
                $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                $rmRights = $ruleToRemove."${providerName}Rights"
                Write-Information "${Description}  ${rmIdentity}  - ${rmType} ${rmRights}"
                [void] $keySecurity.RemoveAccessRule($ruleToRemove)
            }

            $action = "revoke ${Identity}'s permissions"
            Set-CryptoKeySecurity -Certificate $certificate -CryptoKeySecurity $keySecurity -Action $action
            return
        }

        $privateKeyFilesPaths = $item | Resolve-CPrivateKeyPath
        if (-not $privateKeyFilesPaths)
        {
            # Resolve-CPrivateKeyPath writes an appropriately detailed error message.
            continue
        }

        $revokePermissionParams = New-Object -TypeName 'Collections.Generic.Dictionary[[string], [object]]' `
                                             -ArgumentList $PSBoundParameters
        [void]$revokePermissionParams.Remove('Path')
        foreach( $privateKeyFilePath in $privateKeyFilesPaths )
        {
            Revoke-CPermission -Path $privateKeyFilePath @revokePermissionParams -Description $Description -NoWarn
        }
    }
}



function Revoke-CPrivilege
{
    <#
    .SYNOPSIS
    Revokes an identity's privileges to perform system operations and certain types of logons.

    .DESCRIPTION
    Valid privileges are documented on Microsoft's website: [Privilege Constants](http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx) and [Account Right Constants](http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx). Known values as of August 2014 are:

     * SeAssignPrimaryTokenPrivilege
     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeBatchLogonRight
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
     * SeCreateSymbolicLinkPrivilege
     * SeCreateTokenPrivilege
     * SeDebugPrivilege
     * SeDenyBatchLogonRight
     * SeDenyInteractiveLogonRight
     * SeDenyNetworkLogonRight
     * SeDenyRemoteInteractiveLogonRight
     * SeDenyServiceLogonRight
     * SeEnableDelegationPrivilege
     * SeImpersonatePrivilege
     * SeIncreaseBasePriorityPrivilege
     * SeIncreaseQuotaPrivilege
     * SeIncreaseWorkingSetPrivilege
     * SeInteractiveLogonRight
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeNetworkLogonRight
     * SeProfileSingleProcessPrivilege
     * SeRelabelPrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeRestorePrivilege
     * SeSecurityPrivilege
     * SeServiceLogonRight
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTimeZonePrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    .LINK
    Get-CPrivilege

    .LINK
    Grant-CPrivilege

    .LINK
    Test-CPrivilege

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb530716.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb545671.aspx

    .EXAMPLE
    Revoke-CPrivilege -Identity Batcomputer -Privilege SeServiceLogonRight

    Revokes the Batcomputer account's ability to logon as a service.  Don't restart that thing!
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity to grant a privilege.
        $Identity,

        [Parameter(Mandatory=$true)]
        [string[]]
        # The privileges to revoke.
        $Privilege,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Security'
    }

    $account = Resolve-CIdentity -Name $Identity -NoWarn
    if( -not $account )
    {
        return
    }

    # Convert the privileges from the user into their canonical names.
    $cPrivileges = Get-CPrivilege -Identity $account.FullName -NoWarn |
                        Where-Object { $Privilege -contains $_ }
    if( -not $cPrivileges )
    {
        return
    }

    try
    {
        [Carbon.Security.Privilege]::RevokePrivileges($account.FullName,$cPrivileges)
    }
    catch
    {
        Write-Error -Message ('Failed to revoke {0}''s {1} privilege(s).' -f $account.FullName,($cPrivileges -join ', '))

        $ex = $_.Exception
        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}

function Revoke-CServicePermission
{
    <#
    .SYNOPSIS
    Removes all permissions an identity has to manage a service.

    .DESCRIPTION
    No permissions are left behind.  This is an all or nothing operation, baby!

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .EXAMPLE
    Revoke-CServicePermission -Name 'Hyperdrive` -Identity 'CLOUDCITY\LCalrissian'

    Removes all of Lando's permissions to control the `Hyperdrive` service.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose permissions are being revoked.
        $Identity,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $account = Resolve-CIdentity -Name $Identity -NoWarn
    if( -not $account )
    {
        return
    }

    if( -not (Assert-CService -Name $Name -NoWarn) )
    {
        return
    }

    if( (Get-CServicePermission -Name $Name -Identity $account.FullName -NoWarn) )
    {
        Write-Verbose ("Revoking {0}'s {1} service permissions." -f $account.FullName,$Name)

        $dacl = Get-CServiceAcl -Name $Name -NoWarn
        $dacl.Purge( $account.Sid )

        Set-CServiceAcl -Name $Name -Dacl $dacl -NoWarn
    }
}

function Set-CEnvironmentVariable
{
    <#
    .SYNOPSIS
    Creates or sets an environment variable.

    .DESCRIPTION
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to create or set an environment variable in the Process, User, or Machine scopes.

    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running processes that use this environment variable should be restarted.

    Beginning with Carbon 2.3.0, you can set an environment variable for a specific user by specifying the `-ForUser` switch and passing the user's credentials with the `-Credential` parameter. This will run a PowerShell process as that user in order to set the environment variable.

    Normally, you have to restart your PowerShell session/process to see the variable in the `env:` drive. Use the `-Force` switch to also add the variable to the `env:` drive. This functionality was added in Carbon 2.3.0.

    .LINK
    Remove-CEnvironmentVariable

    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Set-CEnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForProcess

    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the process scope, i.e. the variable is only accessible in the current process.

    .EXAMPLE
    Set-CEnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForComputer

    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the machine scope, i.e. the variable is accessible in all newly launched processes.

    .EXAMPLE
    Set-CEnvironmentVariable -Name 'SomeUsersEnvironmentVariable' -Value 'SomeValue' -ForUser -Credential $userCreds

    Demonstrates that you can set a user-level environment variable for another user by passing its credentials to the `Credential` parameter. Runs a separate PowerShell process as that user to set the environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The name of environment variable to add/set.
        [string]$Name,

        [Parameter(Mandatory=$true)]
        # The environment variable's value.
        [string]$Value,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Sets the environment variable for the current computer.
        [Switch]$ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Sets the environment variable for the current user.
        [Switch]$ForUser,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Sets the environment variable for the current process.
        [Switch]$ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Set the variable in the current PowerShell session's `env:` drive, too. Normally, you have to restart your session to see the variable in the `env:` drive.
        #
        # This parameter was added in Carbon 2.3.0.
        [Switch]$Force,

        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Set an environment variable for a specific user.
        [pscredential]$Credential,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Environment'
    }

    if( $PSCmdlet.ParameterSetName -eq 'ForSpecificUser' )
    {
        $parameters = $PSBoundParameters
        $parameters.Remove('Credential')
        $job = Start-Job -ScriptBlock {
            Import-Module -Name (Join-Path -path $using:carbonRoot -ChildPath 'Carbon.psd1' -Resolve)
            $VerbosePreference = $using:VerbosePreference
            $ErrorActionPreference = $using:ErrorActionPreference
            $DebugPreference = $using:DebugPreference
            $WhatIfPreference = $using:WhatIfPreference
            Set-CEnvironmentVariable @using:parameters
        } -Credential $Credential
        $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force -ErrorAction Ignore
        return
    }

    if( -not $ForProcess -and -not $ForUser -and -not $ForComputer )
    {
        Write-Error -Message ('Environment variable target not specified. You must supply one of the ForComputer, ForUser, or ForProcess switches.')
        return
    }

    Invoke-Command -ScriptBlock {
            if( $ForComputer )
            {
                [EnvironmentVariableTarget]::Machine
            }

            if( $ForUser )
            {
                [EnvironmentVariableTarget]::User
            }

            if( $Force -or $ForProcess )
            {
                [EnvironmentVariableTarget]::Process
            }
        } |
        Where-Object { $PSCmdlet.ShouldProcess( "$_-level environment variable '$Name'", "set") } |
        ForEach-Object { [Environment]::SetEnvironmentVariable( $Name, $Value, $_ ) }
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



function Set-CryptoKeySecurity
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Security.Cryptography.X509Certificates.X509Certificate2] $Certificate,

        [Parameter(Mandatory)]
        [Security.AccessControl.CryptoKeySecurity] $CryptoKeySecurity,

        [Parameter(Mandatory)]
        [String] $Action
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $keyContainerInfo = $Certificate.PrivateKey.CspKeyContainerInfo
    $cspParams = New-Object 'Security.Cryptography.CspParameters' ($keyContainerInfo.ProviderType, $keyContainerInfo.ProviderName, $keyContainerInfo.KeyContainerName)
    $cspParams.Flags = [Security.Cryptography.CspProviderFlags]::UseExistingKey
    $cspParams.KeyNumber = $keyContainerInfo.KeyNumber
    if( (Split-Path -NoQualifier -Path $Certificate.PSPath) -like 'LocalMachine\*' )
    {
        $cspParams.Flags = $cspParams.Flags -bor [Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
    }
    $cspParams.CryptoKeySecurity = $CryptoKeySecurity

    try
    {
        # persist the rule change
        if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $Certificate.Subject,$Certificate.Thumbprint), $Action ) )
        {
            $null = New-Object 'Security.Cryptography.RSACryptoServiceProvider' ($cspParams)
        }
    }
    catch
    {
        $actualException = $_.Exception
        while( $actualException.InnerException )
        {
            $actualException = $actualException.InnerException
        }
        Write-Error ('Failed to {0} to ''{1}'' ({2}) certificate''s private key: {3}: {4}' -f $Action,$Certificate.Subject,$Certificate.Thumbprint,$actualException.GetType().FullName,$actualException.Message)
    }
}

function Set-CServiceAcl
{
    <#
    .SYNOPSIS
    Sets a service's discretionary access control list (i.e. DACL).

    .DESCRIPTION
    The existing DACL is replaced with the new DACL.  No previous permissions are preserved.  That's your job.  You're warned!

    You probably want `Grant-CServicePermission` or `Revoke-CServicePermission` instead.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .LINK
    Revoke-CServicePermission

    .EXAMPLE
    Set-ServiceDacl -Name 'Hyperdrive' -Dacl $dacl

    Replaces the DACL on the `Hyperdrive` service.  Yikes!  Sounds like something the Empire would do, though.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service whose DACL to replace.
        $Name,

        [Parameter(Mandatory=$true)]
        [Security.AccessControl.DiscretionaryAcl]
        # The service's new DACL.
        $Dacl,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $rawSD = Get-CServiceSecurityDescriptor -Name $Name -NoWarn
    $daclBytes = New-Object byte[] $Dacl.BinaryLength
    $Dacl.GetBinaryForm($daclBytes, 0);
    $rawSD.DiscretionaryAcl = New-Object Security.AccessControl.RawAcl $daclBytes,0
    $sdBytes = New-Object byte[] $rawSD.BinaryLength
    $rawSD.GetBinaryForm($sdBytes, 0);

    if( $pscmdlet.ShouldProcess( ("{0} service DACL" -f $Name), "set" ) )
    {
        [Carbon.Service.ServiceSecurity]::SetServiceSecurityDescriptor( $Name, $sdBytes )
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



function Start-CDscPullConfiguration
{
    <#
    .SYNOPSIS
    Performs a configuration check on a computer that is using DSC's Pull refresh mode.

    .DESCRIPTION
    The most frequently a computer's LCM will download new configuration is every 15 minutes; the most frequently it will apply it is every 30 minutes. This function contacts a computer's LCM and tells it to apply and download its configuration immediately.

    If a computer's LCM isn't configured to pull its configuration, an error is written, and nothing happens.

    If a configuration check fails, the errors are retrieved from the computer's event log and written out as errors. The `Remote Event Log Management` firewall rules must be enabled on the computer for this to work. If they aren't, you'll see an error explaining this. The `Get-CDscError` help topic shows how to enable these firewall rules.

    Sometimes, the LCM does a really crappy job of updating to the latest version of a module. `Start-CDscPullConfiguration` will delete modules on the target computers. Specify the names of the modules to delete with the `ModuleName` parameter. Make sure you only delete modules that will get installed by the LCM. Only modules installed in the `$env:ProgramFiles\WindowsPowerShell\Modules` directory are removed.

    `Start-CDscPullConfiguration` is new in Carbon 2.0.

    .LINK
    Get-CDscError

    .LINK
    Initialize-CLcm

    .LINK
    Get-CDscWinEvent

    .EXAMPLE
    Start-CDscPullConfiguration -ComputerName '10.1.2.3','10.4.5.6'

    Demonstrates how to immedately download and apply a computer from its pull server.

    .EXAMPLE
    Start-CDscPullConfiguration -ComputerName '10.1.2.3' -Credential (Get-Credential domain\username)

    Demonstrates how to use custom credentials to contact the remote server.

    .EXAMPLE
    Start-CDscPullConfiguration -CimSession $session

    Demonstrates how to use one or more CIM sessions to invoke a configuration check.

    .EXAMPLE
    Start-CDscPullConfiguration -ComputerName 'example.com' -ModuleName 'Carbon'

    Demonstrates how to delete modules on the target computers, because sometimes the LCM does a really crappy job of it.
    #>
    [CmdletBinding(DefaultParameterSetName='WithCredentials')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='WithCredentials')]
        [string[]]
        # The credential to use when connecting to the target computer.
        $ComputerName,

        [Parameter(ParameterSetName='WithCredentials')]
        [PSCredential]
        # The credentials to use when connecting to the computers.
        $Credential,

        [Parameter(ParameterSetName='WithCimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]
        $CimSession,

        [string[]]
        # Any modules that should be removed from the target computer's PSModulePath (since the LCM does a *really* crappy job of removing them).
        $ModuleName,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    $credentialParam = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'WithCredentials' )
    {
        if( $Credential )
        {
            $credentialParam.Credential = $Credential
        }

        $CimSession = New-CimSession -ComputerName $ComputerName @credentialParam
        if( -not $CimSession )
        {
            return
        }
    }

    $CimSession = Get-DscLocalConfigurationManager -CimSession $CimSession |
                    ForEach-Object {
                        if( $_.RefreshMode -ne 'Pull' )
                        {
                            Write-Error ('The Local Configuration Manager on ''{0}'' is not in Pull mode (current RefreshMode is ''{1}'').' -f $_.PSComputerName,$_.RefreshMode)
                            return
                        }

                        foreach( $session in $CimSession )
                        {
                            if( $session.ComputerName -eq $_.PSComputerName )
                            {
                                return $session
                            }
                        }
                    }

    if( -not $CimSession )
    {
        return
    }

    # Get rid of any _tmp directories you might find out there.
    Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
        $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
        Get-ChildItem -Path $modulesRoot -Filter '*_tmp' -Directory |
            Remove-Item -Recurse
    }

    if( $ModuleName )
    {
        # Now, get rid of any modules we know will need to get updated
        Invoke-Command -ComputerName $CimSession.ComputerName @credentialParam -ScriptBlock {
            param(
                [string[]]
                $ModuleName
            )

            $dscProcessID = Get-CCimInstance -Class 'msft_providers' |
                                Where-Object {$_.provider -like 'dsccore'} |
                                Select-Object -ExpandProperty HostProcessIdentifier
            Stop-Process -Id $dscProcessID -Force

            $modulesRoot = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
            Get-ChildItem -Path $modulesRoot -Directory |
                Where-Object { $ModuleName -contains $_.Name } |
                Remove-Item -Recurse

        } -ArgumentList (,$ModuleName)
    }

    # Getting the date/time on the remote computers so we can get errors later.
    $win32OS = Get-CimInstance -CimSession $CimSession -ClassName 'Win32_OperatingSystem'

    $results = Invoke-CimMethod -CimSession $CimSession `
                                -Namespace 'root/microsoft/windows/desiredstateconfiguration' `
                                -Class 'MSFT_DscLocalConfigurationManager' `
                                -MethodName 'PerformRequiredConfigurationChecks' `
                                -Arguments @{ 'Flags' = [uint32]1 }

    $successfulComputers = $results | Where-Object { $_ -and $_.ReturnValue -eq 0 } | Select-Object -ExpandProperty 'PSComputerName'

    $CimSession |
        Where-Object { $successfulComputers -notcontains $_.ComputerName } |
        ForEach-Object {
            $session = $_
            $startedAt= $win32OS | Where-Object { $_.PSComputerName -eq $session.ComputerName } | Select-Object -ExpandProperty 'LocalDateTime'
            Get-CDscError -ComputerName $session.ComputerName -StartTime $startedAt -Wait -NoWarn
        } |
        Write-CDscError -NoWarn
}

function Test-CAdminPrivilege
{
    <#
    .SYNOPSIS
    Checks if the current user is an administrator or has administrative privileges.

    .DESCRIPTION
    Many tools, cmdlets, and APIs require administative privileges.  Use this function to check.  Returns `True` if the current user has administrative privileges, or `False` if he doesn't.  Or she.  Or it.

    This function handles UAC and computers where UAC is disabled.

    .EXAMPLE
    Test-CAdminPrivilege

    Returns `True` if the current user has administrative privileges, or `False` if the user doesn't.
    #>
    [CmdletBinding()]
    param(
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Test-CRunAsElevated' `
                                    -NoWarn:$NoWarn

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Debug -Message "Checking if current user '$($identity.Name)' has administrative privileges."

    $hasElevatedPermissions = $false
    foreach ( $group in $identity.Groups )
    {
        if ( $group.IsValidTargetType([Security.Principal.SecurityIdentifier]) )
        {
            $groupSid = $group.Translate([Security.Principal.SecurityIdentifier])
            if ( $groupSid.IsWellKnown("AccountAdministratorSid") -or $groupSid.IsWellKnown("BuiltinAdministratorsSid"))
            {
                return $true
            }
        }
    }

    return $false
}

Set-Alias -Name 'Test-AdminPrivileges' -Value 'Test-CAdminPrivilege'

function Test-CGroup
{
    <#
    .SYNOPSIS
    Checks if a *local* group exists.

    .DESCRIPTION
    Uses .NET's AccountManagement API to check if a *local* group exists.  Returns `True` if the *local* account exists, or `False` if it doesn't.

    .OUTPUTS
    System.Boolean

    .LINK
    Get-CGroup

    .LINK
    Install-CGroup

    .LINK
    Uninstall-CGroup

    .EXAMPLE
    Test-CGroup -Name RebelAlliance

    Checks if the `RebelAlliance` *local* group exists.  Returns `True` if it does, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the *local* group to check.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Test-CLocalGroup' `
                                    -NoWarn:$NoWarn

    $group = Get-CGroup -Name $Name -NoWarn -ErrorAction Ignore
    if( $group )
    {
        $group.Dispose()
        return $true
    }
    else
    {
        return $false
    }
}

function Test-CGroupMember
{
    <#
    .SYNOPSIS
    Tests if a user or group is a member of a *local* group.

    .DESCRIPTION
    The `Test-CGroupMember` function tests if a user or group is a member of a *local* group using [.NET's DirectoryServices.AccountManagement APIs](https://msdn.microsoft.com/en-us/library/system.directoryservices.accountmanagement.aspx). If the group or member you want to check don't exist, you'll get errors and `$null` will be returned. If `Member` is in the group, `$true` is returned. If `Member` is not in the group, `$false` is returned.

    The user running this function must have permission to access whatever directory the `Member` is in and whatever directory current members of the group are in.

    This function was added in Carbon 2.1.0.

    .LINK
    Add-CGroupMember

    .LINK
    Install-CGroup

    .LINK
    Remove-CGroupMember

    .LINK
    Test-CGroup

    .LINK
    Uninstall-CGroup

    .EXAMPLE
    Test-CGroupMember -GroupName 'SithLords' -Member 'REBELS\LSkywalker'

    Demonstrates how to test if a user is a member of a group. In this case, it tests if `REBELS\LSkywalker` is in the local `SithLords`, *which obviously he isn't*, so `$false` is returned.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group whose membership is being tested.
        $GroupName,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the member to check.
        $Member,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Test-CLocalGroupMember' `
                                    -NoWarn:$NoWarn

    if( -not (Test-CGroup -Name $GroupName -NoWarn) )
    {
        Write-Error -Message ('Group ''{0}'' not found.' -f $GroupName)
        return
    }

    $group = Get-CGroup -Name $GroupName -NoWarn
    if( -not $group )
    {
        return
    }

    $principal = Resolve-CIdentity -Name $Member -NoWarn
    if( -not $principal )
    {
        return
    }

    try
    {
        return $principal.IsMemberOfLocalGroup($group.Name)
    }
    catch
    {
        Write-Error -Message ('Checking if "{0}" is a member of local group "{1}" failed: {2}' -f $principal.FullName,$group.Name,$_)
    }
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




function Test-CDscTargetResource
{
    <#
    .SYNOPSIS
    Tests that all the properties on a resource and object are the same.

    .DESCRIPTION
    DSC expects a resource's `Test-TargetResource` function to return `$false` if an object needs to be updated. Usually, you compare the current state of a resource with the desired state, and return `$false` if anything doesn't match.

    This function takes in a hashtable of the current resource's state (what's returned by `Get-TargetResource`) and compares it to the desired state (the values passed to `Test-TargetResource`). If any property in the target resource is different than the desired resource, a list of stale resources is written to the verbose stream and `$false` is returned.

    Here's a quick example:

        return Test-TargetResource -TargetResource (Get-TargetResource -Name 'fubar') -DesiredResource $PSBoundParameters -Target ('my resource ''fubar''')

    If you want to exclude properties from the evaluation, just remove them from the hashtable returned by `Get-TargetResource`:

        $resource = Get-TargetResource -Name 'fubar'
        $resource.Remove( 'PropertyThatDoesNotMatter' )
        return Test-TargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('my resource ''fubar''')

    `Test-CDscTargetResource` is new in Carbon 2.0.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-TargetResource -TargetResource (Get-TargetResource -Name 'fubar') -DesiredResource $PSBoundParameters -Target ('my resource ''fubar''')

    Demonstrates how to test that all the properties on a DSC resource are the same was what's desired.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        # The current state of the resource.
        $TargetResource,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The desired state of the resource. Properties not in this hashtable are skipped. Usually you'll pass `PSBoundParameters` from your `Test-TargetResource` function.
        $DesiredResource,

        [Parameter(Mandatory=$true)]
        [string]
        # The a description of the target object being tested. Output in verbose messages.
        $Target,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
    }

    $notEqualProperties = $TargetResource.Keys |
                            Where-Object { $_ -ne 'Ensure' } |
                            Where-Object { $DesiredResource.ContainsKey( $_ ) } |
                            Where-Object {
                                $desiredObj = $DesiredResource[$_]
                                $targetObj = $TargetResource[$_]

                                if( $desiredobj -eq $null -or $targetObj -eq $null )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( -not $desiredObj.GetType().IsArray -or -not $targetObj.GetType().IsArray )
                                {
                                    return ($desiredObj -ne $targetObj)
                                }

                                if( $desiredObj.Length -ne $targetObj.Length )
                                {
                                    return $true
                                }

                                $desiredObj | Where-Object { $targetObj -notcontains $_ }
                            }

    if( $notEqualProperties )
    {
        Write-Verbose ('{0} has stale properties: ''{1}''' -f $Target,($notEqualProperties -join ''','''))
        return $false
    }

    return $true
}

function Test-CCryptoKeyAvailable
{
    return $null -ne [Type]::GetType('System.Security.AccessControl.CryptoKeyRights')
}


function Test-CFileShare
{
    <#
    .SYNOPSIS
    Tests if a file/SMB share exists on the local computer.

    .DESCRIPTION
    The `Test-CFileShare` function uses WMI to check if a file share exists on the local computer. If the share exists, `Test-CFileShare` returns `$true`. Otherwise, it returns `$false`.

    `Test-CFileShare` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Test-CFileShare -Name 'CarbonShare'

    Demonstrates how to test of a file share exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific share to check.
        $Name,

        # Hide the warning that this command is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.SmbShare' `
                                    -NewCommandName 'Test-CSmbShare' `
                                    -NoWarn:$NoWarn

    $share = Get-CFileShare -Name ('{0}*' -f $Name) -NoWarn |
                Where-Object { $_.Name -eq $Name }

    return ($share -ne $null)
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

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Accounts'
    }

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



function Test-CPermission
{
    <#
    .SYNOPSIS
    Tests if permissions are set on a file, directory, registry key, or certificate's private key/key container.

    .DESCRIPTION
    Sometimes, you don't want to use `Grant-CPermission` on a big tree.  In these situations, use `Test-CPermission` to see if permissions are set on a given path.

    This function supports file system, registry, and certificate private key/key container permissions.  You can also test the inheritance and propogation flags on containers, in addition to the permissions, with the `ApplyTo` parameter.  See [Grant-CPermission](Grant-CPermission.html) documentation for an explanation of the `ApplyTo` parameter.

    Inherited permissions on *not* checked by default.  To check inherited permission, use the `-Inherited` switch.

    By default, the permission check is not exact, i.e. the user may have additional permissions to what you're checking.  If you want to make sure the user has *exactly* the permission you want, use the `-Exact` switch.  Please note that by default, NTFS will automatically add/grant `Synchronize` permission on an item, which is handled by this function.

    When checking for permissions on certificate private keys/key containers, if a certificate doesn't have a private key, `$true` is returned.

    .OUTPUTS
    System.Boolean.

    .LINK
    ConvertTo-CContainerInheritanceFlags

    .LINK
    Disable-CAclInheritance

    .LINK
    Enable-CAclInheritance

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\JLPicard' -Permission 'FullControl' -Path 'C:\Enterprise\Bridge'

    Demonstrates how to check that Jean-Luc Picard has `FullControl` permission on the `C:\Enterprise\Bridge`.

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\GLaForge' -Permission 'WriteKey' -Path 'HKLM:\Software\Enterprise\Engineering'

    Demonstrates how to check that Geordi LaForge can write registry keys at `HKLM:\Software\Enterprise\Engineering`.

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\Worf' -Permission 'Write' -ApplyTo 'Container' -Path 'C:\Enterprise\Brig'

    Demonstrates how to test for inheritance/propogation flags, in addition to permissions.

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\Data' -Permission 'GenericWrite' -Path 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678'

    Demonstrates how to test for permissions on a certificate's private key/key container. If the certificate doesn't have a private key, returns `$true`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be checked.  Can be a file system or registry path.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The user or group whose permissions to check.
        $Identity,

        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission to test for: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,

        [Carbon.Security.ContainerInheritanceFlags]
        # The container and inheritance flags to check. Ignored if `Path` is a file. These are ignored if not supplied. See `Grant-CPermission` for detailed explanation of this parameter. This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo,

        [Switch]
        # Include inherited permissions in the check.
        $Inherited,

        [Switch]
        # Check for the exact permissions, inheritance flags, and propagation flags, i.e. make sure the identity has *only* the permissions you specify.
        $Exact,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        $msg = "Carbon's $($MyInvocation.MyCommand.Name) function moved to the Carbon.Cryptography, " +
               'Carbon.FileSystem, and Carbon.Registry modules as Test-CPrivateKeyPermission, Test-CNtfsPermission, ' +
               "and Test-CRegistryPermission, respectively. The $($MyInvocation.MyCommand.Name) function will be " +
               'removed from the next major version of Carbon. Please switch to the new functions and modules, ' +
               'available on the PowerShell Gallery.'
        Write-CWarningOnce -Message $msg
    }

    $originalPath = $Path
    $Path = Resolve-Path -Path $Path -ErrorAction 'SilentlyContinue'
    if( -not $Path -or -not (Test-Path -Path $Path) )
    {
        if( -not $Path )
        {
            $Path = $originalPath
        }
        Write-Error ('Unable to test {0}''s {1} permissions: path ''{2}'' not found.' -f $Identity,($Permission -join ','),$Path)
        return
    }

    $providerName = Get-CPathProvider -Path $Path -NoWarn | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
        # CryptoKey does not exist in .NET standard/core so we will have to use FileSystem instead
        if( -not (Test-CCryptoKeyAvailable) )
        {
            $providerName = 'FileSystem'
        }
    }

    if( ($providerName -eq 'FileSystem' -or $providerName -eq 'CryptoKey') -and $Exact )
    {
        # Synchronize is always on and can't be turned off.
        $Permission += 'Synchronize'
    }
    $rights = $Permission | ConvertTo-ProviderAccessControlRights -ProviderName $providerName
    if( -not $rights )
    {
        Write-Error ('Unable to test {0}''s {1} permissions on {2}: received an unknown permission.' -f $Identity,$Permission,$Path)
        return
    }

    $account = Resolve-CIdentity -Name $Identity -NoWarn
    if( -not $account)
    {
        return
    }

    $rightsPropertyName = '{0}Rights' -f $providerName
    $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    $testApplyTo = $false
    if( $PSBoundParameters.ContainsKey('ApplyTo') )
    {
        if( (Test-Path -Path $Path -PathType Leaf ) )
        {
            Write-Warning "Can't test inheritance/propagation rules on a leaf. Please omit `ApplyTo` parameter when `Path` is a leaf."
        }
        else
        {
            $testApplyTo = $true
            $inheritanceFlags = ConvertTo-CInheritanceFlag -ContainerInheritanceFlag $ApplyTo -NoWarn
            $propagationFlags = ConvertTo-CPropagationFlag -ContainerInheritanceFlag $ApplyTo -NoWarn
        }
    }

    if( $providerName -eq 'CryptoKey' )
    {
        # If the certificate doesn't have a private key, return $true.
        if( (Get-Item -Path $Path | Where-Object { -not $_.HasPrivateKey } ) )
        {
            return $true
        }
    }

    $acl = Get-CPermission -Path $Path -Identity $Identity -Inherited:$Inherited -NoWarn |
                Where-Object { $_.AccessControlType -eq 'Allow' } |
                Where-Object { $_.IsInherited -eq $Inherited } |
                Where-Object {
                    if( $Exact )
                    {
                        return ($_.$rightsPropertyName -eq $rights)
                    }
                    else
                    {
                        return ($_.$rightsPropertyName -band $rights) -eq $rights
                    }
                } |
                Where-Object {
                    if( -not $testApplyTo )
                    {
                        return $true
                    }

                    if( $Exact )
                    {
                        return ($_.InheritanceFlags -eq $inheritanceFlags) -and ($_.PropagationFlags -eq $propagationFlags)
                    }
                    else
                    {
                        return (($_.InheritanceFlags -band $inheritanceFlags) -eq $inheritanceFlags) -and `
                               (($_.PropagationFlags -and $propagationFlags) -eq $propagationFlags)
                    }
                }
    if( $acl )
    {
        return $true
    }
    else
    {
        return $false
    }
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



function Test-CPrivilege
{
    <#
    .SYNOPSIS
    Tests if an identity has a given privilege.

    .DESCRIPTION
    Returns `true` if an identity has a privilege.  `False` otherwise.

    .LINK
    Get-CPrivilege

    .LINK
    Grant-CPrivilege

    .LINK
    Revoke-CPrivilege

    .EXAMPLE
    Test-CPrivilege -Identity Forrester -Privilege SeServiceLogonRight

    Tests if `Forrester` has the `SeServiceLogonRight` privilege.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose privileges to check.
        $Identity,

        [Parameter(Mandatory=$true)]
        [string]
        # The privilege to check.
        $Privilege,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Security'
    }

    $matchingPrivilege = Get-CPrivilege -Identity $Identity -NoWarn |
                            Where-Object { $_ -eq $Privilege }
    return ($matchingPrivilege -ne $null)
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



function Test-CScheduledTask
{
    <#
    .SYNOPSIS
    Tests if a scheduled task exists on the current computer.

    .DESCRIPTION
    The `Test-CScheduledTask` function uses `schtasks.exe` to tests if a task with a given name exists on the current computer. If it does, `$true` is returned. Otherwise, `$false` is returned. This name must be the *full task name*, i.e. the task's path/location and its name.

    .LINK
    Get-CScheduledTask

    .EXAMPLE
    Test-CScheduledTask -Name 'AutoUpdateMyApp'

    Demonstrates how to test if a scheduled tasks exists.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to check. This must be the *full task name*, i.e. the task's path/location and its name.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.ScheduledTasks'
    }

    $Name = Join-Path -Path '\' -ChildPath $Name

    $task = Get-CScheduledTask -Name $Name -AsComObject -NoWarn -ErrorAction Ignore
    if( $task )
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Test-CService
{
    <#
    .SYNOPSIS
    Tests if a service exists, without writing anything out to the error stream.

    .DESCRIPTION
    `Get-Service` writes an error when a service doesn't exist.  This function tests if a service exists without writing anyting to the output stream.

    .OUTPUTS
    System.Boolean.

    .LINK
    Install-CService

    .LINK
    Uninstall-CService

    .EXAMPLE
    Test-CService -Name 'Drive'

    Returns `true` if the `Drive` service exists.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service to test.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $service = Get-Service -Name $Name -ErrorAction Ignore
    if( $service )
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


function Uninstall-CDirectory
{
    <#
    .SYNOPSIS
    Removes a directory, if it exists.

    .DESCRIPTION
    The `Uninstall-CDirectory` function removes a directory. If the directory doesn't exist, it does nothing. If the directory has any files or sub-directories, you will be prompted to confirm the deletion of the directory and all its contents. To avoid the prompt, use the `-Recurse` switch.

    `Uninstall-CDirectory` was added in Carbon 2.1.0.

    .EXAMPLE
    Uninstall-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to remove/delete a directory. In this case, the directory `C:\Projects\Carbon` will be deleted, if it exists.

    .EXAMPLE
    Uninstall-CDirectory -Path 'C:\Projects\Carbon' -Recurse

    Demonstrates how to remove/delete a directory that has items in it. In this case, the directory `C:\Projects\Carbon` *and all of its files and sub-directories* will be deleted, if the directory exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the directory to create.
        $Path,

        [Switch]
        # Delete the directory *and* everything under it.
        $Recurse,

        # Don't show the warning that this command is obsolete.
        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.FileSystem' `
                                    -NoWarn:$NoWarn

    if( (Test-Path -Path $Path -PathType Container) )
    {
        Remove-Item -Path $Path -Recurse:$Recurse
    }
}


function Uninstall-CFileShare
{
    <#
    .SYNOPSIS
    Uninstalls/removes a file share from the local computer.

    .DESCRIPTION
    The `Uninstall-CFileShare` function uses WMI to uninstall/remove a file share from the local computer, if it exists.
    Pass the name of the share to delete to the `Name` parameter (or pipe the name or share objects to the function). If
    the file share exists, it is deleted. If it doesn't exist, nothing hapens.

    `Uninstall-CFileShare` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Test-CFileShare

    .EXAMPLE
    Uninstall-CFileShare -Name 'CarbonShare'

    Demonstrates how to uninstall/remove a share from the local computer. If the share does not exist,
    `Uninstall-CFileShare` silently does nothing (i.e. it doesn't write an error).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of a specific share to uninstall/delete. Wildcards accepted. If the string contains WMI sensitive
        # characters, you'll need to escape them.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Name,

        # Hide the warning that this function is obsolete.
        [switch] $NoWarn
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.SmbShare' `
                                        -NewCommandName 'Uninstall-CSmbShare' `
                                        -NoWarn:$NoWarn

        if( -not (Test-CFileShare -Name $Name -NoWarn) )
        {
            return
        }

        foreach ($share in (Get-CFileShare -Name $Name -NoWarn))
        {
            $deletePhysicalPath = $false
            if (-not (Test-Path -Path $share.Path -PathType Container))
            {
                Install-CDirectory -Path $share.Path -InformationAction SilentlyContinue -NoWarn
                $deletePhysicalPath = $true
            }

            if( $PSCmdlet.ShouldProcess( "$($share.Name) ($($share.Path))", 'delete SMB file share' ) )
            {
                Write-Information "Deleting SMB file share ""$($share.Name)"" ($($share.Path))."
                $share | Invoke-CCimMethod -Name 'Delete'
            }

            if ($deletePhysicalPath -and (Test-Path -Path $share.Path))
            {
                Uninstall-CDirectory -Path $share.Path -Recurse -InformationAction SilentlyContinue -NoWarn
            }
        }
    }
}

function Uninstall-CGroup
{
    <#
    .SYNOPSIS
    Removes a *local* group.

    .DESCRIPTION
    The `Uninstall-CGroup` function removes a *local* group using .NET's [DirectoryServices.AccountManagement API](https://msdn.microsoft.com/en-us/library/system.directoryservices.accountmanagement.aspx). If the group doesn't exist, returns without doing any work or writing any errors.

    This function was added in Carbon 2.1.0.

    .LINK
    Add-CGroupMember

    .LINK
    Install-CGroup

    .LINK
    Remove-CGroupMember

    .LINK
    Test-CGroup

    .LINK
    Test-CGroupMember

    .INPUTS
    System.String

    .EXAMPLE
    Uninstall-WhsGroup -Name 'TestGroup1'

    Demonstrates how to uninstall a group. In this case, the `TestGroup1` group is removed.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        # The name of the group to remove/uninstall.
        $Name,

        [switch] $NoWarn
    )

	Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                    -ModuleName 'Carbon.Accounts' `
                                    -NewCommandName 'Uninstall-CLocalGroup' `
                                    -NoWarn:$NoWarn

    if( -not (Test-CGroup -Name $Name -NoWarn) )
    {
        return
    }

    $group = Get-CGroup -Name $Name -NoWarn
    if( -not $group )
    {
        return
    }

    if( $PSCmdlet.ShouldProcess(('local group {0}' -f $Name), 'remove') )
    {
        Write-Verbose -Message ('[{0}]              -' -f $Name)
        $group.Delete()
    }

}

function Uninstall-CScheduledTask
{
    <#
    .SYNOPSIS
    Uninstalls a scheduled task on the current computer.

    .DESCRIPTION
    The `Uninstall-CScheduledTask` function uses `schtasks.exe` to uninstall a scheduled task on the current computer. If the task doesn't exist, nothing happens.

    .LINK
    Get-CScheduledTask

    .LINK
    Test-CScheduledTask

    .LINK
    Install-CScheduledTask

    .EXAMPLE
    Uninstall-CScheduledTask -Name 'doc'

    Demonstrates how to delete a scheduled task named `doc`.

    .EXAMPLE
    Uninstall-CScheduledTask -Name 'doc' -Force

    Demonstrates how to delete a scheduled task that is currently running.
    #>
    [CmdletBinding(DefaultParameterSetName='AsBuiltinPrincipal')]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to uninstall.
        $Name,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.ScheduledTasks'
    }

    $Name = Join-Path -Path '\' -ChildPath $Name

    $MAX_TRIES = 5
    $tryNum = 0
    do
    {
        if( -not (Test-CScheduledTask -Name $Name -NoWarn) )
        {
            Write-Verbose ('Scheduled task ''{0}'' not found.' -f $Name)
            return
        }

        $lastTry = (++$tryNum -ge $MAX_TRIES)
        Write-Verbose ('Deleting scheduled task ''{0}''.' -f $Name)
        $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Uninstall-CScheduledTask+{0}' -f ([IO.Path]::GetRandomFileName()))
        schtasks.exe /delete /tn $Name '/F' 2> $errFile | ForEach-Object {
            if( $_ -match '\bERROR\b' )
            {
                if( $lastTry -or $err -notmatch 'The function attempted to use a name that is reserved for use by another transaction' )
                {
                    Write-Error $_
                }
            }
            elseif( $_ -match '\bWARNING\b' )
            {
                Write-Warning $_
            }
            else
            {
                Write-Verbose $_
            }
        }

        if( $LASTEXITCODE )
        {
            $err = (Get-Content -Path $errFile) -join ([Environment]::NewLine)
            if( -not $lastTry -and $err -match 'The function attempted to use a name that is reserved for use by another transaction' )
            {
                if( $Global:Error.Count -gt 0 )
                {
                    $Global:Error.RemoveAt(0)
                }
                if( $Global:Error.Count -gt 0 )
                {
                    $Global:Error.RemoveAt(0)
                }
                Write-Verbose ('Failed to delete scheduled task ''{0}'' (found ''The function attempted to use a name that is reserved for use by another transaction.'' error). Retrying (attempt #{1}).' -f $Name,$tryNum)
                Start-Sleep -Milliseconds 100
                continue
            }

            Write-Error $err
            break
        }
    }
    while( $true -and -not $lastTry)
}

function Uninstall-CService
{
    <#
    .SYNOPSIS
    Removes/deletes a service.

    .DESCRIPTION
    Removes an existing Windows service.  If the service doesn't exist, nothing happens.  The service is stopped before being deleted, so that the computer doesn't need to be restarted for the removal to complete.

    Beginning in Carbon 2.7, if the service's process is still running after the service is stopped (some services don't behave nicely) and the service is only running one process, `Uninstall-CService` will kill the service's process. This helps prevent requiring a reboot. If you want to give the service time to

    .LINK
    Install-CService

    .EXAMPLE
    Uninstall-CService -Name DeathStar

    Removes the Death Star Windows service.  It is destro..., er, stopped first, then destro..., er, deleted.  If only the rebels weren't using Linux!
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service name to delete.
        $Name,

        [timespan]
        # The amount of time to wait for the service to stop before attempting to kill it. The default is not to wait.
        #
        # This parameter was added in Carbon 2.7.
        $StopTimeout,

        [switch] $NoWarn
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $NoWarn)
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Windows.Service'
    }

    $service = Get-Service -ErrorAction Ignore | Where-Object 'Name' -EQ $Name
    $sc = Join-Path -Path $env:WinDir -ChildPath 'system32\sc.exe' -Resolve

    if( -not $service )
    {
        return
    }

    $origVerbosePref = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    $cimService = Get-CimInstance 'Win32_Service' -Filter ('Name = ''{0}''' -f $service.Name)
    $cimServiceProcessCount = 0
    if( $cimService )
    {
        $cimServiceProcessCount = Get-CimInstance 'Win32_Service' -Filter ('ProcessId = ''{0}''' -f $cimService.ProcessId) |
                                            Measure-Object |
                                            Select-Object -ExpandProperty 'Count'
    }
    $VerbosePreference = $origVerbosePref

    if( -not $pscmdlet.ShouldProcess( "service '$Name'", "remove" ) )
    {
        return
    }

    Stop-Service $Name
    if( $cimService -and $cimServiceProcessCount -eq 1 )
    {
        $process = Get-Process -Id $cimService.ProcessId -ErrorAction Ignore
        if( $process )
        {
            $killService = $true
            if( $StopTimeout )
            {
                Write-Verbose -Message ('[Uninstall-CService]  [{0}]  Waiting "{1}" second(s) for service process "{2}" to exit.' -f $Name,$StopTimeout.TotalSeconds,$process.Id)
                $killService = -not $process.WaitForExit($StopTimeout.TotalMilliseconds)
            }

            if( $killService )
            {
                $attemptNum = 0
                $maxAttempts = 100
                $killed = $false
                while( $attemptNum++ -lt $maxAttempts )
                {
                    Write-Verbose -Message ('[Uninstall-CService]  [{0}]  [Attempt {1,3} of {2}]  Killing service process "{3}".' -f $Name,$attemptNum,$maxAttempts,$process.Id)
                    Stop-Process -Id $process.Id -Force -ErrorAction Ignore
                    if( -not (Get-Process -Id $process.Id -ErrorAction Ignore) )
                    {
                        $killed = $true
                        break
                    }
                    Start-Sleep -Milliseconds 100
                }
                if( -not $killed )
                {
                    Write-Error -Message ('Failed to kill "{0}" service process "{1}".' -f $Name,$process.Id) -ErrorAction $ErrorActionPreference
                }
            }
        }
    }


    Write-Verbose -Message ('[Uninstall-CService]  [{0}]  {1} delete {0}' -f $Name,$sc)
    $output = & $sc delete $Name
    if( $LASTEXITCODE )
    {
        if( $LASTEXITCODE -eq 1072 )
        {
            Write-Warning -Message ('The {0} service is marked for deletion and will be removed during the next reboot.{1}{2}' -f $Name,([Environment]::NewLine),($output -join ([Environment]::NewLine)))
        }
        else
        {
            Write-Error -Message ('Failed to uninstall {0} service (returned non-zero exit code {1}):{2}{3}' -f $Name,$LASTEXITCODE,([Environment]::NewLine),($output -join ([Environment]::NewLine)))
        }
    }
    else
    {
        $output | Write-Verbose
    }
}

Set-Alias -Name 'Remove-Service' -Value 'Uninstall-CService'

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


function Write-CDscError
{
    <#
    .SYNOPSIS
    Writes DSC errors out as errors.

    .DESCRIPTION
    The Local Configuration Manager (LCM) applies configuration in a separate process space as a background service which writes its errors to the `Microsoft-Windows-DSC/Operational` event log. This function is intended to be used with `Get-CDscError`, and will write errors returned by that function as PowerShell errors.

    `Write-CDscError` is new in Carbon 2.0.

    .OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

    .LINK
    Get-CDscError

    .EXAMPLE
    Get-CDscError | Write-CDscError

    Demonstrates how `Write-CDscError` is intended to be used. `Get-CDscError` gets the appropriate event objects that `Write-CDscError` writes out.
    #>
    [CmdletBinding()]
    [OutputType([Diagnostics.Eventing.Reader.EventLogRecord])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Diagnostics.Eventing.Reader.EventLogRecord[]]
        # The error record to write out as an error.
        $EventLogRecord,

        [Switch]
        # Return the event log record after writing an error.
        $PassThru,

        [switch] $NoWarn
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.DSC'
        }

        foreach( $record in $EventLogRecord )
        {
            [string[]]$property = $record.Properties | Select-Object -ExpandProperty Value

            $message = $property[-1]

            Write-Error -Message ('[{0}] [{1}] [{2}] {3}' -f $record.TimeCreated,$record.MachineName,($property[0..($property.Count - 2)] -join '] ['),$message)

            if( $PassThru )
            {
                return $record
            }
        }
    }
}
