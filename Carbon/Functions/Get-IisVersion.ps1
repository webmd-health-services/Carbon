
function Get-CIisVersion
{
    <#
    .SYNOPSIS
    Gets the version of IIS.
    
    .DESCRIPTION
    Reads the version of IIS from the registry, and returns it as a `Major.Minor` formatted string.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Get-CIisVersion
    
    Returns `7.0` on Windows 2008, and `7.5` on Windows 7 and Windows 2008 R2.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $props = Get-ItemProperty hklm:\Software\Microsoft\InetStp
    return $props.MajorVersion.ToString() + "." + $props.MinorVersion.ToString()
}

