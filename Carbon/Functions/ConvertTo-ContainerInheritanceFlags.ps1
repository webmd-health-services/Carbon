
function ConvertTo-CContainerInheritanceFlags
{
    <#
    .SYNOPSIS
    Converts a combination of InheritanceFlags Propagation Flags into a Carbon.Security.ContainerInheritanceFlags enumeration value.

    .DESCRIPTION
    `Grant-CPermission`, `Test-CPermission`, and `Get-CPermission` all take an `ApplyTo` parameter, which is a `Carbon.Security.ContainerInheritanceFlags` enumeration value. This enumeration is then converted to the appropriate `System.Security.AccessControl.InheritanceFlags` and `System.Security.AccessControl.PropagationFlags` values for getting/granting/testing permissions. If you prefer to speak in terms of `InheritanceFlags` and `PropagationFlags`, use this function to convert them to a `ContainerInheritanceFlags` value.

    If your combination doesn't result in a valid combination, `$null` is returned.

    For detailed description of inheritance and propagation flags, see the help for `Grant-CPermission`.

    .OUTPUTS
    Carbon.Security.ContainerInheritanceFlags.

    .LINK
    Grant-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    ConvertTo-CContainerInheritanceFlags -InheritanceFlags 'ContainerInherit' -PropagationFlags 'None'

    Demonstrates how to convert `InheritanceFlags` and `PropagationFlags` enumeration values into a `ContainerInheritanceFlags`. In this case, `[Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainers` is returned.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Security.ContainerInheritanceFlags])]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Security.AccessControl.InheritanceFlags]
        # The inheritance flags to convert.
        $InheritanceFlags,

        [Parameter(Mandatory=$true,Position=1)]
        [Security.AccessControl.PropagationFlags]
        # The propagation flags to convert.
        $PropagationFlags
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $propFlagsNone = $PropagationFlags -eq [Security.AccessControl.PropagationFlags]::None
    $propFlagsInheritOnly = $PropagationFlags -eq [Security.AccessControl.PropagationFlags]::InheritOnly
    $propFlagsInheritOnlyNoPropagate = $PropagationFlags -eq ([Security.AccessControl.PropagationFlags]::InheritOnly -bor [Security.AccessControl.PropagationFlags]::NoPropagateInherit)
    $propFlagsNoPropagate = $PropagationFlags -eq [Security.AccessControl.PropagationFlags]::NoPropagateInherit

    if( $InheritanceFlags -eq [Security.AccessControl.InheritanceFlags]::None )
    {
        return [Carbon.Security.ContainerInheritanceFlags]::Container
    }
    elseif( $InheritanceFlags -eq [Security.AccessControl.InheritanceFlags]::ContainerInherit )
    {
        if( $propFlagsInheritOnly )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::SubContainers
        }
        elseif( $propFlagsInheritOnlyNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ChildContainers
        }
        elseif( $propFlagsNone )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainers
        }
        elseif( $propFlagsNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndChildContainers
        }
    }
    elseif( $InheritanceFlags -eq [Security.AccessControl.InheritanceFlags]::ObjectInherit )
    {
        if( $propFlagsInheritOnly )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::Leaves
        }
        elseif( $propFlagsInheritOnlyNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ChildLeaves
        }
        elseif( $propFlagsNone )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndLeaves
        }
        elseif( $propFlagsNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndChildLeaves
        }
    }
    elseif( $InheritanceFlags -eq ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit ) )
    {
        if( $propFlagsInheritOnly )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::SubContainersAndLeaves
        }
        elseif( $propFlagsInheritOnlyNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ChildContainersAndChildLeaves
        }
        elseif( $propFlagsNone )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainersAndLeaves
        }
        elseif( $propFlagsNoPropagate )
        {
            return [Carbon.Security.ContainerInheritanceFlags]::ContainerAndChildContainersAndChildLeaves
        }
    }
}
