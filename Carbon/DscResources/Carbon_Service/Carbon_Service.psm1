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
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
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
        # The user the service should run as.
        $Username,
        
        [string]
        # The user's password.
        $Password,
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $resource = @{
                    Name = $Name;
                    Path = $null;
                    StartupType = $null;
                    OnFirstFailure = $null;
                    OnSecondFailure = $null;
                    OnThirdFailure = $null;
                    ResetFailureCount = $null;
                    RestartDelay = $null;
                    RebootDelay = $null;
                    Dependency = $null;
                    Username = $null;
                    Password = $null;
                    Ensure = 'Absent';
                }

    if( Test-Service -Name $Name )
    {
        $service = Get-Service -Name $Name
        $resource.Path = $service.Path
        $resource.StartupType = $service.StartMode
        $resource.OnFirstFailure = $service.FirstFailure
        $resource.OnSecondFailure = $service.SecondFailure
        $resource.OnThirdFailure = $service.ThirdFailure
        $resource.ResetFailureCount = $service.ResetPeriod
        $resource.RestartDelay = $service.RestartDelay
        $resource.RebootDelay = $service.RebootDelay
        $resource.UserName = $service.UserName
        $actualUserName = Resolve-Identity -Name $service.UserName -ErrorAction Ignore
        if( $actualUserName )
        {
            $resource.UserName = $actualUserName.FullName
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
    Install/uninstalls a Windows service.

    .DESCRIPTION

    The service is installed when the `Ensure` property is set to `Present`. If the service already exists, and its configuration doesn't match the properties being set, the service is stopped, its configuration updated, and the service is restarted. Properties not passed are ignored/left as-is.

    In addition to installing the service, this resource also grants the service user the logon as a service privilege and execute permissions on the service executable.

    The service is uninstalled when the `Ensure` property is set to `Absent`. The service is stopped, then uninstalled.

    .LINK
    Install-Service

    .LINK
    Uninstall-Service
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
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
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
        # The user the service should run as.
        $Username,
        
        [string]
        # The user's password.
        $Password,
     
        [Parameter(Mandatory=$true)]   
        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $serviceExists = Test-Service -Name $Name
    if( $Ensure -eq 'Absent' )
    {
        if( $serviceExists )
        {
            Write-Verbose ('Removing service ''{0}''' -f $Name)
            Uninstall-Service -Name $Name
        }
        return
    }

    if( -not $Path )
    {
        Write-Error ('Property ''Path'' mandatory when installing/updating a service.')
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
    Install-Service @PSBoundParameters
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
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's first failure.  Default is to take no action.
        $OnFirstFailure,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
        # What to do on the service's second failure. Default is to take no action.
        $OnSecondFailure,
        
        [string]
        [ValidateSet("Reboot","Restart","TakeNoAction")]
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
        # The user the service should run as.
        $Username,
        
        [string]
        # The user's password.
        $Password,
     
        [Parameter(Mandatory=$true)]   
        [ValidateSet('Present','Absent')]
        [string]
        # If `Present`, the service is installed/updated. If `Absent`, the service is removed.
        $Ensure
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
        $identity = Resolve-Identity -Name $Username
        if( $identity )
        {
            $PSBoundParameters['UserName'] = $identity.FullName
        }
    }

    if( $resource.ContainsKey('Password') )
    {
        $resource.Remove('Password')
    }

    return Test-DscTargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('Service ''{0}''' -f $Name)
}