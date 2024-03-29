
function Get-CComSecurityDescriptor
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
    Get-CComPermission

    .EXAMPLE
    Get-CComSecurityDescriptor -Access -Default

    Gets the default security descriptor for COM Access Permissions.

    .EXAMPLE
    Get-CComSecurityDescriptor -Access -Limits

    Gets the security limits descriptor for COM Access Permissions.

    .EXAMPLE
    Get-CComSecurityDescriptor -LaunchAndActivation -Default

    Gets the default security descriptor for COM Launch and Activation Permissions.

    .EXAMPLE
    Get-CComSecurityDescriptor -LaunchAndActivation -Limits

    Gets the security limits descriptor for COM Launch and Activation Permissions.

    .EXAMPLE
    Get-CComSecurityDescriptor -Access -Default -AsComAccessRule

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

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $regValueName = $pscmdlet.ParameterSetName

    $bytes = Get-CRegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -NoWarn

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

                if( -not $_.Trustee.Domain -and -not $_.Trustee.Name )
                {
                    Write-Debug ('Unresolved trustee: SID: {0}' -f $_.Trustee.SidString)
                    return
                }

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

