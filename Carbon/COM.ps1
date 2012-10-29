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

$ComRegKeyPath = 'hklm:\software\microsoft\ole'

function Get-ComSecurityDescriptor
{
    <#
    .SYNOPSIS
    Gets a WMI Win32_SecurityDescriptor default security or security limits object for COM Access or Launch and Activation permissions.
    
    .DESCRIPTION
    There are four available security descriptors.  Default security and security limits for Access Permissions and Launch and Activation Permissions.  This method returns a Win32_SecurityDescriptor for the given area and security type.

    The `AsComAccessRule` parameter will return a `Carbon.Security.ComAccessRule` object for each of the access control entries in the security descriptor's ACL.
        
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa394402.aspx
    
    .LINK
    Get-ComPermissions
    
    .EXAMPLE
    Get-ComSecurityDescriptor -Access -Default
    
    Gets the default security descriptor for COM Access Permissions.
    
    .EXAMPLE
    Get-ComSecurityDescriptor -Access -Limits
    
    Gets the security limits descriptor for COM Access Permissions.
    
    .EXAMPLE
    Get-ComSecurityDescriptor -LaunchAndActivation -Default
    
    Gets the default security descriptor for COM Launch and Activation Permissions.
    
    .EXAMPLE
    Get-ComSecurityDescriptor -LaunchAndActivation -Limits
    
    Gets the security limits descriptor for COM Launch and Activation Permissions.

    .EXAMPLE
    Get-ComSecurityDescriptor -Access -Default -AsComAccessRule
    
    Returns a `Carbon.Security.ComAccessRule` object for each of the access control entries in the Access Permissions's default security descriptor.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Switch]
        # Returns a securty descriptor for one of the Access Permissions security types.
        $Access,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        # Returns a security descriptor for one of the Launch and Activation Permissions security types.
        $LaunchAndActivation,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Switch]
        # Returns the default security descriptor.
        $Default,
        
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        # Returns the security limits descriptor.
        $Limits,
        
        [Switch]
        # Returns `Carbon.Security.ComAccessRule` objects instead of a security descriptor.
        $AsComAccessRule
    )
    
    $regValueName = $pscmdlet.ParameterSetName
    
    $bytes = Get-RegistryKeyValue -Path $ComRegKeyPath -Name $regValueName
    
    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'

    if( -not $bytes -and $pscmdlet.ParameterSetName -eq 'DefaultAccessPermission')
    {
        Write-Warning "COM Default Access Permission not found. Using reverse-engineered, hard-coded default access permissions."

        # If no custom access permissions have been granted, then the DefaultAccessPermission registry value doesn't exist.
        # This is the SDDL for the default permissions used on Windows 2008 and Windows 7.
        $DEFAULT_SDDL = 'O:BAG:BAD:(A;;CCDCLC;;;PS)(A;;CCDC;;;SY)(A;;CCDCLC;;;BA)'
        $sd = $converter.SDDLToWin32SD( $DEFAULT_SDDL )
    }
    else
    {
        $sd = $converter.BinarySDToWin32SD( $bytes )
    }
    
    if( $AsComAccessRule )
    {
        $sd.Descriptor.DACL | 
            ForEach-Object {
                
                $identity = New-Object Security.Principal.NTAccount $_.Trustee.Domain,$_.Trustee.Name
                $rights = [Carbon.Security.ComAccessRights]$_.AccessMask
                $controlType = [Security.AccessControl.AccessControlType]$_.AceType

                New-Object Carbon.Security.ComAccessRule $identity,$rights,$controlType
            }
    }
    else
    {
        $sd.Descriptor
    }
}

