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

function Grant-ComPermission
{
    <#
    .SYNOPSIS
    Grants COM access permissions.
    
    .DESCRIPTION
    Calling this function is equivalent to opening Component Services (dcomcnfg), right-clicking `My Computer` under Component Services > Computers, choosing `Properties`, going to the `COM Security` tab, and modifying the permission after clicking the `Edit Limits...` or `Edit Default...` buttons under the `Access Permissions` section.
    
    You must set at least one of the `LocalAccess` or `RemoteAccess` switches.
    
    .LINK
    Get-ComPermission

    .LINK
    Revoke-ComPermission
    
    .EXAMPLE
    Grant-ComPermission -Access -Identity 'Users' -Allow -Default -Local
    
    Updates access permission default security to allow the local `Users` group local access permissions.

    .EXAMPLE
    Grant-ComPermission -LaunchAndActivation -Identity 'Users' -Limits -Deny -Local -Remote
    
    Updates access permission security limits to deny the local `Users` group local and remote access permissions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]        
        $Identity,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # Grants Access Permissions.
        $Access,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # Grants Launch and Activation Permissions.
        $LaunchAndActivation,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionDeny')]
        [Switch]
        # Grants default security permissions.
        $Default,
        
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # Grants security limits permissions.
        $Limits,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionAllow')]
        [Switch]
        # If set, allows the given permissions.
        $Allow,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestrictionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, denies the given permissions.
        $Deny,
                
        [Parameter(ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # If set, grants local access permissions.  Only valid if `Access` switch is set.
        $Local,
        
        [Parameter(ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # If set, grants remote access permissions.  Only valid if `Access` switch is set.
        $Remote,

        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants local launch permissions.  Only valid if `LaunchAndActivation` switch is set.
        $LocalLaunch,
        
        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants remote launch permissions.  Only valid if `LaunchAndActivation` switch is set.
        $RemoteLaunch,

        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants local activation permissions.  Only valid if `LaunchAndActivation` switch is set.
        $LocalActivation,
        
        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants remote activation permissions.  Only valid if `LaunchAndActivation` switch is set.
        $RemoteActivation
    )
    
    $sid = Test-Identity -Name $Identity -PassThru
    if( -not $sid )
    {
        Write-Error ("Identity {0} not found." -f $Identity)
    }

    $comArgs = @{ }
    if( $pscmdlet.ParameterSetName -like 'Default*' )
    {
        $typeDesc = 'default security permissions'
        $comArgs.Default = $true
    }
    else
    {
        $typeDesc = 'security limits'
        $comArgs.Limits = $true
    }
    
    if( $pscmdlet.ParameterSetName -like '*Access*' )
    {
        $permissionsDesc = 'Access'
        $comArgs.Access = $true
    }
    else
    {
        $permissionsDesc = 'Launch and Activation'
        $comArgs.LaunchAndActivation = $true
    }
    
    $currentSD = Get-ComSecurityDescriptor @comArgs

    $newSd = ([wmiclass]'win32_securitydescriptor').CreateInstance()
    $newSd.ControlFlags = $currentSD.ControlFlags
    $newSd.Group = $currentSD.Group
    $newSd.Owner = $currentSD.Owner

    $trustee = ([wmiclass]'win32_trustee').CreateInstance()
    $trustee.SIDString = $sid.Value

    $ace = ([wmiclass]'win32_ace').CreateInstance()
    $accessMask = [Carbon.Security.ComAccessRights]::Execute
    if( $Local -or $LocalLaunch )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ExecuteLocal
    }
    if( $Remote -or $RemoteLaunch )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ExecuteRemote
    }
    if( $LocalActivation )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ActivateLocal
    }
    if( $RemoteActivation )
    {
        $accessMask = $accessMask -bor [Carbon.Security.ComAccessRights]::ActivateRemote
    }
    
    Write-Verbose ("Granting {0} {1} COM {2} {3}." -f $Identity,([Carbon.Security.ComAccessRights]$accessMask),$permissionsDesc,$typeDesc)

    $ace.AccessMask = $accessMask
    $ace.Trustee = $trustee

    # Remove DACL for this user, if it exists, so we can replace it.
    $newDacl = $currentSD.DACL | 
                    Where-Object { $_.Trustee.SIDString -ne $trustee.SIDString } | 
                    ForEach-Object { $_.PsObject.BaseObject }
    $newDacl += $ace.PsObject.BaseObject
    $newSd.DACL = $newDacl

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'
    $sdBytes = $converter.Win32SDToBinarySD( $newSd )

    $regValueName = $pscmdlet.ParameterSetName -replace '(Allow|Deny)$',''
    Set-RegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -Binary $sdBytes.BinarySD -Quiet
}

Set-Alias -Name 'Grant-ComPermissions' -Value 'Grant-ComPermission'