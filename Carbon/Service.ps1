
Add-Type -AssemblyName System.ServiceProcess

function Grant-ControlServicePermission
{
    <#
    .SYNOPSIS
    Grants a user/group permission to control a service.
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
    Installs a Windows service, uninstalling if it doesn't already exist.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='NetworkServiceAccount')]
    param(
        [Parameter(Mandatory=$true)]
        # The name of the service.
        $Name,
        
        [Parameter(Mandatory=$true)]
        # The path to the service.
        $Path,
        
        [Parameter()]
        [ServiceProcess.ServiceStartMode]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        $StartupType = [ServiceProcess.ServiceStartMode]::Automatic,
        
        [Parameter()]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure = 'TakeNoAction',
        
        [Parameter()]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure = 'TakeNoAction',
        
        [Parameter()]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service' third failure.  Default is to take no action.
        $OnThirdFailure = 'TakeNoAction',
        
        [Parameter()]
        [int]
        # How many seconds after which the failure count is reset to 0.
        $ResetFailureCount = 0,
        
        [Parameter()]
        [int]
        # How many milliseconds to wait before restarting the service.  Default is 60,0000, or 1 minute.
        $RestartDelay = 60000,
        
        [Parameter()]
        [int]
        # How many milliseconds to wait before handling the second failure.  Default is 60,000 or 1 minute.
        $RebootDelay = 60000,
        
        [Parameter()]
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
    Invokes the SubInAcl console application, and parses its output so it displays correctly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromRemainingArguments=$true)]
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


function Restart-RemoteService_SC
{
 <#
    .SYNOPSIS
    Restarts a service on a remote machine using the SC command instead of PSH
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
    Stop-Service_SC $Name $ComputerName
    Start-Service_SC $Name $ComputerName
}
 
function Invoke-SC($command, $serviceName, $computerName)
{
	$scOutput = C:\Windows\system32\sc.exe "\\$computerName" $command $serviceName
}

function Get-ServiceStatus_SC($serviceName, $computerName)
{
	$service = Get-Service -name $serviceName -ComputerName $computerName -ErrorAction SilentlyContinue
	$status = if( $service -eq $null ) { $null } else { $service.Status }
	return $status
}

function Start-Service_SC($serviceName, $computerName)
{
	Write-Host "Starting service $serviceName on computer $computerName" -NoNewline
	
	$status = Get-ServiceStatus_SC $serviceName $computerName
	if( $status -ne 'Running' -and $status -ne 'StartPending' )
	{
		Invoke-SC 'Start' $serviceName $computerName
	}

	Wait-ServiceState_SC 'Running' $serviceName $computerName
}

function Stop-Service_SC($serviceName, $computerName)
{
	Write-Host "Stopping service $serviceName on computer $computerName" -NoNewline

	$status = Get-ServiceStatus_SC $serviceName $computerName
	if( $status -ne 'Stopped' -and $status -ne 'StopPending' )
	{
		Invoke-SC 'Stop' $serviceName $computerName
	}

	Wait-ServiceState_SC 'Stopped' $serviceName $computerName
}

function Wait-ServiceState_SC($state, $serviceName, $computerName)
{
	$status = ''
	$tryCount = 0
	do
	{
		Start-Sleep 1
		$status = Get-ServiceStatus_SC $serviceName $computerName
		Write-Host "." -NoNewline
		$tryCount++
	}
	until( $tryCount -gt 10 -or $status -eq $state )
	
	if( $tryCount -gt 10 )
	{
		Write-Host $status -NoNewline
	}

	Write-Host ""
}