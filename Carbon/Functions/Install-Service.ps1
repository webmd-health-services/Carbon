
function Install-CService
{
    <#
    .SYNOPSIS
    Installs a Windows service.

    .DESCRIPTION
    `Install-CService` uses `sc.exe` to install a Windows service. If a service with the given name already exists, it is stopped, its configuration is updated to match the parameters passed in, and then re-started. Settings whose parameters are omitted are reset to their default values.
    
    Beginning in Carbon 2.0, use the `PassThru` switch to return a `ServiceController` object for the new/updated service.

    By default, the service is installed to run as `NetworkService`. Use the `Credential` parameter to run as a different account (if you don't have a `Credential` parameter, upgrade to Carbon 2.0 or use the `UserName` and `Password` parameters). This user will be granted the logon as a service right. To run as a system account other than `NetworkService`, provide just the account's name as the `UserName` parameter.

    The minimum required information to install a service is its name and path.

    [Managed service accounts and virtual accounts](http://technet.microsoft.com/en-us/library/dd548356.aspx) should be supported (we don't know how to test, so can't be sure).  Simply omit the `-Password` parameter when providing a custom account name with the `-Username` parameter.

    `Manual` services are not started. `Automatic` services are started after installation. If an existing manual service is running when configuration begins, it is re-started after re-configured. If a service is stopped when configuration begins, it remains stopped when configuration ends. To start the service if it is stopped, use the `-EnsureRunning` switch (which was added in version 2.5.0).

    The ability to provide service arguments/parameters via the `ArgumentList` parameter was added in Carbon 2.0.

    .LINK
    Carbon_Service

    .LINK
    New-CCredential

    .LINK
    Uninstall-CService

    .LINK
    http://technet.microsoft.com/en-us/library/dd548356.aspx

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe

    Installs the Death Star service, which runs the service executable at `C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe`.  The service runs as `NetworkService` and will start automatically.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Manual

    Install the Death Star service to startup manually.  You certainly don't want the thing roaming the galaxy, destroying thing willy-nilly, do you?

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Automatic -Delayed

    Demonstrates how to set a service startup typemode to automatic delayed. Set the `StartupType` parameter to `Automatic` and provide the `Delayed` switch. This behavior was added in Carbon 2.5.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Credential $tarkinCredentials

    Installs the Death Star service to run as Grand Moff Tarkin, who is given the log on as a service right.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Username SYSTEM

    Demonstrates how to install a service to run as a system account other than `NetworkService`. Installs the DeathStart service to run as the local `System` account.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -OnFirstFailure RunCommand -RunCommandDelay 5000 -Command 'engage_hyperdrive.exe "Corruscant"' -OnSecondFailure Restart -RestartDelay 30000 -OnThirdFailure Reboot -RebootDelay 120000 -ResetFailureCount (60*60*24)

    Demonstrates how to control the service's failure actions. On the first failure, Windows will run the `engage-hyperdrive.exe "Corruscant"` command after 5 seconds (`5,000` milliseconds). On the second failure, Windows will restart the service after 30 seconds (`30,000` milliseconds). On the third failure, Windows will reboot after two minutes (`120,000` milliseconds). The failure count gets reset once a day (`60*60*24` seconds).

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -EnsureRunning

    Demonstrates how to ensure a service gets started after installation/configuration. Normally, `Install-CService` leaves the service in whatever state the service was in. The `EnsureRunnnig` switch will attempt to start the service even if it was stopped to begin with.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='NetworkServiceAccount')]
    [OutputType([ServiceProcess.ServiceController])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the service.
        $Path,

        [string[]]
        # The arguments/startup parameters for the service. Added in Carbon 2.0.
        $ArgumentList,
        
        [ServiceProcess.ServiceStartMode]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        #
        # To start the service as automatic delayed, use the `-Delayed` switch and set this parameter to `Automatic`. The ability to set a service's startup type to automatic delayed was added in Carbon 2.5.
        $StartupType = [ServiceProcess.ServiceStartMode]::Automatic,

        [Switch]
        # When the startup type is automatic, further configure the service start type to be automatic delayed. This parameter is ignored unless `StartupType` is `Automatic`.
        #
        # This switch was added in Carbon 2.5.
        $Delayed,
        
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

        [string]
        # The service's description. If you don't supply a value, the service's existing description is preserved.
        #
        # The `Description` parameter was added in Carbon 2.0.
        $Description,

        [string]
        # The service's display name. If you don't supply a value, the display name will set to Name.
        #
        # The `DisplayName` parameter was added in Carbon 2.0.
        $DisplayName,
        
        [Parameter(ParameterSetName='CustomAccount',Mandatory=$true)]
        [string]
        # The user the service should run as. Default is `NetworkService`.
        $UserName,
        
        [Parameter(ParameterSetName='CustomAccount',DontShow=$true)]
        [string]
        # OBSOLETE. The `Password` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
        $Password,

        [Parameter(ParameterSetName='CustomAccountWithCredential',Mandatory=$true)]
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
        $EnsureRunning
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

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


        $identity = Resolve-CIdentity -Name $UserName

        if( -not $identity )
        {
            Write-Error ("Identity '{0}' not found." -f $UserName)
            return
        }
    }
    else
    {
        $identity = Resolve-CIdentity "NetworkService"
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

    $passwordArgName = ''
    $passwordArgValue = ''
    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
    {
        if( $Credential )
        {
            $passwordArgName = 'password='
            $passwordArgValue = $Credential.GetNetworkCredential().Password -replace '"', '\"'
        }

        if( $PSCmdlet.ShouldProcess( $identity.FullName, "grant the log on as a service right" ) )
        {
            Grant-CPrivilege -Identity $identity.FullName -Privilege SeServiceLogonRight
        }
    }

    if( $PSCmdlet.ShouldProcess( $Path, ('grant {0} ReadAndExecute permissions' -f $identity.FullName) ) )
    {
        Grant-CPermission -Identity $identity.FullName -Permission ReadAndExecute -Path $Path
    }

    $doInstall = $false
    if( -not $Force -and (Test-CService -Name $Name) )
    {
        Write-Debug -Message ('Service {0} exists. Checking if configuration has changed.' -f $Name)
        $service = Get-Service -Name $Name
        $serviceConfig = Get-CServiceConfiguration -Name $Name
        $dependedOnServiceNames = $service.ServicesDependedOn | Select-Object -ExpandProperty 'Name'

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

        $currentIdentity = Resolve-CIdentity $serviceConfig.UserName
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
            $Dependency | 
                ForEach-Object {
                    if( -not (Test-CService -Name $_) )
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
    
        $dependencyArgValue = '""'
        if( $Dependency )
        {
            $dependencyArgValue = $Dependency -join '/'
        }

        $displayNameArgName = 'DisplayName='
        $displayNameArgValue = '""'
        if( $DisplayName )
        {
            $displayNameArgValue = $DisplayName
        }

        $binPathArg = $binPathArg -replace '"','\"'
        if( $PSCmdlet.ShouldProcess( "$Name [$Path]", "$operation service" ) )
        {
            Write-Verbose "$sc $operation $Name binPath= $binPathArg start= $startArg obj= $($identity.FullName) $passwordArgName $('*' * $passwordArgValue.Length) depend= $dependencyArgValue $displayNameArgName $displayNameArgValue"
            & $sc $operation $Name binPath= $binPathArg start= $startArg obj= $identity.FullName $passwordArgName $passwordArgValue depend= $dependencyArgValue $displayNameArgName $displayNameArgValue |
                Write-Verbose
            $scExitCode = $LastExitCode
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to {0} service '{1}'. {2} returned exit code {3}: {4}" -f $operation,$Name,$sc,$scExitCode,$reason)
                return
            }

            if( $Description )
            {
                & $sc 'description' $Name $Description | Write-Verbose
                $scExitCode = $LastExitCode
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

        if( -not $Command )
        {
            $Command = '""'
        }

        if( $PSCmdlet.ShouldProcess( $Name, "setting service failure actions" ) )
        {
            & $sc failure $Name reset= $ResetFailureCount actions= $firstAction/$secondAction/$thirdAction command= $Command |
                Write-Verbose
            $scExitCode = $LastExitCode
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
                Start-Service -Name $Name -ErrorAction $ErrorActionPreference
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
