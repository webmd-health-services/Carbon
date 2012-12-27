
function Get-IisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Gets a site's (and optional sub-directory's) security authentication configuration section.
    
    .DESCRIPTION
    You can get the anonymous, basic, digest, and Windows authentication sections by using the `Anonymous`, `Basic`, `Digest`, or `Windows` switches, respectively.
    
    .OUTPUTS
    Microsoft.Web.Administration.ConfigurationSection.
    
    .EXAMPLE
    Get-IisSecurityAuthentication -SiteName Peanuts -Anonymous
    
    Gets the `Peanuts` site's anonymous authentication configuration section.
    
    .EXAMPLE
    Get-IisSecurityAuthentication -SiteName Peanuts -Path Doghouse -Basic
    
    Gets the `Peanuts` site's `Doghouse` sub-directory's basic authentication configuration section.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where anonymous authentication should be set.
        $SiteName,
        
        [string]
        # The optional path where anonymous authentication should be set.
        $Path = '',

        [Parameter(Mandatory=$true,ParameterSetName='anonymousAuthentication')]        
        [Switch]
        # Gets a site's (and optional sub-directory's) anonymous authentication configuration section.
        $Anonymous,
        
        [Parameter(Mandatory=$true,ParameterSetName='basicAuthentication')]        
        [Switch]
        # Gets a site's (and optional sub-directory's) basic authentication configuration section.
        $Basic,
        
        [Parameter(Mandatory=$true,ParameterSetName='digestAuthentication')]        
        [Switch]
        # Gets a site's (and optional sub-directory's) digest authentication configuration section.
        $Digest,
        
        [Parameter(Mandatory=$true,ParameterSetName='windowsAuthentication')]        
        [Switch]
        # Gets a site's (and optional sub-directory's) Windows authentication configuration section.
        $Windows
    )
    
    $sectionPath = 'system.webServer/security/authentication/{0}' -f $pscmdlet.ParameterSetName
    Get-IisConfigurationSection -SiteName $SiteName -Path $Path -SectionPath $sectionPath
}