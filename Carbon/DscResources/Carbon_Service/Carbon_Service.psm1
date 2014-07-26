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
        [string[]]$resource.Dependency = $service.ServicesDependedOn | Select-Object -ExpandProperty Name
        $resource.Ensure = 'Present'
    }
    $resource
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    Grants/revokes a user or group permission to a file, directory, or registry key.

    .DESCRIPTION

    ## Granting Permission

    Permissions are granted when the `Ensure` property is set to `Present`.
    
    When granting permissions, you *must* supply a value for the `Permission` property. When granting permission to a file or directory, the values for the `Permission` property must be a valid [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx) enumeration value. When granting permission to a registry key, `Permission` must be a valid [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx) enumeration value.
    
    The value of the `ApplyTo` property must be a valid `Carbon.Security.ContainerInheritanceFlags` enumeration value. For a list of values, run `[Enum]::GetValues([Carbon.Security.ContainerInheritanceFlags])`. For help on choosing a proper value, see the help for `Grant-Permission`.

    ## Revoking Permission
        
    Permissions are revoked when the `Ensure` property is set to `Absent`. *All* a user or group's permissions are revoked. You can't revoke part of a user's access. If you want to revoke part of a user's access, set the `Ensure` property to `Present` and the `Permissions` property to the list of properties you want the user to have.

    .LINK
    Grant-Permission

    .LINK
    Revoke-Permission
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions.
        $Identity,
        
        [string[]]
        # The permission: e.g. FullControl, Read, etc. Mandatory when granting permission. For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,
        
        [ValidateSet('Container','SubContainers','ContainerAndSubContainers','Leaves','ContainerAndLeaves','SubContainersAndLeaves','ContainerAndSubContainersAndLeaves','ChildContainers','ContainerAndChildContainers','ChildLeaves','ContainerAndChildLeaves','ChildContainersAndChildLeaves','ContainerAndChildContainersAndChildLeaves')]
        [string]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a file.
        $ApplyTo,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Present','Absent')]
        [string]
        # If set to `Present`, permissions are set. If `Absent`, all permissions to `$Path` removed.
        $Ensure
    )

    Set-StrictMode -Version 'Latest'


    if( $PSBoundParameters.ContainsKey('Ensure') )
    {
        $PSBoundParameters.Remove('Ensure')
    }
    
    if( $Ensure -eq 'Absent' )
    {
        Write-Verbose ('Revoking permission for ''{0}'' to ''{1}''' -f $Identity,$Path)
        Revoke-Permission -Path $Path -Identity $Identity
    }
    else
    {
        if( -not $Permission )
        {
            Write-Error ('Permission parameter is mandatory when granting permissions.')
            return
        }

        Write-Verbose ('Granting permission for ''{0}'' to ''{1}'': {2}' -f $Identity,$Path,($Permission -join ','))
        Grant-Permission @PSBoundParameters
    }
}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,
        
        [ValidateSet('Container','SubContainers','ContainerAndSubContainers','Leaves','ContainerAndLeaves','SubContainersAndLeaves','ContainerAndSubContainersAndLeaves','ChildContainers','ContainerAndChildContainers','ChildLeaves','ContainerAndChildLeaves','ChildContainersAndChildLeaves','ContainerAndChildContainersAndChildLeaves')]
        [string]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo,
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $providerName = Get-PathProvider -Path $Path
    if( -not $providerName )
    {
        Write-Error ('Path ''{0}'' not supported. Only file system and registry paths are allowed.')
        return
    }
    $providerName = $providerName.Name

    $resource = Get-TargetResource -Identity $Identity -Path $Path
    $desiredRights = $Permission -join ','
    $currentRights = $resource.Permission -join ','
    
    if( $Ensure -eq 'Absent' )
    {
        if( $resource.Ensure -eq 'Absent' )
        {
            Write-Verbose ('Identity ''{0}'' has no permission to ''{1}''' -f $Identity,$Path)
            return $true
        }
        
        Write-Verbose ('Identity ''{0}'' has permission to ''{1}'': {2}' -f $Identity,$Path,$currentRights)
        return $false
    }

    if( -not $currentRights )
    {
        Write-Verbose ('Identity ''{0} has no permission to ''{1}''' -f $Identity,$Path,$currentRights)
        return $false
    }

    if( $desiredRights -ne $currentRights )
    {
        Write-Verbose ('Identity ''{0} has stale permission to ''{1}'': {2}' -f $Identity,$Path,$currentRights)
        return $false
    }

    if( $ApplyTo -and $ApplyTo -ne $resource.ApplyTo )
    {
        Write-Verbose ('Identity ''{0}'' has stale inheritance/propagation flags to ''{1}'': {2}' -f $Identity,$Path,$resource.ApplyTo)
        return $false
    }

    return $true
}