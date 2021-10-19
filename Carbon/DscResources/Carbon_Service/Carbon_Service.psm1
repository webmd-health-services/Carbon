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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name,
        
        [string]
        # The path to the service.
        $Path,
        
        [ValidateSet('Automatic','Manual','Disabled')]
        [string]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        $StartupType,

        [Switch]
        $Delayed,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure,
        
        [Carbon.Service.FailureAction]
        # What to do on the service' third failure.  Default is to take no action.
        $OnThirdFailure,
        
        [int]
        # How many seconds after which the failure count is reset to 0.
        $ResetFailureCount,
        
        [int]
        # How many milliseconds to wait before restarting the service.  Default is 60,0000, or 1 minute.
        $RestartDelay,
        
        [int]
        # How many milliseconds to wait before handling the second failure.  Default is 60,000 or 1 minute.
        $RebootDelay,
        
        [string[]]
        # What other services does this service depend on?
        $Dependency,
        
        [string]
        # The command to run when a service fails, including path to the command and arguments.
        $Command,
        
        [int]
        # How many milliseconds to wait before running the failure command. Default is 0, or immediately.
        $RunCommandDelay,

        [string]
        # The service's display names.
        $DisplayName,
        
        [string]
        # The service's description.
        $Description,
        
        [ValidateSet("LocalSystem", "LocalService", "NetworkService")]
        [string]
        # The system account the service should run as.
        $UserName,
        
        [pscredential]
        # The credentials of the custom account the service should run as.
        $Credential,
        
        [string[]]
        # The arguments/startup parameters for the service
        $ArgumentList,

        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure = 'Present'        
    )

    Set-StrictMode -Version 'Latest'

    $resource = @{
                    Name = $Name;
                    Path = $null;
                    StartupType = $null;
                    Delayed = $null;
                    OnFirstFailure = $null;
                    OnSecondFailure = $null;
                    OnThirdFailure = $null;
                    ResetFailureCount = $null;
                    RestartDelay = $null;
                    RebootDelay = $null;
                    Command = $null;
                    RunCommandDelay = $null;
                    Dependency = $null;
                    DisplayName = $null;
                    Description = $null;
                    UserName = $null;
                    Credential = $null;
                    Ensure = 'Absent';
                    ArgumentList = $null;
                }

    if( Test-CService -Name $Name )
    {
        $service = Get-Service -Name $Name
        
        $resource.Path,$resource.ArgumentList = [Carbon.Shell.Command]::Split($service.Path)
        $resource.StartupType = $service.StartMode
        $resource.Delayed = $service.DelayedAutoStart
        $resource.OnFirstFailure = $service.FirstFailure
        $resource.OnSecondFailure = $service.SecondFailure
        $resource.OnThirdFailure = $service.ThirdFailure
        $resource.ResetFailureCount = $service.ResetPeriod
        $resource.RestartDelay = $service.RestartDelay
        $resource.RebootDelay = $service.RebootDelay
        $resource.Command = $service.FailureProgram
        $resource.RunCommandDelay = $service.RunCommandDelay
        $resource.DisplayName = $service.DisplayName
        $resource.Description = $service.Description
        $resource.UserName = $service.UserName
        $actualUserName = ''
        if( $service.UserName )
        {
            $actualUserName = Resolve-CIdentity -Name $service.UserName -ErrorAction Ignore
            if( $actualUserName )
            {
                $resource.UserName = $actualUserName.FullName
            }
        }
        [string[]]$resource.Dependency = $service.ServicesDependedOn | Select-Object -ExpandProperty Name
        $resource.Ensure = 'Present'
    }
    $resource
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for configuring Windows services.

    .DESCRIPTION
    The `Carbon_Service` resource configures Windows services, including name, credentials, startup type, state, failure actions, and dependencies.

    The service is installed when the `Ensure` property is set to `Present`. If the service already exists, and its configuration doesn't match the properties being set, the service is stopped, its configuration updated, and the service is restarted. Properties not passed are ignored/left as-is.

    In addition to installing the service, this resource also grants the service user the logon as a service privilege and execute permissions on the service executable.

    The service is uninstalled when the `Ensure` property is set to `Absent`. The service is stopped, then uninstalled.

    `Carbon_Service` is new in Carbon 2.0.

    .LINK
    Grant-CPrivilege

    .LINK
    Install-CService

    .LINK
    Uninstall-CService

    .EXAMPLE
    >
    Demonstrates how to install a service that runs as a custom account and has custom failure actions.

        Carbon_Service InstallNoOpService
        {
            Name = 'CarbonNoOpService';
            Path = 'C:\Projects\Carbon\bin\NoOpService.bin';
            StartupType = 'Automatic';
            Credential = $noOpServiceCreential';
            OnFirstFailure = 'RunCommand';
            Command = 'example.exe /fail %1%';
            RunCommandDelay = 1000;
            OnSecondFailure = 'Restart';
            RestartDelay = (1000*60*5); # 5 minutes as milliseconds
        }

    .EXAMPLE
    >
    Demonstrates how to install a service that runs as a built-in account.

        Carbon_Service InstallNoOpService
        {
            Name = 'CarbonNoOpService';
            Path = 'C:\Projects\Carbon\bin\NoOpService.bin';
            StartupType = 'Automatic';
            UserName = 'LocalService';
        }

    .EXAMPLE
    >
    Demonstrates how to remove a service.

        Carbon_Service InstallNoOpService
        {
            Name = 'CarbonNoOpService';
            Ensure = 'Absent';
        }

    .EXAMPLE
    >
    Demonstrates how to set a service's start type `Automatic (Delayed)`. This functionality was added in Carbon 2.5.

        Carbon_Service InstallNoOpService
        {
            Name = 'CarbonNoOpService';
            Path = 'C:\Projects\Carbon\bin\NoOpService.bin';
            StartupType = 'Automatic';
            Delayed = $true;
            Ensure = 'Present';
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name,
        
        [string]
        # The path to the service.
        $Path,
        
        [ValidateSet('Automatic','Manual','Disabled')]
        [string]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        $StartupType,

        [Switch]
        # Used in combination with the `StartupType` parameter to set a service's startup type to `Automatic (Delayed)`.
        #
        # If `Delayed` is true true, and `StartupType` is `Automatic` sets the service's startup type to `Automatic (Delayed)`. 
        #
        # If `Delayed` is false and `StartupType` is `Automatic, sets the service's startup type to `Automatic`.
        #
        # For all other values of `StartupType`, this parameter is ignored.
        #
        # This parameter was added in Carbon 2.5.
        $Delayed,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure,
        
        [Carbon.Service.FailureAction]
        # What to do on the service' third failure.  Default is to take no action.
        $OnThirdFailure,
        
        [int]
        # How many seconds after which the failure count is reset to 0.
        $ResetFailureCount,
        
        [int]
        # How many milliseconds to wait before restarting the service.  Default is 60,0000, or 1 minute.
        $RestartDelay,
        
        [int]
        # How many milliseconds to wait before handling the second failure.  Default is 60,000 or 1 minute.
        $RebootDelay,
        
        [string[]]
        # What other services does this service depend on?
        $Dependency,
        
        [string]
        # The command to run when a service fails, including path to the command and arguments.
        $Command,
        
        [int]
        # How many milliseconds to wait before running the failure command. Default is 0, or immediately.
        $RunCommandDelay,
        
        [string]
        # The service's display names.
        $DisplayName,
        
        [string]
        # The service's description.
        $Description,
        
        [ValidateSet("LocalSystem", "LocalService", "NetworkService")]
        [string]
        # The system account the service should run as.
        $UserName,
        
        [pscredential]
        # The credentials of the custom account the service should run as.
        $Credential,
        
        [string[]]
        # The arguments/startup parameters for the service
        $ArgumentList,

        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $serviceExists = Test-CService -Name $Name
    if( $Ensure -eq 'Absent' )
    {
        if( $serviceExists )
        {
            Write-Verbose ('Removing service ''{0}''' -f $Name)
            Uninstall-CService -Name $Name
        }
        return
    }

    if( -not $Path )
    {
        Write-Error ('Property ''Path'' mandatory when installing/updating a service.')
        return
    }

    if( $UserName -and $Credential )
    {
        Write-Error ('UserName and Credential properties are mutually exclusive. Please provide either Credential or UserName, not both.')
        return
    }

    $PSBoundParameters.Remove('Ensure')
    if( $serviceExists )
    {
        Write-Verbose ('Updating service ''{0}''' -f $Name)
    }
    else
    {
        Write-Verbose ('Installing service ''{0}''' -f $Name)
    }

    Install-CService @PSBoundParameters
}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name,
        
        [string]
        # The path to the service.
        $Path,
        
        [ValidateSet('Automatic','Manual','Disabled')]
        [string]
        # The startup type: automatic, manual, or disabled.  Default is automatic.
        $StartupType,

        [Switch]
        $Delayed,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure,
        
        [Carbon.Service.FailureAction]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure,
        
        [Carbon.Service.FailureAction]
        # What to do on the service' third failure.  Default is to take no action.
        $OnThirdFailure,
        
        [int]
        # How many seconds after which the failure count is reset to 0.
        $ResetFailureCount,
        
        [int]
        # How many milliseconds to wait before restarting the service.  Default is 60,0000, or 1 minute.
        $RestartDelay,
        
        [int]
        # How many milliseconds to wait before handling the second failure.  Default is 60,000 or 1 minute.
        $RebootDelay,
        
        [string[]]
        # What other services does this service depend on?
        $Dependency,
        
        [string]
        # The command to run when a service fails, including path to the command and arguments.
        $Command,
        
        [int]
        # How many milliseconds to wait before running the failure command. Default is 0, or immediately.
        $RunCommandDelay,
        
        [string]
        # The service's display names.
        $DisplayName,
        
        [string]
        # The service's description.
        $Description,
        
        [ValidateSet("LocalSystem", "LocalService", "NetworkService")]
        [string]
        # The system account the service should run as.
        $UserName,
        
        [pscredential]
        # The custom account the service should run as.
        $Credential,
        
        [string[]]
        # The arguments/startup parameters for the service
        $ArgumentList,

        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Name $Name

    if( $Ensure -eq 'Absent' )
    {
        if( $resource.Ensure -eq 'Absent' )
        {
            return $true
        }

        Write-Verbose ('Service ''{0}'' found.' -f $Name)
        return $false
    }

    if( $resource.Ensure -eq 'Absent' )
    {
        Write-Verbose ('Service ''{0}'' not found.' -f $Name)
        return $false
    }

    if( $PSBoundParameters.ContainsKey( 'UserName' ) )
    {
        $identity = Resolve-CIdentity -Name $UserName
        if( $identity )
        {
            $PSBoundParameters['UserName'] = $identity.FullName
        }
    }

    if( $resource.ContainsKey('Credential') )
    {
        [void]$resource.Remove('Credential')
    }

    if( $PSBoundParameters.ContainsKey('Credential') )
    {
        [void]$PSBoundParameters.Remove('Credential')
        $identity = Resolve-CIdentity -Name $Credential.UserName -ErrorAction Ignore
        if( $identity )
        {
            $PSBoundParameters.UserName = $identity.FullName
        }
    }

    return Test-CDscTargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('Service ''{0}''' -f $Name)
}
