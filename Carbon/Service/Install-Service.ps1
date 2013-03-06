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
        
        [Alias('Dependencies')]
        [string[]]
        # What other services does this service depend on?
        $Dependency,
        
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
            Write-Error "Service failure action '$action' not found/recognized."
            return ''
        }
    }

    if( $Dependency )
    {
        $missingDependencies = $false
        $Dependency | 
            ForEach-Object {
                if( -not (Test-Service -Name $_) )
                {
                    Write-Error ('Dependent service {0} not found.' -f $_)
                    $missingDependencies = $true
                }
            }
        if( $missingDependencies )
        {
            return
        }
    }
    
    if( $pscmdlet.ParameterSetName -eq 'CustomAccount' )
    {
        $identity = Resolve-IdentityName -Name $Username
        if( -not $identity )
        {
            Write-Error ("Service identity '{0}' not found." -f $Username,$Name)
            return
        }
    }
    else
    {
        $identity = "NT AUTHORITY\NetworkService"
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
    
    $passwordArgName = ''
    $passwordArgValue = ''
    if( $pscmdlet.ParameterSetName -eq 'CustomAccount' )
    {
        $passwordArgName = 'password='
        $passwordArgValue = $Password
        
        if( $pscmdlet.ShouldProcess( $identity, "grant the log on as a service right" ) )
        {
            Write-Host ("Granting '{0}' the log on as a service right." -f $Identity)
            Grant-Privilege -Identity $identity -Privilege SeServiceLogonRight
        }
    }
    
    if( $pscmdlet.ShouldProcess( $Path, ('grant {0} ReadAndExecute permissions' -f $identity) ) )
    {
        Grant-Permission -Identity $identity -Permission ReadAndExecute -Path $Path
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
    
    $dependencyArgName = ''
    $dependencyArgValue = ''
    if( $Dependency )
    {
        $dependencyArgName = 'depend='
        $dependencyArgValue = $Dependency -join '/'
    }

    if( $pscmdlet.ShouldProcess( "$Name [$Path]", "$operation service" ) )
    {
        Write-Host "Installing service '$Name' at '$Path' to run as '$identity'."
        
        & $sc $operation $Name binPath= $Path start= $startArg obj= $identity $passwordArgName $passwordArgValue $dependencyArgName $dependencyArgValue
        if( $LastExitCode -ne 0 )
        {
            Write-Error "$sc failed $operation and returned '$LastExitCode'."
        }
    }
    
    $firstAction = ConvertTo-FailureActionArg $OnFirstFailure $RestartDelay $RebootDelay
    $secondAction = ConvertTo-FailureActionArg $OnSecondFailure $RestartDelay $RebootDelay
    $thirdAction = ConvertTo-FailureActionArg $OnThirdFailure $RestartDelay $RebootDelay

    if( $pscmdlet.ShouldProcess( $Name, "setting service failure actions" ) )
    {
        & $sc failure $Name reset= $ResetFailureCount actions= $firstAction/$secondAction/$thirdAction
        if( $LastExitCode -ne 0 )
        {
            Write-Error "$sc failed when setting failure actions and returned '$LastExitCode'."
        }
    }
        
    if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic )
    {
        if( $pscmdlet.ShouldProcess( $Name, 'start service' ) )
        {
            Start-Service -Name $Name
        }
    }
}
