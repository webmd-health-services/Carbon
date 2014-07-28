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
    Creates a new application at `VirtualPath` under website `SiteName` running the code found on the file system under `PhysicalPath`, i.e. if SiteName is is `example.com`, the application is accessible at `example.com/VirtualPath`.  If an application already exists at that path, it is removed first.  The application can run under a custom application pool using the optional `AppPoolName` parameter.  If no app pool is specified, the application runs under the same app pool as the website it runs under.
    
    .EXAMPLE
    Install-IisApplication -SiteName Peanuts -VirtualPath CharlieBrown -PhysicalPath C:\Path\To\CharlieBrown -AppPoolName CharlieBrownPool
    
    Creates an application at `Peanuts/CharlieBrown` which runs from `Path/To/CharlieBrown`.  The application runs under the `CharlieBrownPool`.
    
    .EXAMPLE
    Install-IisApplication -SiteName Peanuts -VirtualPath Snoopy -PhysicalPath C:\Path\To\Snoopy
    
    Create an application at Peanuts/Snoopy, which runs from C:\Path\To\Snoopy.  It uses the same application as the Peanuts website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the application should be created.
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [string]
        # The name of the application.
        $VirtualPath,
        
        [Parameter(Mandatory=$true)]
        [Alias('Path')]
        [string]
        # The path to the application.
        $PhysicalPath,
        
        [string]
        # The app pool for the application.
        $AppPoolName
    )
    
    $PhysicalPath = Resolve-FullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        $null = New-Item $PhysicalPath -ItemType Directory
    }

    $appPoolDesc = ''
    if( $AppPoolName )
    {
        $appPoolDesc = '; appPool: {0}' -f $AppPoolName
    }
    
    $app = Get-IisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    if( $app )
    {
        Write-Verbose ('IIS://{0}: deleting application' -f (Join-IisVirtualPath $SiteName $VirtualPath))
        $app.Delete()
        $app.CommitChanges()
    }

    Write-Verbose ('IIS:/{0}: creating application: physicalPath: {1}{2}' -f (Join-IisVirtualPath $SiteName $VirtualPath),$PhysicalPath,$appPoolDesc)
    $site = Get-IisWebsite -SiteName $SiteName
    if( -not $site )
    {
        Write-Error ('[IIS] Website ''{0}'' not found.' -f $SiteName)
        return
    }
    $apps = $site.GetCollection()
    $app = $apps.CreateElement('application') |
                Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
    $app['path'] = "/{0}" -f $VirtualPath
    $apps.Add( $app ) | Out-Null

    if( $AppPoolName )
    {
        $app['applicationPool'] = $AppPoolName
    }
    $vdir = $app.VirtualDirectories |
                Where-Object { $_.Path -eq '/' }
    if( -not $vdir )
    {
        $vdirs = $app.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        $vdir['path'] = '/'
        $vdirs.Add( $vdir ) | Out-Null
    }
    $vdir['physicalPath'] = $PhysicalPath
    $app.CommitChanges()
}
