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

function Get-IisMimeMap
{
    <#
    .SYNOPSIS
    Gets the file extension to MIME type mappings.
    
    .DESCRIPTION
    IIS won't serve static content unless there is an entry for it in the web server or website's MIME map configuration. This function will return all the MIME maps for the current server.  The objects returned are instances of the `Carbon.Iis.MimeMap` class, and contain the following properties:
    
     * `FileExtension`: the mapping's file extension
     * `MimeType`: the mapping's MIME type
    
    .OUTPUTS
    Carbon.Iis.MimeMap.
    
    .LINK
    Set-IisMimeMap
    
    .EXAMPLE
    Get-IisMimeMap
    
    Gets all the the file extension to MIME type mappings for the web server.
    
    .EXAMPLE
    Get-IisMimeMap -FileExtension .htm*
    
    Gets all the file extension to MIME type mappings whose file extension matches the `.htm*` wildcard.
    
    .EXAMPLE
    Get-IisMimeMap -MimeType 'text/*'
    
    Gets all the file extension to MIME type mappings whose MIME type matches the `text/*` wildcard.
    
    .EXAMPLE
    Get-IisMimeMap -SiteName DeathStar
    
    Gets all the file extenstion to MIME type mappings for the `DeathStar` website.
    
    .EXAMPLE
    Get-IisMimeMap -SiteName DeathStar -VirtualPath ExhaustPort
    
    Gets all the file extension to MIME type mappings for the `DeathStar`'s `ExhausePort` directory.
    #>
    [CmdletBinding(DefaultParameterSetName='ForWebServer')]
    [OutputType([Carbon.Iis.MimeMap])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForWebsite')]
        [string]
        # The website whose MIME mappings to return.  If not given, returns the web server's MIME map.
        $SiteName,
        
        [Parameter(ParameterSetName='ForWebsite')]
        [Alias('Path')]
        [string]
        # The directory under the website whose MIME mappings to return.  Optional.
        $VirtualPath = '',
        
        [string]
        # The name of the file extensions to return. Wildcards accepted.
        $FileExtension = '*',
        
        [string]
        # The name of the MIME type(s) to return.  Wildcards accepted.
        $MimeType = '*'
    )

    Set-StrictMode -Version 'Latest'
    
    $getIisConfigSectionParams = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
    {
        $getIisConfigSectionParams['SiteName'] = $SiteName
        $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
    }

    $staticContent = Get-IisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams
    $staticContent.GetCollection() | 
        Where-Object { $_['fileExtension'] -like $FileExtension -and $_['mimeType'] -like $MimeType } |
        ForEach-Object {
            New-Object 'Carbon.Iis.MimeMap' ($_['fileExtension'],$_['mimeType'])
        }
}