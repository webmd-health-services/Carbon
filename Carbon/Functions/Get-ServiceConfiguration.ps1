
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
        $ComputerName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        $optionalParams = @{ }
        if( $ComputerName )
        {
            $optionalParams['ComputerName'] = $ComputerName
        }

        if( -not (Get-Service -Name $Name @optionalParams -ErrorAction $ErrorActionPreference) )
        {
            return
        }

        New-Object 'Carbon.Service.ServiceInfo' $Name,$ComputerName
    }
}
