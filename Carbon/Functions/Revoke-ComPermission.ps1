
function Revoke-CComPermission
{
    <#
    .SYNOPSIS
    Revokes COM Access or Launch and Activation permissions.
    
    .DESCRIPTION
    Calling this function is equivalent to opening Component Services (dcomcnfg), right-clicking `My Computer` under Component Services > Computers, choosing `Properties`, going to the `COM Security` tab, and removing an identity from the permissions window that opens after clicking the `Edit Limits...` or `Edit Default...` buttons under `Access Permissions` or `Launch and Activation Permissions` section, 
    
    .LINK
    Get-CComPermission

    .LINK
    Grant-CComPermission
    
    .LINK
    Revoke-CComPermission
    
    .EXAMPLE
    Revoke-CComPermission -Access -Identity 'Users' -Default
    
    Removes all default security COM access permissions for the local `Users` group.

    .EXAMPLE
    Revoke-CComPermission -LaunchAndActivation -Identity 'Users' -Limits
    
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

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

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
    
    $account = Resolve-CIdentity -Name $Identity
    if( -not $account )
    {
        return
    }

    Write-Verbose ("Revoking {0}'s COM {1} {2}." -f $Identity,$permissionsDesc,$typeDesc)
    $currentSD = Get-CComSecurityDescriptor @comArgs

    $newSd = ([wmiclass]'win32_securitydescriptor').CreateInstance()
    $newSd.ControlFlags = $currentSD.ControlFlags
    $newSd.Group = $currentSD.Group
    $newSd.Owner = $currentSD.Owner

    # Remove DACL for this user, if it exists
    $newSd.DACL = $currentSD.DACL | 
                    Where-Object { $_.Trustee.SIDString -ne $account.Sid.Value } | 
                    ForEach-Object { $_.PsObject.BaseObject }

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'
    $sdBytes = $converter.Win32SDToBinarySD( $newSd )

    $regValueName = $pscmdlet.ParameterSetName
    Set-CRegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -Binary $sdBytes.BinarySD
}

Set-Alias -Name 'Revoke-ComPermissions' -Value 'Revoke-CComPermission'

