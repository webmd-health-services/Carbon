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

Add-Type -AssemblyName System.ServiceProcess

function Assert-Service
{
    <#
    .SYNOPSIS
    Checks if a service exists, and writes an error if it doesn't.
    
    .DESCRIPTION
    Also returns `True` if the service exists, `False` if it doesn't.
    
    .OUTPUTS
    System.Boolean.
    
    .LINK
    Test-Service
    
    .EXAMPLE
    Assert-Service -Name 'Drivetrain'
    
    Writes an error if the `Drivetrain` service doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name
    )
    
    if( -not (Test-Service $Name) )
    {
        Write-Error ('Service {0} not found.' -f $Name)
        return $false
    }
    
    return $true
}

function Get-ServiceAcl
{
    <#
    .SYNOPSIS
    Gets the discretionary access control list (i.e. DACL) for a service.
    
    .DESCRIPTION
    You wanted it, you got it!  You probably want to use `Get-ServicePermissions` instead.  If you want to chagne a service's permissions, use `Grant-ServicePermission` or `Revoke-ServicePermissions`.
    
    .LINK
    Get-ServicePermissions
    
    .LINK
    Grant-ServicePermission
    
    .LINK
    Revoke-ServicePermission
    
    .EXAMPLE
    Get-ServiceAcl -Name Hyperdrive
    
    Gets the `Hyperdrive` service's DACL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service whose DACL to return.
        $Name
    )

    $rawSD = Get-ServiceSecurityDescriptor -Name $Name
    $rawDacl = $rawSD.DiscretionaryAcl
    New-Object Security.AccessControl.DiscretionaryAcl $false,$false,$rawDacl
}


function Get-ServiceSecurityDescriptor
{
    <#
    .SYNOPSIS
    Gets the raw security descriptor for a service.
    
    .DESCRIPTION
    You probably don't want to mess with the raw security descriptor.  Try `Get-ServicePermissions` instead.  Much more useful.
    
    .OUTPUTS
    System.Security.AccessControl.RawSecurityDescriptor.
    
    .LINK
    Get-ServicePermissions
    
    .LINK
    Grant-ServicePermissions
    
    .LINK
    Revoke-ServicePermissions
    
    .EXAMPLE
    Get-ServiceSecurityDescriptor -Name 'Hyperdrive'
    
    Gets the hyperdrive service's raw security descriptor.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service whose permissions to return.
        $Name
    )

    $sdBytes = [Carbon.AdvApi32]::GetServiceSecurityDescriptor($Name)
    New-Object Security.AccessControl.RawSecurityDescriptor $sdBytes,0
}

function Get-ServicePermissions
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
    Get-ServicePermissions -Name 'Hyperdrive'
    
    Gets the access rules for the `Hyperdrive` service.
    
    .EXAMPLE
    Get-ServicePermissions -Name 'Hyperdrive' -Identity FALCON\HSolo
    
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
        $Identity
    )
    
    $dacl = Get-ServiceAcl -Name $Name
    
    $rIdentity = $null
    if( $Identity )
    {
        $rIdentity = Resolve-IdentityName -Name $Identity
        if( -not $rIdentity )
        {
            Write-Error ("Identity {0} not found." -f $identity)
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
            if( $rIdentity )
            {
                return ($_.IdentityReference.Value -eq $rIdentity)
            }
            return $_
        }
}

function Grant-ServiceControlPermission
{
    <#
    .SYNOPSIS
    Grants a user/group permission to start/stop (i.e. use PowerShell's `*-Service` cmdlets) a service.

    .DESCRIPTION
    By default, only Administrators are allowed to control a service. You may notice that when running the `Stop-Service`, `Start-Service`, or `Restart-Service` cmdlets as a non-Administrator, you get permissions errors. That's because you need to correct permissions.  This function grants just the permissions needed to use PowerShell's `Stop-Service`, `Start-Service`, and `Restart-Service` cmdlets to control a service.

    .LINK
    Get-ServicePermissions
    
    .LINK
    Grant-ServicePermission
    
    .LINK
    Revoke-ServicePermission
    
    .EXAMPLE
    Grant-ServiceControlPermission -ServiceName CCService -Identity INITRODE\Builders

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
        $Identity
    )
   
    if( $pscmdlet.ShouldProcess( $ServiceName, "grant control service permissions to '$Identity'" ) )
    {
        Write-Host "Granting '$Identity' the permissions to control '$ServiceName'."
        Grant-ServicePermission -Name $ServiceName -Identity $Identity -QueryStatus -EnumerateDependents -Start -Stop
    }
}

