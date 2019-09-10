
function Set-CIisWindowsAuthentication
{
    <#
    .SYNOPSIS
    Configures the settings for Windows authentication.

    .DESCRIPTION
    By default, configures Windows authentication on a website.  You can configure Windows authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.
    
    The changes only take effect if Windows authentication is enabled (see `Enable-CIisSecurityAuthentication`).

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx
    
    .LINK
    Disable-CIisSecurityAuthentication
    
    .LINK
    Enable-CIisSecurityAuthentication

    .EXAMPLE
    Set-CIisWindowsAuthentication -SiteName Peanuts

    Configures Windows authentication on the `Peanuts` site to use kernel mode.

    .EXAMPLE
    Set-CIisWindowsAuthentication -SiteName Peanuts -VirtualPath Snoopy/DogHouse -DisableKernelMode

    Configures Windows authentication on the `Doghouse` directory of the `Peanuts` site to not use kernel mode.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where Windows authentication should be set.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path where Windows authentication should be set.
        $VirtualPath = '',
        
        [Switch]
        # Turn on kernel mode.  Default is false.  [More information about Kerndel Mode authentication.](http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx)
        $DisableKernelMode
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $useKernelMode = 'True'
    if( $DisableKernelMode )
    {
        $useKernelMode = 'False'
    }
    
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath -Windows
    $authSettings.SetAttributeValue( 'useKernelMode', $useKernelMode )

    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, "set Windows authentication" ) )
    {
        $authSettings.CommitChanges()
    }
}


