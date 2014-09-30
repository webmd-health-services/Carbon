# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Remove-IisMimeMap
{
    <#
    .SYNOPSIS
    Removes a file extension to MIME type map from an entire web server.
    
    .DESCRIPTION
    IIS won't serve static files unless they have an entry in the MIME map.  Use this function toremvoe an existing MIME map entry.  If one doesn't exist, nothing happens.  Not even an error.
    
    If a specific website has the file extension in its MIME map, that site will continue to serve files with those extensions.
    
    .LINK
    Get-IisMimeMap
    
    .LINK
    Set-IisMimeMap
    
    .EXAMPLE
    Remove-IisMimeMap -FileExtension '.m4v' -MimeType 'video/x-m4v'
    
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

    $getIisConfigSectionParams = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
    {
        $getIisConfigSectionParams['SiteName'] = $SiteName
        $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
    }
    
    $staticContent = Get-IisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams
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
