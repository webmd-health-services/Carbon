
function Enable-CIisDirectoryBrowsing
{
    <#
    .SYNOPSIS
    Enables directory browsing under all or part of a website.

    .DESCRIPTION
    Enables directory browsing (i.e. showing the contents of a directory by requesting that directory in a web browser) for a website.  To enable directory browsing on a directory under the website, pass the virtual path to that directory as the value to the `Directory` parameter.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Enable-CIisDirectoryBrowsing -SiteName Peanuts

    Enables directory browsing on the `Peanuts` website.

    .EXAMPLE
    Enable-CIisDirectoryBrowsing -SiteName Peanuts -Directory Snoopy/DogHouse

    Enables directory browsing on the `/Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the site where the virtual directory is located.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The directory where directory browsing should be enabled.
        $VirtualPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/directoryBrowse'

    if( $section['enabled'] -ne 'true' )
    {
        Write-IisVerbose $SiteName 'Directory Browsing' 'disabled' 'enabled'
        $section['enabled'] = $true
        $section.CommitChanges()
    }

}