function Grant-ServicePermission
{
    <#
    .SYNOPSIS
    Grants permissions for an identity against a service.
    
    .DESCRIPTION
    By default, only Administators are allowed to manage a service.  Use this function to grant specific identities permissions to manage a specific service.
    
    If you just want to grant a user the ability to start/stop/restart a service using PowerShell's `Start-Service`, `Stop-Service`, or `Restart-Service` cmdlets, use the `Grant-ServiceControlPermissions` function instead.
    
    Any previous permissions are replaced.
    
    .LINK
    Get-ServicePermissions
    
    .LINK
    Grant-ServiceControlPermissions
    
    .EXAMPLE
    Grant-ServicePermission -Identity FALCON\Chewbacca -Name Hyperdrive -QueryStatus -EnumerateDependents -Start -Stop
    
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
        $WriteOwner
    )

    $rIdentity = Resolve-IdentityName -Name $Identity
    if( -not $rIdentity )
    {
        return
    }
    
    if( -not (Assert-Service -Name $Name) )
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
    
    $identitySid = Test-Identity -Name $Identity -PassThru

    $dacl = Get-ServiceAcl -Name $Name
    $dacl.SetAccess( [Security.AccessControl.AccessControlType]::Allow, $identitySid, $accessRights, 'None', 'None' )
    
    Set-ServiceAcl -Name $Name -DACL $dacl
}

