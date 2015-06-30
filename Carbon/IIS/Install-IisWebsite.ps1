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
    `Install-IisWebsite` installs an IIS website. Anonymous authentication is enabled, and the anonymous user is set to the website's application pool identity. Before Carbon 2.0, if a website already existed, it was deleted and re-created. Beginning with Carbon 2.0, existing websites are modified in place. Also starting in Carbon 2.0, when a website is created or its application pool changes, its app pool is recycled.
    
    If don't set the website's app pool, IIS will pick one for you, and `Install-IisWebsite` will never manage the app pool for you (i.e. if someone changes it manually, this function won't set it back to the default). We recommend always supplying an app pool name, even if it is `DefaultAppPool`.

    By default, the site listens on (i.e. is bound to) all IP addresses on port 80 (binding `http/*:80:`). Set custom bindings with the `Bindings` argument. Multiple bindings are allowed. Each binding must be in this format (in BNF):

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
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        # The name of the website.
        $Name,
        
        [Parameter(Position=1,Mandatory=$true)]
        [Alias('Path')]
        [string]
        # The physical path (i.e. on the file system) to the website. If it doesn't exist, it will be created for you.
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
        $AppPoolName,

        [int]
        # The site's IIS ID. IIS picks one for you automatically if you don't supply one. Must be greater than 0.
        $SiteID,

        [Switch]
        # Return a `Microsoft.Web.Administration.Site` object for the website.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    $PhysicalPath = Resolve-FullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        New-Item $PhysicalPath -ItemType Directory | Out-String | Write-Verbose
    }
    
    $bindingRegex = '^(?<Protocol>https?):?//?(?<IPAddress>\*|[\d\.]+):(?<Port>\d+):?(?<HostName>.*)$'
    $invalidBindings = $Bindings | 
                           Where-Object { $_ -notmatch $bindingRegex } 
    if( $invalidBindings )
    {
        $invalidBindings = $invalidBindings -join "`n`t"
        $errorMsg = "The following bindings are invalid. The correct format is protocol/IPAddress:Port:Hostname. Protocol and IP address must be separted by a single slash, not ://. IP address can be * for all IP addresses. Hostname is optional. If hostname is not provided, the binding must end with a colon.`n`t{0}" -f $invalidBindings
        Write-Error $errorMsg
        return
    }

    [Microsoft.Web.Administration.Site]$site = $null
    $modified = $true
    $created = $false
    if( (Test-IisWebsite -Name $Name) )
    {
        $site = Get-IisWebsite -Name $Name
    }
    else
    {
        Write-Verbose -Message ('Creating website ''{0}'' ({1}).' -f $Name,$PhysicalPath)
        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $site = $mgr.Sites.Add( $Name, $PhysicalPath, 80 ) | Add-IisServerManagerMember -ServerManager $mgr -PassThru
        $modified = $true
        $created = $true
    }

    $existingBindings = New-Object 'Collections.Generic.Hashset[string]'
    $site.Bindings | ForEach-Object { [void]$existingBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }

    $missingBinding = $Bindings | Where-Object { -not $existingBindings.Contains( $_ ) }
    $hasExtraBinding = $existingBindings | Where-Object { $Bindings -notcontains $_ }
    if( $missingBinding -or $hasExtraBinding )
    {
        $site.Bindings.Clear()
        $Bindings | ForEach-Object { 
            $_ -match $bindingRegex | Out-Null
            $protocol = $Matches['Protocol']
            $bindingInfo = '{0}:{1}:{2}' -f $Matches['IPAddress'],$Matches['Port'],$Matches['HostName']
            Write-Verbose -Message ('IIS://{0}: adding binding [{1}] {2}' -f $Name,$protocol,$bindingInfo)
            $site.Bindings.Add( $bindingInfo, $protocol )
        }
        $modified = $true
    }

    if( $site.Applications.Count -eq 0 )
    {
        $rootApp = $site.Applications.Add("/", $PhysicalPath)
        $modifed = $true
    }
    else
    {
        [Microsoft.Web.Administration.Application]$rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
        if( $site.PhysicalPath -ne $PhysicalPath )
        {
            Write-Verbose -Message ('IIS://{0}: PhysicalPath: {1}' -f $Name,$PhysicalPath)
            [Microsoft.Web.Administration.VirtualDirectory]$vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq '/' }
            $vdir.PhysicalPath = $PhysicalPath
            $modified = $true
        }
    }
    
    $setAppPool = $false
    if( $AppPoolName )
    {
        if( $rootApp.ApplicationPoolName -ne $AppPoolName )
        {
            Write-Verbose -Message ('IIS://{0}: AppPool: {1}' -f $Name,$AppPoolName)
            $rootApp.ApplicationPoolName = $AppPoolName
            $modified = $true
            $setAppPool = $true
        }
    }

    if( $modified )
    {
        Write-Verbose -Message ('IIS://{0}: Committing changes' -f $Name)
        $site.CommitChanges()
        if( $created -or $setAppPool )
        {
            $rootApp = Get-IisApplication -SiteName $Name
            $appPool = Get-IisAppPool -Name $rootApp.ApplicationPoolName
            Write-Verbose ('IIS://{0}: recycling ''{1}'' app pool' -f $Name,$appPool.Name)
            $appPool.Recycle() | Write-Verbose
        }
    }
    
    if( $SiteID )
    {
        Set-IisWebsiteID -SiteName $Name -ID $SiteID
    }
    
    # Make sure anonymous authentication is enabled and uses the application pool identity
    Write-Verbose ('IIS://{0}: Enabling anonymous authentication; setting anonymous user to app pool identity.' -f $Name)
    $security = Get-IisSecurityAuthentication -SiteName $Name -VirtualPath '/' -Anonymous
    $security['username'] = ''
    $security.CommitChanges()

    # Now, wait until site is actually running
    $tries = 0
    $website = $null
    do
    {
        $website = Get-IisWebsite -SiteName $Name
        $tries += 1
        if($website.State -ne 'Unknown')
        {
            return $website
        }
        else
        {
            Start-Sleep -Milliseconds 100
        }
    }
    while( $tries -lt 100 )

    return $website
}
