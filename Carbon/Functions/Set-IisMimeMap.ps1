
function Set-CIisMimeMap
{
    <#
    .SYNOPSIS
    Creates or sets a file extension to MIME type map for an entire web server.
    
    .DESCRIPTION
    IIS won't serve static files unless they have an entry in the MIME map.  Use this function to create/update a MIME map entry.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisMimeMap
    
    .LINK
    Remove-CIisMimeMap
    
    .EXAMPLE
    Set-CIisMimeMap -FileExtension '.m4v' -MimeType 'video/x-m4v'
    
    Adds a MIME map so that IIS will serve `.m4v` files as `video/x-m4v`.
    
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='ForWebServer')]
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
        # The file extension to set.
        $FileExtension,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The MIME type to serve the files as.
        $MimeType
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
    
    $mimeMap = $mimeMapCollection | Where-Object { $_['fileExtension'] -eq $FileExtension }
    
    if( $mimeMap )
    {
        $action = 'setting'
        $mimeMap['fileExtension'] = $FileExtension
        $mimeMap['mimeType'] = $MimeType
    }
    else
    {
        $action = 'adding'
        $mimeMap = $mimeMapCollection.CreateElement("mimeMap");
        $mimeMap["fileExtension"] = $FileExtension
        $mimeMap["mimeType"] = $MimeType
        [void] $mimeMapCollection.Add($mimeMap)
    }
     
    if( $PSCmdlet.ShouldProcess( 'IIS web server', ('{0} MIME map {1} -> {2}' -f $action,$FileExtension,$MimeType) ) )
    {
        $staticContent.CommitChanges()
    }
}

