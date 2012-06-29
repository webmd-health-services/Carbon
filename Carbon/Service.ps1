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

function Grant-ServiceControlPermission
{
    <#
    .SYNOPSIS
    Grants a user/group permission to control a service.

    .DESCRIPTION
    Users/groups that aren't administrators need to granted permission to control (e.g. start, stop) a service.  This function uses Microsoft's `subinacl.exe` program to grant those permissions.  

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
        Invoke-SubInAcl /service `"$Servicename`" /GRANT=`"$Identity`"=STOE
    }
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
            $ntRightsPath = Join-Path $CarbonBinDir ntrights.exe -Resolve
            & $ntRightsPath +r SeServiceLogonRight -u $Username
            if( $LastExitCode )
            {
                Write-Error "Failed to grant '$Username' the logon as a service right."
            }
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
        
        Start-Service -Name $Name
    }
}

function Invoke-SubInAcl
{
    <#
    .SYNOPSIS
    **INTERNAL.**  Invokes the SubInAcl console application, and parses its output so it displays correctly.  **This is an internal function is will be removed in a future release.**

    .DESCRIPTION
    **NOTE: This function will be removed in a future release.  It is internal, and should not be used.**

    Subinacl.exe outputs text for the classic Windows console.  This output doesn't work in PowerShell: it looks like there is a space between every character.  In fact, there are `null` bytes between each character.  Hopefully, somebody will be able to explain this to me someday.  Until then, this function runs `subinacl.exe` and parses its output to remove these extra `null` bytes.

    All parameters passed to `Invoke-SubInAcl` are passed to the actual `subinacl.exe` program unchanged.

    .EXAMPLE
    Invoke-SubInAcl /help

    Shows the SubInAcl help documentation.

    .EXAMPLE
    Invoke-SubInAcl /service `"CCService`" /GRANT=`"$Identity`"=STOE

    Grants `$Identity` permissions to control the `CCService`.  Note escaped quotes around some of the arguments to `subinacl.exe`.  You may or may not need to follow this pattern.  It's been too long since we wrote that code to remember.  We were PowerShell noobies back then.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromRemainingArguments=$true)]
        [string[]]
        $Parameters
    )
    
    $subInAclPath = Join-Path $CarbonBinDir subinacl.exe -Resolve
    $output = & $subInAclPath $Parameters
    $previousLineEmpty = $false
    $lineEmpty = $true
    foreach( $line in $output )
    {
        $lineEmpty = ( $line -eq "`0" )
        
        if( $previousLineEmpty -and $lineEmpty)
        {
            Write-Output ""
            $previousLineEmpty = $false
            continue
        }
        
        $line = $line -replace "`0",''
        if( $line )
        {
            Write-Output "$line"
        }
        $previousLineEmpty = $lineEmpty
    }
}

function Remove-Service
{
    <#
    .SYNOPSIS
    Removes/deletes a service.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service name
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
    Restarts a service on a remote machine
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service name
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the remote machine
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