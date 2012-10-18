
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
    
    This information is stored in the registry, at `HKLM\Software\Microsoft\Ole@DefaultAccessPermission`.  If custom access permissions have never been granted, this registry key will be missing/empty.  In this situation, it will return objects that represent the default access permissions. These permissions were reverse-engineered from Windows 2008 and 7 computers by adding then removing a user so that the operating system creates and sets this key.  The default value of the key was then converted to an SDDL descriptor, and that descriptor is used to return the default set of permissions.  If anyone knows a way to get this default access permissions without hard-coding something, please let us know!
    
    Returns a `Carbon.Security.ComAccessRule` object, which inherits from `[System.Security.AccessControl.AccessRule](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.accessrule.aspx).
    
    .OUTPUTS
    Carbon.Security.ComAccessRule.
     
    .EXAMPLE
    Get-ComAccessPermissions
    
    Look how easy it is!

    .EXAMPLE
    Get-ComAccessPermissions -Identity 'Administrators'
    
    Gets the COM access rules for the local administrators group.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The identity whose access rule to return.  If not set, all access rules are returned.
        $Identity
    )

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'

    $bytes = Get-RegistryKeyValue -Path 'hklm:\software\microsoft\ole' -Name 'DefaultAccessPermission'
    $convertArgs = @{ }
    if( -not $bytes )
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
    DCOM launch and activation permissions are used to allow default access to applications.  Usually, these permissions are viewed and edited by opening dcomcnfg, right-clicking My Computer under Component Services > Computers, choosing Properties, going to the COM Security tab, and clicking `Edit Default...`.  This function does all that, but does it much easier.

    Returns a `Carbon.Security.ComAccessRule` object, which inherits from `[System.Security.AccessControl.AccessRule](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.accessrule.aspx).
    
    .OUTPUTS
    Carbon.Security.ComAccessRule.
          
    .EXAMPLE
    Get-ComLaunchAndActivationPermissions
    
    Look how easy it is!
    
    .EXAMPLE
    Get-ComLaunchAndActivationPermissions -Identity 'Administrators'
    
    Gets the COM Launch and Activation access rules for the local administrators group.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The identity whose access rule to return.  If not set, all access rules are returned.
        $Identity
    )
    
    $bytes = Get-RegistryKeyValue -Path 'hklm:\software\microsoft\ole' -Name 'DefaultLaunchPermission'
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