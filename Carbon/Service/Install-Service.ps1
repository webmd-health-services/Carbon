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
    Installs a Windows service. If a service with the given name already exists, it is stopped, its configuration is updated to match the parameters passed in, and then re-started. If its configuration is unchanged, the function returns without making any changes. Settings whose parameters are omitted are reset to their default values.
    
    By default, the service is installed to run as `NetworkService`. Set the `Username` and `Password` arguments to run as a different account. This user will be granted the logon as a service right. To run as a system account other than `NetworkService`, provide just the account's name as the `UserName` parameter, and omit the `Password` parameter.

    The minimum required information to install a service is its name and path.

    [Managed service accounts and virtual accounts](http://technet.microsoft.com/en-us/library/dd548356.aspx) should be supported (we don't know how to test, so can't be sure).  Simply omit the `-Password` parameter when providing a custom account name with the `-Username` parameter.

    `Manual` services are not started. `Automatic` services are started after installation. If an existing manual service is started when configuration begins, it is re-started after re-configured.

    .LINK
    Uninstall-Service

    .LINK
    http://technet.microsoft.com/en-us/library/dd548356.aspx

    .EXAMPLE
    Install-Service -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe

    Installs the Death Star service, which runs the service executable at `C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe`.  The service runs as `NetworkService` and will start automatically.

    .EXAMPLE
    Install-Service -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Manual

    Install the Death Star service to startup manually.  You certainly don't want the thing roaming the galaxy, destroying thing willy-nilly, do you?

    .EXAMPLE
    Install-Service -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Username EMPIRE\wtarkin -Password 5irewh3nready

    Installs the Death Star service to run as Grand Moff Tarkin, who is given the log on as a service right.

    .EXAMPLE
    Install-Service -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Username SYSTEM

    Demonstrates how to install a service to run as a system account other than `NetworkService`. Installs the DeathStart service to run as the local `System` account.

    .EXAMPLE
    Install-Service -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -OnFirstFailure RunCommand -RunCommandDelay 5000 -Command 'engage_hyperdrive.exe "Corruscant"' -OnSecondFailure Restart -RestartDelay 30000 -OnThirdFailure Reboot -RebootDelay 120000 -ResetFailureCount (60*60*24)

    Demonstrates how to control the service's failure actions. On the first failure, Windows will run the `engage-hyperdrive.exe "Corruscant"` command after 5 seconds (`5,000` milliseconds). On the second failure, Windows will restart the service after 30 seconds (`30,000` milliseconds). On the third failure, Windows will reboot after two minutes (`120,000` milliseconds). The failure count gets reset once a day (`60*60*24` seconds).
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
        
        [ServiceProcess.ServiceStartMode]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        $StartupType = [ServiceProcess.ServiceStartMode]::Automatic,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure = [Carbon.Service.FailureAction]::TakeNoAction,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure = [Carbon.Service.FailureAction]::TakeNoAction,
        
        [Carbon.Service.FailureAction]
        # What to do on the service' third failure.  Default is to take no action.
        $OnThirdFailure = [Carbon.Service.FailureAction]::TakeNoAction,

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
        
        [string]
        # The command to run when a service fails, including path to the command and arguments.
        $Command,
        
        [int]
        # How many milliseconds to wait before running the failure command. Default is 0, or immediately.
        $RunCommandDelay = 0,
        
        [Parameter(ParameterSetName='CustomAccount',Mandatory=$true)]
        [string]
        # The user the service should run as. Default is NetworkService.
        $Username,
        
        [Parameter(ParameterSetName='CustomAccount')]
        [string]
        # The user's password.
        $Password,

        [Switch]
        # Update the service even if there are no changes.
        $Force
    )

    Set-StrictMode -Version 'Latest'

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

    if( $PSCmdlet.ParameterSetName -eq 'CustomAccount' )
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
    
    $doInstall = $false
    if( -not $Force -and (Test-Service -Name $Name) )
    {
        Write-Verbose ('Service {0} exists. Checking if configuration has changed.' -f $Name)
        $service = Get-Service -Name $Name
        $serviceConfig = Get-ServiceConfiguration -Name $Name
        $dependedOnServiceNames = $service.ServicesDependedOn | Select-Object -ExpandProperty 'Name'

        Write-Verbose ('[{0}] Path              {1} | {2}' -f $Name,$serviceConfig.Path,$Path)
        Write-Verbose ('[{0}] OnFirstFailure    {1} | {2}' -f $Name,$serviceConfig.FirstFailure,$OnFirstFailure)
        Write-Verbose ('[{0}] OnSecondFailure   {1} | {2}' -f $Name,$serviceConfig.SecondFailure,$OnSecondFailure)
        Write-Verbose ('[{0}] OnThirdFailure    {1} | {2}' -f $Name,$serviceConfig.ThirdFailure,$OnThirdFailure)
        Write-Verbose ('[{0}] ResetFailureCount {1} | {2}' -f $Name,$serviceConfig.ResetPeriod,$ResetFailureCount)

        $doInstall = $service.Path -ne $Path -or 
                     $serviceConfig.FirstFailure -ne $OnFirstFailure -or
                     $serviceConfig.SecondFailure -ne $OnSecondFailure -or
                     $serviceConfig.ThirdFailure -ne $OnThirdFailure -or
                     $serviceConfig.ResetPeriod -ne $ResetFailureCount
        
        $failureActions = $OnFirstFailure,$OnSecondFailure,$OnThirdFailure
        if( -not $doInstall )
        {
            if( $failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::Reboot } )
            {
                Write-Verbose ('[{0}] RebootDelay       {1} | {2}' -f $Name,$serviceConfig.RebootDelay,$RebootDelay)
                $doInstall = $serviceConfig.RebootDelay -ne $RebootDelay
            }
        }

        if( -not $doInstall )
        {
            if( $failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::Restart } )
            {
                Write-Verbose ('[{0}] RestartDelay      {1} | {2}' -f $Name,$serviceConfig.RestartDelay,$RestartDelay)
                $doInstall = $serviceConfig.RestartDelay -ne $RestartDelay
            }
        }

        if( -not $doInstall )
        {
            if( $failureActions | Where-Object { $_ -eq [Carbon.Service.FailureAction]::RunCommand } )
            {
                Write-Verbose ('[{0}] Command           {1} | {2}' -f $Name,$serviceConfig.FailureProgram,$Command)
                $doInstall = $serviceConfig.FailureProgram -ne $Command -or
                             $serviceConfig.RunCommandDelay -ne $RunCommandDelay
            }
        }

        if( -not $doInstall )
        {
            Write-Verbose ('[{0}] StartupType       {1} | {2}' -f $Name,$serviceConfig.StartType,$StartupType)
            $doInstall = $service.StartMode -ne $StartupType
        }

        if( -not $doInstall )
        {
            Write-Verbose ('[{0}] Dependency        {1} | {2}' -f $Name,($dependedOnServiceNames -join ','),($Dependency -join ','))
            if( $Dependency | Where-Object { $dependedOnServiceNames -notcontains $_ } )
            {
                $doInstall = $true
            }

            if( $dependedOnServiceNames | Where-Object { $Dependency -notcontains $_ } )
            {
                $doInstall = $true
            }
        }

        if( -not $doInstall -and $PSCmdlet.ParameterSetName -eq 'CustomAccount' )
        {
            Write-Verbose ('[{0}] UserName          {1} | {2}' -f $Name,$serviceConfig.UserName,$identity)
            $doinstall = $serviceConfig.UserName -ne $identity
        }
    }
    else
    {
        $doInstall = $true
    }

    if( -not $doInstall )
    {
        Write-Verbose ('Skipping {0} service configuration: settings unchanged.' -f $Name)
        return
    }

    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Warning ('Service ''{0}'' executable ''{1}'' not found.' -f $Name,$Path)
    }
    else
    {
        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath
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
    if( $PSCmdlet.ParameterSetName -eq 'CustomAccount' )
    {
        if( $PSBoundParameters.ContainsKey( 'Password' ) )
        {
            $passwordArgName = 'password='
            $passwordArgValue = $Password
        }
        
        if( $PSCmdlet.ShouldProcess( $identity, "grant the log on as a service right" ) )
        {
            Grant-Privilege -Identity $identity -Privilege SeServiceLogonRight
        }
    }
    
    if( $PSCmdlet.ShouldProcess( $Path, ('grant {0} ReadAndExecute permissions' -f $identity) ) )
    {
        Grant-Permission -Identity $identity -Permission ReadAndExecute -Path $Path
    }
    
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    
    $operation = 'create'
    $serviceIsRunningStatus = @(
                                  [ServiceProcess.ServiceControllerStatus]::Running,
                                  [ServiceProcess.ServiceControllerStatus]::StartPending
                               )

    $restartService = ($StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic)
    if( $service )
    {
        $restartService = ( $restartService -or ($serviceIsRunningStatus -contains $service.Status) )

        $stopSuccessful = $false
        if( $service.CanStop )
        {
            Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            if( $? )
            {
                $service.WaitForStatus( 'Stopped' )
                $stopSuccessful = $true
            }

            if( (Get-Service -Name $Name).Status -eq [ServiceProcess.ServiceControllerStatus]::Stopped )
            {
                $stopSuccessful = $true
            }
        }
        
        if( -not $stopSuccessful )
        {
            Write-Warning "Unable to stop service '$Name' before applying config changes.  You may need to restart this service manually for any changes to take affect."
        }
        $operation = 'config'
    }
    
    $dependencyArgValue = '""'
    if( $Dependency )
    {
        $dependencyArgValue = $Dependency -join '/'
    }

    if( $PSCmdlet.ShouldProcess( "$Name [$Path]", "$operation service" ) )
    {
        & $sc $operation $Name binPath= $Path start= $startArg obj= $identity $passwordArgName $passwordArgValue depend= $dependencyArgValue
        if( $LastExitCode -ne 0 )
        {
            Write-Error "$sc failed $operation and returned '$LastExitCode'."
        }
    }
    
    $firstAction = ConvertTo-FailureActionArg $OnFirstFailure
    $secondAction = ConvertTo-FailureActionArg $OnSecondFailure
    $thirdAction = ConvertTo-FailureActionArg $OnThirdFailure

    if( -not $Command )
    {
        $Command = '""'
    }

    if( $PSCmdlet.ShouldProcess( $Name, "setting service failure actions" ) )
    {
        & $sc failure $Name reset= $ResetFailureCount actions= $firstAction/$secondAction/$thirdAction command= $Command
        if( $LastExitCode -ne 0 )
        {
            Write-Error "$sc failed when setting failure actions and returned '$LastExitCode'."
        }
    }
        
    if( $restartService )
    {
        if( $PSCmdlet.ShouldProcess( $Name, 'start service' ) )
        {
            Start-Service -Name $Name -Verbose:$VerbosePreference
            if( (Get-Service -Name $Name).Status -ne [ServiceProcess.ServiceControllerStatus]::Running )
            {
                if( $PSCmdlet.ParameterSetName -eq 'CustomAccount' -and -not $PSBoundParameters.ContainsKey('Password') )
                {
                    Write-Warning ('Service ''{0}'' didn''t start and you didn''t supply a password to Install-Service.  Is ''{1}'' a managed service account or virtual account? (See http://technet.microsoft.com/en-us/library/dd548356.aspx.)  If not, please provide the account''s password with the `-Password` parameter.' -f $Name,$Username)
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
        Write-Verbose ('Not re-starting {0} service. Its startup type is {0} and it wasn''t running when configuration began.' -f $Name,$StartupType)
    }

}
