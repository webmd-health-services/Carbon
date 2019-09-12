
function Get-CIisConfigurationSection
{
    <#
    .SYNOPSIS
    Gets a Microsoft.Web.Adminisration configuration section for a given site and path.
    
    .DESCRIPTION
    Uses the Microsoft.Web.Administration API to get a `Microsoft.Web.Administration.ConfigurationSection`.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.ConfigurationSection.
    
    .EXAMPLE
    Get-CIisConfigurationSection -SiteName Peanuts -Path Doghouse -Path 'system.webServer/security/authentication/anonymousAuthentication'

    Returns a configuration section which represents the Peanuts site's Doghouse path's anonymous authentication settings.    
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
        [string]
        # The site whose configuration should be returned.
        $SiteName,
        
        [Parameter(ParameterSetName='ForSite')]
        [Alias('Path')]
        [string]
        # The optional site path whose configuration should be returned.
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
        [Parameter(Mandatory=$true,ParameterSetName='Global')]
        [string]
        # The path to the configuration section to return.
        $SectionPath,
        
        [Type]
        # The type of object to return.  Optional.
        $Type = [Microsoft.Web.Administration.ConfigurationSection]
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $config = $mgr.GetApplicationHostConfiguration()
    
    $section = $null
    $qualifier = ''
    try
    {
        if( $PSCmdlet.ParameterSetName -eq 'ForSite' )
        {
            $qualifier = Join-CIisVirtualPath $SiteName $VirtualPath
            $section = $config.GetSection( $SectionPath, $Type, $qualifier )
        }
        else
        {
            $section = $config.GetSection( $SectionPath, $Type )
        }
    }
    catch
    {
    }
        
    if( $section )
    {
        $section | Add-IisServerManagerMember -ServerManager $mgr -PassThru
    }
    else
    {
        Write-Error ('IIS:{0}: configuration section {1} not found.' -f $qualifier,$SectionPath)
        return
    }
}

