
function Test-CWindowsFeature
{
    <#
    .SYNOPSIS
    Tests if an optional Windows component exists and, optionally, if it is installed.

    .DESCRIPTION
    Feature names are different across different versions of Windows.  This function tests if a given feature exists.  You can also test if a feature is installed by setting the `Installed` switch.

    Feature names are case-sensitive and are different between different versions of Windows.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.  On Windows 8/2012, use `Get-CWindowsFeature`.

    .LINK
    Get-CWindowsFeature
    
    .LINK
    Install-CWindowsFeature
    
    .LINK
    Uninstall-CWindowsFeature
    
    .EXAMPLE
    Test-CWindowsFeature -Name MSMQ-Server

    Tests if the MSMQ-Server feature exists on the current computer.

    .EXAMPLE
    Test-CWindowsFeature -Name IIS-WebServer -Installed

    Tests if the IIS-WebServer features exists and is installed/enabled.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the feature to test.  Feature names are case-sensitive and are different between different versions of Windows.  For a list, on Windows 2008, run `serveramanagercmd.exe -q`; on Windows 7, run `Get-WmiObject -Class Win32_OptionalFeature | Select-Object Name`.  On Windows 8/2012, use `Get-CWindowsFeature`.
        $Name,
        
        [Switch]
        # Test if the service is installed in addition to if it exists.
        $Installed
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name

    if( -not (Get-Module -Name 'ServerManager') -and -not (Assert-WindowsFeatureFunctionsSupported) )
    {
        return
    }
    
    $feature = Get-CWindowsFeature -Name $Name 
    
    if( $feature )
    {
        if( $Installed )
        {
            return $feature.Installed
        }
        return $true
    }
    else
    {
        return $false
    }
}

