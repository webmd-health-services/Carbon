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
    Get-ServicePermission
    
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

