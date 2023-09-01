
function Get-CComPermission
{
    <#
    .SYNOPSIS
    Gets the COM Access or Launch and Activation permissions for the current computer.

    .DESCRIPTION
    COM access permissions ared used to "allow default access to application" or "set limits on applications that determine their own permissions".  Launch and Activation permissions are used "who is allowed to launch applications or activate objects" and to "set limits on applications that determine their own permissions."  Usually, these permissions are viewed and edited by opening dcomcnfg, right-clicking My Computer under Component Services > Computers, choosing Properties, going to the COM Security tab, and clicking `Edit Default...` or `Edit Limits...` buttons under the **Access Permissions** or **Launch and Activation Permissions** sections.  This function does all that, but does it much easier, and returns objects you can work with.

    These permissions are stored in the registry, under `HKLM\Software\Microsoft\Ole`.  The default security registry value for Access Permissions is missing/empty until custom permissions are granted.  If this is the case, this function will return objects that represent the default security, which was lovingly reverse engineered by gnomes.

    Returns `Carbon.Security.ComAccessRule` objects, which inherit from `[System.Security.AccessControl.AccessRule](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.accessrule.aspx).

    .LINK
    Grant-CComPermission

    .LINK
    Revoke-CComPermission

    .OUTPUTS
    Carbon.Security.ComAccessRule.

    .EXAMPLE
    Get-CComPermission -Access -Default

    Gets the COM access default security permissions. Look how easy it is!

    .EXAMPLE
    Get-CComPermission -LaunchAndActivation -Identity 'Administrators' -Limits

    Gets the security limits for COM Launch and Activation permissions for the local administrators group.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Security.ComAccessRights])]
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

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

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

    Get-CComSecurityDescriptor @comArgs -AsComAccessRule |
        Where-Object {
            if( $Identity )
            {
                $account = Resolve-CIdentity -Name $Identity -NoWarn
                if( -not $account )
                {
                    return $false
                }
                return ( $_.IdentityReference.Value -eq $account.FullName )
            }

            return $true
        }
}

Set-Alias -Name 'Get-ComPermissions' -Value 'Get-CComPermission'
