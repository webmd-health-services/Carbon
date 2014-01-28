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

function Install-IisWebsite
{
    <# 
    .SYNOPSIS
    Installs a website.

    .DESCRIPTION
    Installs a website named `Name`, serving files out of the file system from `PhysicalPath`.  If no app pool name is given (via the `AppPoolName` parameter), IIS will pick one for you, usually the `DefaultAppPool`.  If a site with name `Name` already exists, it is deleted, and a new site is created.

    By default, the site listens on all IP addresses on port 80.  Set custom bindings with the `Bindings` argument.  Multiple bindings are allowed.  Each binding must be in this format (in BNF):

        <PROTOCOL> '/' <IP_ADDRESS> ':' <PORT> ':' [ <HOSTNAME> ]

     * `PROTOCOL` is one of `http` or `https`.
     * `IP_ADDRESS` is a literal IP address, or `*` for all of the computer's IP addresses.  This function does not validate if `IPADDRESS` is actually in use on the computer.
     * `PORT` is the port to listen on.
     * `HOSTNAME` is the website's hostname, for name-based hosting.  If no hostname is being used, leave off the `HOSTNAME` part.

    Valid bindings are:

     * http/*:80:
     * https/10.2.3.4:443:
     * http/*:80:example.com
    
    .LINK
    Get-IisWebsite
    
    .LINK
    Uninstall-IisWebsite

    .EXAMPLE
    Install-IisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com

    Creates a website named `Peanuts` serving files out of the `C:\Peanuts.com` directory.  The website listens on all the computer's IP addresses on port 80.

    .EXAMPLE
    Install-IisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -Bindings 'http/*:80:peanuts.com:'

    Creates a website named `Peanuts` which uses name-based hosting to respond to all requests to any of the machine's IP addresses for the `peanuts.com` domain.

    .EXAMPLE
    Install-IisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -AppPoolName 'PeanutsAppPool'

    Creates a website named `Peanuts` that runs under the `PeanutsAppPool` app pool
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        # The name of the website
        $Name,
        
        [Parameter(Position=1,Mandatory=$true)]
        [Alias('Path')]
        [string]
        # The physical path (i.e. on the file system) to the website
        $PhysicalPath,
        
        [Parameter(Position=2)]
        [string[]]
        # The site's network bindings.  Default is `http/*:80:`.  Bindings should be specified in protocol/IPAddress:Port:Hostname format.  
        #
        #  * Protocol should be http or https. 
        #  * IPAddress can be a literal IP address or `*`, which means all of the computer's IP addresses.  This function does not validate if `IPAddress` is actually in use on this computer.
        #  * Leave hostname blank for non-named websites.
        $Bindings = @('http/*:80:'),
        
        [string]
        # The name of the app pool under which the website runs.  The app pool must exist.  If not provided, IIS picks one for you.  No whammy, no whammy!
        $AppPoolName
    )
    
    if( Test-IisWebsite -Name $Name )
    {
        Uninstall-IisWebsite -Name $Name
    }
    
    $PhysicalPath = Resolve-FullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        $null = New-Item $PhysicalPath -ItemType Directory -Force
    }
    
    $invalidBindings = $Bindings | 
                           Where-Object { $_ -notmatch '^http(s)?/(\*|[\d\.]+):\d+:(.*)$' } |
                           Where-Object { $_ -notmatch '^http(s)?://(\*|[\d\.]+):\d+(:.*)?$' }
    if( $invalidBindings )
    {
        $invalidBindings = $invalidBindings -join "`n`t"
        $errorMsg = "The following bindings are invalid.  The correct format is protocol/IPAddress:Port:Hostname.  IP address can be * for all IP addresses.  Hostname is optional.`n`t{0}" -f $invalidBindings
        Write-Error $errorMsg
        return
    }
    
    $bindingsArg = $Bindings -join ','
    Invoke-AppCmd add site /name:"$Name" /physicalPath:"$PhysicalPath" /bindings:$bindingsArg
    
    if( $AppPoolName )
    {
        Invoke-AppCmd set site /site.name:"$Name" /[path=`'/`'].applicationPool:`"$AppPoolName`"
    }
    
    # Make sure anonymous authentication uses the application pool identity
    Invoke-AppCmd set config `"$Name`" /section:anonymousAuthentication /userName: /commit:apphost
    
    # Now, wait until site is actually running
    $tries = 0
    do
    {
        $website = Get-IisWebsite -SiteName $Name
        $tries += 1
        if($website.State -ne 'Unknown')
        {
            break
        }
        else
        {
            Start-Sleep -Milliseconds 100
        }
    }
    while( $tries -lt 100 )
}
