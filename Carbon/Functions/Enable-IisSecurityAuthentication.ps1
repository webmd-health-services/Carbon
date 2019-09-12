
function Enable-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Enables anonymous or basic authentication for an entire site or a sub-directory of that site.

    .DESCRIPTION
    By default, enables an authentication type on an entire website.  You can enable an authentication type at a specific path under a website by passing the virtual path (*not* the physical path) to that directory as the value of the `VirtualPath` parameter.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Disable-CIisSecurityAuthentication
    
    .LINK
    Get-CIisSecurityAuthentication
    
    .LINK
    Test-CIisSecurityAuthentication
    
    .EXAMPLE
    Enable-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

    Turns on anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Enable-CIisSecurityAuthentication -SiteName Peanuts Snoopy/DogHouse -Basic

    Turns on anonymous authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.

    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where anonymous authentication should be set.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path where anonymous authentication should be set.
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
        [Switch]
        # Enable anonymouse authentication.
        $Anonymous,

        [Parameter(Mandatory=$true,ParameterSetName='Basic')]
        [Switch]
        # Enable basic authentication.
        $Basic,
        
        [Parameter(Mandatory=$true,ParameterSetName='Windows')]
        [Switch]
        # Enable Windows authentication.
        $Windows
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $authType = $pscmdlet.ParameterSetName
    $getArgs = @{ $authType = $true; }
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getArgs
    
    if( $authSettings.GetAttributeValue('enabled') )
    {
        return
    }
    
    $authSettings.SetAttributeValue('enabled', 'true')
    
    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, ("enable {0}" -f $authType) ) )
    {
        $authSettings.CommitChanges()
    }
}