function Get-ComPermissions
{
    <#
    .SYNOPSIS
    Gets the COM Access or Launch and Activation permissions for the current computer.
    
    .DESCRIPTION
    COM access permissions ared used to "allow default access to application" or "set limits on applications that determine their own permissions".  Launch and Activation permissions are used "who is allowed to launch applications or activate objects" and to "set limits on applications that determine their own permissions."  Usually, these permissions are viewed and edited by opening dcomcnfg, right-clicking My Computer under Component Services > Computers, choosing Properties, going to the COM Security tab, and clicking `Edit Default...` or `Edit Limits...` buttons under the **Access Permissions** or **Launch and Activation Permissions** sections.  This function does all that, but does it much easier, and returns objects you can work with.
    
    These permissions are stored in the registry, under `HKLM\Software\Microsoft\Ole`.  The default security registry value for Access Permissions is missing/empty until custom permissions are granted.  If this is the case, this function will return objects that represent the default security, which was lovingly reverse engineered by gnomes.
    
    Returns `Carbon.Security.ComAccessRule` objects, which inherit from `[System.Security.AccessControl.AccessRule](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.accessrule.aspx).
    
    .LINK
    Grant-ComPermissions

    .LINK
    Revoke-ComPermissions
    
    .OUTPUTS
    Carbon.Security.ComAccessRule.
     
    .EXAMPLE
    Get-ComPermissions -Access -Default
    
    Gets the COM access default security permissions. Look how easy it is!

    .EXAMPLE
    Get-ComPermissions -LaunchAndActivation -Identity 'Administrators' -Limits
    
    Gets the security limits for COM Launch and Activation permissions for the local administrators group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Switch]
        # If set, returns permissions for COM Access permissions.
        $Access,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        # If set, returns permissions for COM Access permissions.
        $LaunchAndActivation,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Switch]
        # Gets default security permissions.
        $Default,
        
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        # Gets security limit permissions.
        $Limits,
        
        [string]
        # The identity whose access rule to return.  If not set, all access rules are returned.
        $Identity        
    )
    
    $comArgs = @{ }
    if( $pscmdlet.ParameterSetName -like 'Default*' )
    {
        $comArgs.Default = $true
    }
    else
    {
        $comArgs.Limits = $true
    }
    
    if( $pscmdlet.ParameterSetName -like '*Access*' )
    {
        $comArgs.Access = $true
    }
    else
    {
        $comArgs.LaunchAndActivation = $true
    }
    
    Get-ComSecurityDescriptor @comArgs -AsComAccessRule |
        Where-Object {
            if( $Identity )
            {
                $rIdentity = Resolve-IdentityName -Name $Identity
                return ( $_.IdentityReference.Value -eq $rIdentity )
            }
            
            return $true
        }
}

function Grant-ComPermissions
{
    <#
    .SYNOPSIS
    Grants COM access permissions.
    
    .DESCRIPTION
    Calling this function is equivalent to opening Component Services (dcomcnfg), right-clicking `My Computer` under Component Services > Computers, choosing `Properties`, going to the `COM Security` tab, and modifying the permission after clicking the `Edit Limits...` or `Edit Default...` buttons under the `Access Permissions` section.
    
    You must set at least one of the `LocalAccess` or `RemoteAccess` switches.
    
    .LINK
    Get-ComPermissions

    .LINK
    Revoke-ComPermissions
    
    .EXAMPLE
    Grant-ComPermissions -Access -Identity 'Users' -Allow -Default -Local
    
    Updates access permission default security to allow the local `Users` group local access permissions.

    .EXAMPLE
    Grant-ComPermissions -LaunchAndActivation -Identity 'Users' -Limits -Deny -Local -Remote
    
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
        # If set, grants local access permissions.
        $Local,
        
        [Parameter(ParameterSetName='DefaultAccessPermissionAllow')]
        [Parameter(ParameterSetName='MachineAccessRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultAccessPermissionDeny')]
        [Parameter(ParameterSetName='MachineAccessRestrictionDeny')]
        [Switch]
        # If set, grants remote access permissions.
        $Remote,

        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants local access permissions.
        $LocalLaunch,
        
        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants remote access permissions.
        $RemoteLaunch,

        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants local access permissions.
        $LocalActivation,
        
        [Parameter(ParameterSetName='DefaultLaunchPermissionAllow')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionAllow')]
        [Parameter(ParameterSetName='DefaultLaunchPermissionDeny')]
        [Parameter(ParameterSetName='MachineLaunchRestrictionDeny')]
        [Switch]
        # If set, grants remote access permissions.
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
    
    Write-Host ("Granting {0} {1} {2} {3}." -f $Identity,([Carbon.Security.ComAccessRights]$accessMask),$permissionsDesc,$typeDesc)

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

function Revoke-ComPermissions
{
    <#
    .SYNOPSIS
    Revokes COM Access or Launch and Activation permissions.
    
    .DESCRIPTION
    Calling this function is equivalent to opening Component Services (dcomcnfg), right-clicking `My Computer` under Component Services > Computers, choosing `Properties`, going to the `COM Security` tab, and removing an identity from the permissions window that opens after clicking the `Edit Limits...` or `Edit Default...` buttons under `Access Permissions` or `Launch and Activation Permissions` section, 
    
    .LINK
    Get-ComPermissions

    .LINK
    Grant-ComPermissions
    
    .LINK
    Revoke-ComPermissions
    
    .EXAMPLE
    Revoke-ComPermissions -Access -Identity 'Users' -Default
    
    Removes all default security COM access permissions for the local `Users` group.

    .EXAMPLE
    Revoke-ComPermissions -LaunchAndActivation -Identity 'Users' -Limits
    
    Removes all security limit COM access permissions for the local `Users` group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]        
        $Identity,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Switch]
        # Revokes Access Permissions.
        $Access,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        # Revokes Launch and Activation Permissions.
        $LaunchAndActivation,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Switch]
        # Revokes default security permissions.
        $Default,
        
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        # Revokes security limits permissions.
        $Limits
    )
    
    $comArgs = @{ }
    if( $pscmdlet.ParameterSetName -like 'Default*' )
    {
        $typeDesc = 'default security'
        $comArgs.Default = $true
    }
    else
    {
        $typeDesc = 'security limit'
        $comArgs.Limits = $true
    }
    
    if( $pscmdlet.ParameterSetName -like '*Access*' )
    {
        $permissionsDesc = 'Access'
        $comArgs.Access = $true
    }
    else
    {
        $permissionsDesc = 'Launch and Activiation'
        $comArgs.LaunchAndActivation = $true
    }
    
    $sidAccount = Test-Identity -Name $Identity -PassThru
    if( -not $sidAccount )
    {
        Write-Warning "Unable to find identity $Identity."
        return
    }

    Write-Host ("Revoking {0}'s {1} {2} Permissions." -f $Identity,$typeDesc,$permissionsDesc)
    $currentSD = Get-ComSecurityDescriptor @comArgs

    $newSd = ([wmiclass]'win32_securitydescriptor').CreateInstance()
    $newSd.ControlFlags = $currentSD.ControlFlags
    $newSd.Group = $currentSD.Group
    $newSd.Owner = $currentSD.Owner

    # Remove DACL for this user, if it exists
    $newSd.DACL = $currentSD.DACL | 
                    Where-Object { $_.Trustee.SIDString -ne $sidAccount.Value } | 
                    ForEach-Object { $_.PsObject.BaseObject }

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'
    $sdBytes = $converter.Win32SDToBinarySD( $newSd )

    $regValueName = $pscmdlet.ParameterSetName
    Set-RegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -Binary $sdBytes.BinarySD -Quiet
}
