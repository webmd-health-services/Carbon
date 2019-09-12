
function Remove-CIisMimeMap
{
    <#
    .SYNOPSIS
    Removes a file extension to MIME type map from an entire web server.
    
    .DESCRIPTION
    IIS won't serve static files unless they have an entry in the MIME map.  Use this function toremvoe an existing MIME map entry.  If one doesn't exist, nothing happens.  Not even an error.
    
    If a specific website has the file extension in its MIME map, that site will continue to serve files with those extensions.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisMimeMap
    
    .LINK
    Set-CIisMimeMap
    
    .EXAMPLE
    Remove-CIisMimeMap -FileExtension '.m4v' -MimeType 'video/x-m4v'
    
    Removes the `.m4v` file extension so that IIS will no longer serve those files.
    #>
    [CmdletBinding(DefaultParameterSetName='ForWebServer')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForWebsite')]
        [string]
        # The name of the website whose MIME type to set.
        $SiteName,

        [Parameter(ParameterSetName='ForWebsite')]
        [string]
        # The optional site path whose configuration should be returned.
        $VirtualPath = '',

        [Parameter(Mandatory=$true)]
        [string]
        # The file extension whose MIME map to remove.
        $FileExtension
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getIisConfigSectionParams = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
    {
        $getIisConfigSectionParams['SiteName'] = $SiteName
        $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
    }
    
    $staticContent = Get-CIisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams
    $mimeMapCollection = $staticContent.GetCollection()
    $mimeMapToRemove = $mimeMapCollection |
                            Where-Object { $_['fileExtension'] -eq $FileExtension }
    if( -not $mimeMapToRemove )
    {
        Write-Verbose ('MIME map for file extension {0} not found.' -f $FileExtension)
        return
    }
    
    $mimeMapCollection.Remove( $mimeMapToRemove )
    $staticContent.CommitChanges()
}

