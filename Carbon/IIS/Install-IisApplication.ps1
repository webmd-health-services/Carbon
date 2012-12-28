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

function Install-IisApplication
{
    <#
    .SYNOPSIS
    Creates a new application under a website.
    
    .DESCRIPTION
    Creates a new application at `Name` under website `SiteName` running the code found on the file system under `Path`, i.e. if SiteName is is `example.com`, the application is accessible at `example.com/Name`.  If an application already exists at that path, it is removed first.  The application can run under a custom application pool using the optional `AppPoolName` parameter.  If no app pool is specified, the application runs under the same app pool as the website it runs under.
    
    .EXAMPLE
    Install-IisApplication -SiteName Peanuts -Name CharlieBrown -Path C:\Path\To\CharlieBrown -AppPoolName CharlieBrownPool
    
    Creates an application at `Peanuts/CharlieBrown` which runs from `Path/To/CharlieBrown`.  The application runs under the `CharlieBrownPool`.
    
    .EXAMPLE
    Install-IisApplication -SiteName Peanuts -Name Snoopy -Path C:\Path\To\Snoopy
    
    Create an application at Peanuts/Snoopy, which runs from C:\Path\To\Snoopy.  It uses the same application as the Peanuts website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the application should be created.
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the application.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the application.
        $Path,
        
        [string]
        # The app pool for the application.
        $AppPoolName
    )
    
    $appID = """$SiteName/$Name"""
    $output = Invoke-AppCmd list app $appID
    if( $output -like "*$appID*" )
    {
        Invoke-AppCmd delete app $appID
    }
    
    if( -not (Test-Path $Path -PathType Container) )
    {
        $null = New-Item $Path -ItemType Directory
    }
    
    Invoke-AppCmd add app /site.name:"$SiteName" /path:/$Name /physicalPath:"$Path"
    
    if( $AppPoolName )
    {
        Invoke-AppCmd set app /app.name:"$SiteName/$Name" /applicationPool:`"$AppPoolName`"
    }
}