function Install-Service
{
    <#
    .SYNOPSIS
    Installs a Windows service.

    .DESCRIPTION
    Installs a Windows service.  If a service with the given name already exists, it is left in place, and the its configuration is updated to match the parameters passed in.  In order to configure it, the service is stopped, configured, then started.  By default, the service is installed to run as `NetworkService`.  Set the `Username` and `Password` arguments to run as a different account.  This user will be granted the logon as a service right.

    The minimum required information to install a service is its name and path.  By default the servide will run as `NetworkService` and will start automatically.  Review the parameter list for additional configuraiton options and their defaults.  Normally, we would list them here, but there's like 300 of them and we really don't have the time.  I'm so mean, I'm not even going to give you *examples* of all the different options.  Feel free to send in your own.

    .EXAMPLE
    Install-Service -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe

    Installs the Death Star service, which runs the service executable at `C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe`.  The service runs as `NetworkService` and will start automatically.

    .EXAMPLE
    Install-Service -Name DetahStart -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Manual

    Install the Death Star service to startup manually.  You certainly don't want the thing roaming the galaxy, destroying thing willy-nilly, do you?

    .EXAMPLE
    Install-Service -Name DetahStart -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Username EMPIRE\wtarkin -Password 5irewh3nready

    Installs the Death Star service to run as Grand Moff Tarkin, who is given the log on as a service right.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='NetworkServiceAccount')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the service.
        $Path,
        
        [Parameter()]
        [ServiceProcess.ServiceStartMode]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        $StartupType = [ServiceProcess.ServiceStartMode]::Automatic,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure = 'TakeNoAction',
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure = 'TakeNoAction',
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service' third failure.  Default is to take no action.
        $OnThirdFailure = 'TakeNoAction',
        
        [int]
        # How many seconds after which the failure count is reset to 0.
        $ResetFailureCount = 0,
        
        [int]
        # How many milliseconds to wait before restarting the service.  Default is 60,0000, or 1 minute.
        $RestartDelay = 60000,
        
        [int]
        # How many milliseconds to wait before handling the second failure.  Default is 60,000 or 1 minute.
        $RebootDelay = 60000,
        
        [string[]]
        # What other services does this service depend on?
        $Dependencies = @(),
        
        [Parameter(ParameterSetName='CustomAccount',Mandatory=$true)]
        [string]
        # The user the service should run as.
        $Username,
        
        [Parameter(ParameterSetName='CustomAccount',Mandatory=$true)]
        [string]
        # The user's password.
        $Password
    )
    
    function ConvertTo-FailureActionArg($action, $restartDelay, $rebootDelay)
    {
        if( $action -eq 'Reboot' )
        {
            return "reboot/$rebootDelay"
        }
        elseif( $action -eq 'Restart' )
        {
            return "restart/$restartDelay"
        }
        elseif( $action -eq 'TakeNoAction' )
        {
            return '""/0'
        }
        else
        {
            throw "Unsupported service failure action '$action'."
        }
    }

    foreach( $dependency in $Dependencies )
    {
        if( -not (Get-Service -Name $dependency -ErrorAction SilentlyContinue) )
        {
            throw "Unable to install service '$Name': dependent service '$dependency' does not exist."
        }
    }

    $sc = Join-Path $env:WinDir system32\sc.exe -Resolve
    
    $startArg = 'auto'
    if( $StartupType -eq 'Manual' )
    {
        $startArg = 'demand'
    }
    elseif( $StartupType -eq 'Disabled' )
    {
        $startArg = 'disabled'
    }
    
    $account = "NT AUTHORITY\NetworkService"
    $passwordArgName = ''
    $passwordArgValue = ''
    if( $pscmdlet.ParameterSetName -eq 'CustomAccount' )
    {
        $account = if( $Username.Contains( '\' ) ) { $Username } else { ".\$Username" }
        $passwordArgName = 'password='
        $passwordArgValue = $Password
        
        # TODO: Convert this to C# code (see the ActiveDirectory task in the MSBuild extension pack.
        if( $pscmdlet.ShouldProcess( $Username, "grant the log on as a service right" ) )
        {
            Write-Host "Granting user '$Username' the log on as a service right."
            Grant-Privilege -Identity $Username -Privilege SeServiceLogonRight
        }

        Grant-Permissions -Identity $Username -Permissions FullControl -Path $Path
    
    }
    
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    
    $operation = 'create'
    if( $service )
    {
        $stopSuccessful = $false
        if( $service.CanStop )
        {
            Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            if( $? )
            {
                $service.WaitForStatus( 'Stopped' )
                $stopSuccessful = $true
            }
        }
        
        if( -not $stopSuccessful )
        {
            Write-Warning "Unable to stop service '$Name' before applying config changes.  You may need to restart this service manually for any changes to take affect."
        }
        $operation = 'config'
    }
    
    if( $pscmdlet.ShouldProcess( "$Name [$Path]", "$operation service" ) )
    {
        Write-Host "Installing service '$Name' at '$Path' to run as '$account'."
        $dependencyArgName = ''
        $dependencyArgValue = ''
        if( $Dependencies )
        {
            $dependencyArgName = 'depend='
            $dependencyArgValue = $Dependencies -join '/'
        }
        
        & $sc $operation $Name binPath= $Path start= $startArg obj= $account $passwordArgName $passwordArgValue $dependencyArgName $dependencyArgValue
        if( $LastExitCode -ne 0 )
        {
            Write-Error "$sc failed and returned '$LastExitCode'."
        }
        
        $firstAction = ConvertTo-FailureActionArg $OnFirstFailure $RestartDelay $RebootDelay
        $secondAction = ConvertTo-FailureActionArg $OnSecondFailure $RestartDelay $RebootDelay
        $thirdAction = ConvertTo-FailureActionArg $OnThirdFailure $RestartDelay $RebootDelay
        & $sc failure $Name reset= $ResetFailureCount actions= $firstAction/$secondAction/$thirdAction
        if( $LastExitCode -ne 0 )
        {
            Write-Error "$sc failed when setting failure actions and returned '$LastExitCode'."
        }
        
        if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic )
        {
            Start-Service -Name $Name
        }
    }
}

