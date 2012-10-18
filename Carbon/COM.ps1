
function ConvertTo-ComAccessRule
{
    <#
    .SYNOPSIS
    Converts various forms of a security descriptor into a `ComAccessRule` object.
    
    .DESCRIPTION
    The COM security descriptor can be in binary form (an array of bytes) or an SDDL descriptor.
    
    .OUTPUTS
    Carbon.Security.ComAccessRule
    
    .EXAMPLE
    ConvertTo-ComAccessRule -BinarySD $sdBytes
    
    Converts the array of bytes `sdBytes` into a `ComAccessRule` object.

    .EXAMPLE
    ConvertTo-ComAccessRule -SDDL ''O:BAG:BAD:(A;;CCDCLC;;;PS)'
    
    Converts an SDDL descriptor into a `ComAccessRule` object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByBinarySD')]
        [byte[]]
        # The security descriptor to convert.
        $BinarySD,
        
        [Parameter(Mandatory=$true,ParameterSetName='BySDDL')]
        [string]
        # The security descriptor to convert.
        $SDDL
    )
    
    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'

    switch( $pscmdlet.ParameterSetName )
    {
        'ByBinarySD'
        {
            $sd = $converter.BinarySDToWin32SD( $bytes )
        }
        
        'BySDDL'
        {
            $sd = $converter.SDDLToWin32SD( $SDDL )
        }
        
        default
        {
            Write-Error "Unknown parameter set $_."
            return
        }
    }
    
    $sd |
        Select-Object -ExpandProperty Descriptor | 
        Select-Object -expandproperty DACL | 
        ForEach-Object {
            
            $identity = New-Object Security.Principal.NTAccount $_.Trustee.Domain,$_.Trustee.Name
            $rights = [Carbon.Security.ComAccessRights]$_.AccessMask
            $controlType = [Security.AccessControl.AccessControlType]$_.AceType

            New-Object Carbon.Security.ComAccessRule $identity,$rights,$controlType
        }
    
}

function Get-ComAccessPermissions
{
    <#
    .SYNOPSIS
    Gets the COM access permissions for the current computer.
    
    .DESCRIPTION
    COM access permissions are used to allow default access to applications.  Usually, these permissions are viewed and edited by opening dcomcnfg, right-clicking My Computer under Component Services > Computers, choosing Properties, going to the COM Security tab, and clicking `Edit Default...`.  This function does all that, but does it much easier.
    
    This information is stored in the registry, under `HKLM\Software\Microsoft\Ole`.  The registry value for default security is missing/empty until custom permissions are granted.  If this is the case, this function will return objects that represent the default security, which was lovingly reverse engineered by gnomes.
    
    Returns `Carbon.Security.ComAccessRule` objects, which inherit from `[System.Security.AccessControl.AccessRule](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.accessrule.aspx).
    
    .OUTPUTS
    Carbon.Security.ComAccessRule.
     
    .EXAMPLE
    Get-ComAccessPermissions -Scope 'Default'
    
    Gets the COM access default security permissions. Look how easy it is!

    .EXAMPLE
    Get-ComAccessPermissions -Scope 'Limits' -Identity 'Administrators'
    
    Gets the COM access security limit permissions for the local administrators group. This is equivalent to clicking the `Edit Limits...` button under `Access Permissions` on the COM Security tab of the My Computer Properties window of Component Services snap-in (dcomcnfg).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Default','Limits')]
        # Whether to return the default security or the security limits.  Must be one of `Default` or `Limits`.
        $Scope,
        
        [string]
        # The identity whose access rule to return.  If not set, all access rules are returned.
        $Identity
    )

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'

    $regValueName = 'DefaultAccessPermission'
    if( $Scope -eq 'Limits' )
    {
        $regValueName = 'MachineAccessRestriction'
    }
    $bytes = Get-RegistryKeyValue -Path 'hklm:\software\microsoft\ole' -Name $regValueName
    $convertArgs = @{ }
    if( -not $bytes -and $Scope -eq 'Default')
    {
        Write-Warning "DCOM Default Access Permission not found. Using reverse-engineered, hard-coded default access permissions."

        # If no custom access permissions have been granted, then the DefaultAccessPermission registry value doesn't exist.
        # This is the SDDL for the default permissions used on Windows 2008 and Windows 7.
        $DEFAULT_SDDL = 'O:BAG:BAD:(A;;CCDCLC;;;PS)(A;;CCDC;;;SY)(A;;CCDCLC;;;BA)'
        $convertArgs.SDDL = $DEFAULT_SDDL
    }
    else
    {
        $convertArgs.BinarySD = $bytes
    }
    
    ConvertTo-ComAccessRule @convertArgs |
        Select-ComAccessRule -Identity $Identity
}

function Get-ComLaunchAndActivationPermissions
{
    <#
    .SYNOPSIS
    Gets the COM Launch and Activation permissions for the current computer.
    
    .DESCRIPTION
    COM launch and activation permissions are used to allow default access to applications.  Usually, these permissions are viewed and edited by opening dcomcnfg, right-clicking My Computer under Component Services > Computers, choosing Properties, going to the COM Security tab, and clicking the buttons under `Launch and Activation Permissions`.  This function does all that, but does it much easier.

    Returns `Carbon.Security.ComAccessRule` objects, which inherit from `[System.Security.AccessControl.AccessRule](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.accessrule.aspx).
    
    .OUTPUTS
    Carbon.Security.ComAccessRule.
          
    .EXAMPLE
    Get-ComLaunchAndActivationPermissions -Scope 'Default'
    
    Look how easy it is!  Gets the launch and activation default security.
    
    .EXAMPLE
    Get-ComLaunchAndActivationPermissions -Scope 'Limits' -Identity 'Administrators'
    
    Gets the COM Launch and Activation security limits for the local administrators group. This is equivalent to clicking the `Edit Limits...` button under `Launch and Activation Permissions` on the COM Security tab of the My Computer Properties window of Component Services snap-in (dcomcnfg).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Default','Limits')]
        # Whether to return the default or limits permissions.  Must be one of `Default` or `Limits`.
        $Scope,
        
        [string]
        # The identity whose access rule to return.  If not set, all access rules are returned.
        $Identity
    )
    
    $regValueName = 'DefaultLaunchPermission'
    if( $Scope -eq 'Limits' )
    {
        $regValueName = 'MachineLaunchRestriction'
    }
    
    $bytes = Get-RegistryKeyValue -Path 'hklm:\software\microsoft\ole' -Name $regValueName
    if( -not $bytes )
    {
        Write-Warning "COM Default Launch and Activation Permission not found."
        return
    }
    ConvertTo-ComAccessRule -BinarySD $bytes |
        Select-ComAccessRule -Identity $Identity
}

filter Select-ComAccessRule
{
    <#
    .SYNOPSIS
    Returns COM access rules from a pipeline that match specific criteria.
    
    .DESCRIPTION
    Its sometimes useful to filter a set of COM access rules by certain criteria.
    
    If not criteria are given, all access rules are returned.
    
    .EXAMPLE
    Get-ComLaunchAndActivationPermissions | Select-ComAccessRule -Identity 'Administators
    
    Selects the COM access rule for the local `Administrators` group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Carbon.Security.ComAccessRule]
        # The access rule to filter.
        $InputObject,
        
        [string]
        # Select COM Access Rules that belong to this identity.
        $Identity
    )
    
    if( $Identity )
    {
        $cIdentity = Resolve-IdentityName -Name $Identity
        if( $InputObject.IdentityReference.Value -eq $cIdentity )
        {
            return $InputObject
        }
        return
    }
    
    return $InputObject
}