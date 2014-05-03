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

function Revoke-ComPermission
{
    <#
    .SYNOPSIS
    Revokes COM Access or Launch and Activation permissions.
    
    .DESCRIPTION
    Calling this function is equivalent to opening Component Services (dcomcnfg), right-clicking `My Computer` under Component Services > Computers, choosing `Properties`, going to the `COM Security` tab, and removing an identity from the permissions window that opens after clicking the `Edit Limits...` or `Edit Default...` buttons under `Access Permissions` or `Launch and Activation Permissions` section, 
    
    .LINK
    Get-ComPermission

    .LINK
    Grant-ComPermission
    
    .LINK
    Revoke-ComPermission
    
    .EXAMPLE
    Revoke-ComPermission -Access -Identity 'Users' -Default
    
    Removes all default security COM access permissions for the local `Users` group.

    .EXAMPLE
    Revoke-ComPermission -LaunchAndActivation -Identity 'Users' -Limits
    
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
    
    Set-StrictMode -Version 'Latest'

    $commonParams = @{
                        Verbose = $VerbosePreference;
                        ErrorAction = $ErrorActionPreference;
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
        $permissionsDesc = 'Launch and Activiation'
        $comArgs.LaunchAndActivation = $true
    }
    
    $sidAccount = Test-Identity -Name $Identity -PassThru @commonParams
    if( -not $sidAccount )
    {
        Write-Warning "Unable to find identity $Identity."
        return
    }

    Write-Verbose ("Revoking {0}'s COM {1} {2}." -f $Identity,$permissionsDesc,$typeDesc)
    $currentSD = Get-ComSecurityDescriptor @comArgs @commonParams

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
    Set-RegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -Binary $sdBytes.BinarySD -Quiet @commonParams -WhatIf:$WhatIfPreference
}

Set-Alias -Name 'Revoke-ComPermissions' -Value 'Revoke-ComPermission'