function Remove-Service
{
    <#
    .SYNOPSIS
    Removes/deletes a service.

    .DESCRIPTION
    Removes an existing Windows service.  If the service doesn't exist, nothing happens.  The service is stopped before being deleted, so that the computer doesn't need to be restarted for the removal to complete.  Even then, sometimes it won't go away until a reboot.  I don't get it either.

    .EXAMPLE
    Remove-Service -Name DeathStar

    Removes the Death Star Windows service.  It is destro..., er, stopped first, then destro..., er, deleted.  If only the rebels weren't using Linux!
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service name to delete.
        $Name
    )
    
    $service = Get-Service | Where-Object { $_.Name -eq $Name }
    
    if( $service )
    {
        if( $pscmdlet.ShouldProcess( "service '$Name'", "remove" ) )
        {
            Stop-Service $Name
            & C:\Windows\system32\sc.exe delete $Name
        }
    }
}


function Restart-RemoteService
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
    Restart-RemoteService -Name DeathStar -ComputerName Yavin

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
        $ComputerName
    )
    
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
 
 function Revoke-ServicePermission
 {
    <#
    .SYNOPSIS
    Removes all permissions an identity has to manage a service.
    
    .DESCRIPTION
    No permissions are left behind.  This is an all or nothing operation, baby!
    
    .LINK
    Get-ServicePermissions
    
    .LINK
    Grant-ServicePermission
    
    .EXAMPLE
    Revoke-ServicePermission -Name 'Hyperdrive` -Identity 'CLOUDCITY\LCalrissian'
    
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
        $Identity
    )
    
    $rIdentity = Resolve-IdentityName -Name $Identity
    if( -not $rIdentity )
    {
        return
    }
    
    if( -not (Assert-Service -Name $Name) )
    {
        return
    }
    
    if( (Get-ServicePermissions -Name $Name -Identity $rIdentity) )
    {
        Write-Host ("Revoking {0}'s {1} service permissions." -f $rIdentity,$Name)
        
        $dacl = Get-ServiceAcl -Name $Name
        $sid = Test-Identity -Name $rIdentity -PassThru
        $dacl.Purge( $sid )
        
        Set-ServiceAcl -Name $Name -Dacl $dacl
    }
 }
 
 function Set-ServiceAcl
 {
    <#
    .SYNOPSIS
    Sets a service's discretionary access control list (i.e. DACL).
    
    .DESCRIPTION
    The existing DACL is replaced with the new DACL.  No previous permissions are preserved.  That's your job.  You're warned!
    
    You probably want `Grant-ServicePermission` or `Revoke-ServicePermission` instead.
    
    .LINK
    Get-ServicePermission
    
    .LINK
    Grant-ServicePermission
    
    .LINK
    Revoke-ServicePermission
    
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
        $Dacl
    )
    
    $rawSD = Get-ServiceSecurityDescriptor -Name $Name
    $daclBytes = New-Object byte[] $Dacl.BinaryLength 
    $Dacl.GetBinaryForm($daclBytes, 0);
    $rawSD.DiscretionaryAcl = New-Object Security.AccessControl.RawAcl $daclBytes,0
    $sdBytes = New-Object byte[] $rawSD.BinaryLength   
    $rawSD.GetBinaryForm($sdBytes, 0);
    
    if( $pscmdlet.ShouldProcess( ("{0} service DACL" -f $Name), "set" ) )
    {
        [Carbon.AdvApi32]::SetServiceSecurityDescriptor( $Name, $sdBytes )
    }
}
 
 function Test-Service
 {
    <#
    .SYNOPSIS
    Tests if a service exists, without writing anything out to the error stream.
    
    .DESCRIPTION
    `Get-Service` writes an error when a service doesn't exist.  This function tests if a service exists without writing anyting to the output stream.
    
    .OUTPUTS
    System.Boolean.
    
    .EXAMPLE
    Test-Service -Name 'Drive'
    
    Returns `true` if the `Drive` service exists.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service to test.
        $Name
    )
    
    $service = Get-Service -Name "$Name*" |
                    Where-Object { $_.Name -eq $Name }
    if( $service )
    {
        return $true
    }
    else
    {
        return $false
    }
 }