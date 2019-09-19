
function Test-CIisConfigurationSection
{
    <#
    .SYNOPSIS
    Tests a configuration section.
    
    .DESCRIPTION
    You can test if a configuration section exists or wheter it is locked.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    System.Boolean.
    
    .EXAMPLE
    Test-CIisConfigurationSection -SectionPath 'system.webServer/I/Do/Not/Exist'
    
    Tests if a configuration section exists.  Returns `False`, because the given configuration section doesn't exist.
    
    .EXAMPLE
    Test-CIisConfigurationSection -SectionPath 'system.webServer/cgi' -Locked
    
    Returns `True` if the global CGI section is locked.  Otherwise `False`.
    
    .EXAMPLE
    Test-CIisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication' -SiteName `Peanuts` -VirtualPath 'SopwithCamel' -Locked

    Returns `True` if the `Peanuts` website's `SopwithCamel` sub-directory's `basicAuthentication` security authentication section is locked.  Otherwise, returns `False`.
    #>
    [CmdletBinding(DefaultParameterSetName='CheckExists')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the section to test.
        $SectionPath,
        
        [Parameter()]
        [string]
        # The name of the site whose configuration section to test.  Optional.  The default is the global configuration.
        $SiteName,
        
        [Parameter()]
        [Alias('Path')]
        [string]
        # The optional path under `SiteName` whose configuration section to test.
        $VirtualPath,
        
        [Parameter(Mandatory=$true,ParameterSetName='CheckLocked')]
        [Switch]
        # Test if the configuration section is locked.  
        $Locked
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getArgs = @{
                    SectionPath = $SectionPath;
                }
    if( $SiteName )
    {
        $getArgs.SiteName = $SiteName
    }
    
    if( $VirtualPath )
    {
        $getArgs.VirtualPath = $VirtualPath
    }
    
    $section = Get-CIisConfigurationSection @getArgs -ErrorAction SilentlyContinue
    
    if( $pscmdlet.ParameterSetName -eq 'CheckExists' )
    {
        if( $section )
        {
            return $true
        }
        else
        {
            return $false
        }
    }
        
    if( -not $section )
    {
        Write-Error ('IIS:{0}: section {1} not found.' -f (Join-CIisVirtualPath $SiteName $VirtualPath),$SectionPath)
        return
    }
    
    if( $pscmdlet.ParameterSetName -eq 'CheckLocked' )
    {
        return $section.OverrideMode -eq 'Deny'
    }
}

