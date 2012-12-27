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
Add-Type -AssemblyName "System.Web"
$microsoftWebAdministrationPath = Join-Path $env:SystemRoot system32\inetsrv\Microsoft.Web.Administration.dll
if( (Test-Path -Path $microsoftWebAdministrationPath -PathType Leaf) )
{
    Add-Type -Path $microsoftWebAdministrationPath
}

function Add-IisDefaultDocument
{
    <#
    .SYNOPSIS
    Adds a default document name to a website.
    
    .DESCRIPTION
    If you need a custom default document for your website, this function will add it.  The `FileName` argument should be a filename IIS should use for a default document, e.g. home.html.
    
    If the website already has `FileName` in its list of default documents, this function silently returns.
    
    .EXAMPLE
    Add-IisDefaultDocument -SiteName MySite -FileName home.html
    
    Adds `home.html` to the list of default documents for the MySite website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the site where the default document should be added.
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The default document to add
        $FileName
    )
    
    $xml = [xml] (Invoke-AppCmd list config `"$SiteName`" /section:defaultDocument )
    $docNode = $xml.SelectSingleNode( "/system.webServer/defaultDocument/files/add[@value = '$FileName']" )
    if( -not $docNode )
    {
        Invoke-AppCmd set config `"$SiteName`" /section:defaultDocument /+files.[value=`'$FileName`'] /commit:apphost
    }
}

function Get-IisHttpRedirect
{
    <#
    .SYNOPSIS
    Gets the HTTP redirect settings for a website or virtual directory/application under a website.
    
    .DESCRIPTION
    The settings are returned as a hashtable with the following properties:
    
     * Enabled - `True` if the redirect is enabled, `False` otherwise.
     * Destination - The URL where requests are directed to.
     * StatusCode - The HTTP status code sent to the browser for the redirect.
     * ExactDescription - `True` if redirects are to an exact destination, not relative to the destination.  Whatever that means.
     * ChildOnly - `True` if redirects are only to content in the destination directory (not subdirectories).
     
    .EXAMPLE
    Get-IisHttpRedirect -SiteName ExampleWebsite 
    
    Gets the redirect settings for ExampleWebsite.
    
    .EXAMPLE
    Get-IisHttpRedirect -SiteName ExampleWebsite -Path MyVirtualDirectory
    
    Gets the redirect settings for the MyVirtualDirectory virtual directory under ExampleWebsite.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site's whose HTTP redirect settings will be retrieved.
        $SiteName,
        
        [string]
        # The optional path to a sub-directory under `SiteName` whose settings to return.
        $Path = ''
    )
    
    $settingsDoc = [xml] (Invoke-AppCmd list config "$SiteName/$Path" /section:httpRedirect)
    $settings = @{ }
    $httpRedirectElement = $settingsDoc['system.webServer'].httpRedirect
    $settings.Enabled = ($httpRedirectElement.enabled -eq 'true')
    $settings.Destination = $httpRedirectElement.destination
    $settings.StatusCode= $httpRedirectElement.httpResponseStatus
    $settings.ExactDestination = ($httpRedirectElement.exactDestination -eq 'true')
    $settings.ChildOnly = ($httpRedirectElement.childOnly -eq 'true')
    return $settings
}

function Get-IisVersion
{
    <#
    .SYNOPSIS
    Gets the version of IIS.
    
    .DESCRIPTION
    Reads the version of IIS from the registry, and returns it as a `Major.Minor` formatted string.
    
    .EXAMPLE
    Get-IisVersion
    
    Returns `7.0` on Windows 2008, and `7.5` on Windows 7 and Windows 2008 R2.
    #>
    [CmdletBinding()]
    param(
    )
    $props = Get-ItemProperty hklm:\Software\Microsoft\InetStp
    return $props.MajorVersion.ToString() + "." + $props.MinorVersion.ToString()
}

function Get-IisWebsite
{
    <#
    .SYNOPSIS
    Gets details about a website.
    
    .DESCRIPTION
    Returns an object containing the name, ID, bindings, and state of a website:
    
     * Bindings - An array of objects for each of the website's bindings.  Each object contains:
      * Protocol - The protocol of the binding, e.g. http, https.
      * IPAddress - The IP address the site is listening to, or * for all IP addresses.
      * Port - The port the site is listening on.
     * Name - The site's name.
     * ID - The site's ID.
     * State - The site's state, e.g. started, stopped, etc.
     
     .EXAMPLE
     Get-IisWebsite -SiteName 'WebsiteName'
     
     Returns the details for the site named `WebsiteName`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the site to get.
        $SiteName
    )
    
    if( -not (Test-IisWebsite -Name $SiteName) )
    {
        return $null
    }
    $siteXml = [xml] (Invoke-AppCmd list site $SiteName -xml)
    $siteXml = $siteXml.appcmd.SITE
    
    $site = @{ }
    
    $bindingsRaw = $siteXml.bindings -split ','
    $bindings = @()
    foreach( $bindingRaw in $bindingsRaw )
    {
        if( $bindingRaw -notmatch '^(https?)/([^:]*):([^:]*)(:(.*))?$' )
        {
            Write-Error "Unable to parse binding '$bindingRaw' for website '$SiteName'."
            continue
        }
        $binding = @{
                        Protocol = $matches[1];
                        IPAddress = $matches[2];
                        Port = $matches[3];
                    }
        $binding.HostName = ''
        if( $matches.Count -ge 5 )
        {
            $binding.HostName = $matches[5]
        }
        
        $bindings += New-Object PsObject -Property $binding
    }
    $site.Bindings = $bindings
    $site.Name = $siteXml.'SITE.NAME'
    $site.ID = $siteXml.'SITE.ID'
    $site.State = $siteXml.state
    return New-Object PsObject -Property $site
}

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


function Install-IisAppPool
{
    <#
    .SYNOPSIS
    Creates a new app pool.
    
    .DESCRIPTION
    You can control which version of .NET is used to run an app pool with the `ManagedRuntimeVersion` parameter: versions `v1.0`, `v1.1`, `v2.0`, and `v4.0` are supported.

    To run an application pool using the classic pipeline mode, set the `ClassicPipelineMode` switch.

    To run an app pool using the 32-bit version of the .NET framework, set the `Enable32BitApps` switch.

    An app pool can run as several built-in service accounts, by passing one of them as the value of the `ServiceAccount` parameter: `NetworkService`, `LocalService`, `LocalSystem`, and `ApplicationPoolIdentity`.  Specifying `ApplicationPoolIdentity` causes IIS to create and use a custom local account with the name of the app pool.  See [Application Pool Identities](http://learn.iis.net/page.aspx/624/application-pool-identities/) for more information.

    To run the app pool as a specific user, pass the username and password for the account to the `Username` and `Password` parameters, respectively.

    If an existing app pool exists with name `Name`, it's settings are modified.  The app pool isn't deleted.  (You can't delete an app pool if there are any websites using it, that's why.)

    By default, this function will create an application pool running the latest version of .NET, with an integrated pipeline, as the NetworkService account.

    .EXAMPLE
    Install-IisAppPool -Name Cyberdyne -ServiceAccount NetworkService

    Creates a new Cyberdyne application pool, running as NetworkService, using .NET 4.0 and an integrated pipeline.  If the Cyberdyne app pool already exists, it is modified to run as NetworkService, to use .NET 4.0 and to use an integrated pipeline.

    .EXAMPLE
    Install-IisAppPool -Name Cyberdyne -ServiceAccount NetworkService -Enable32BitApps -ClassicPipelineMode

    Creates or sets the Cyberdyne app pool to run as NetworkService, in 32-bit mode (i.e. 32-bit applications are enabled), using the classic IIS request pipeline.

    .EXAMPLE
    Install-IisAppPool -Name Cyberdyne -Username 'PEANUTS\charliebrown' -Password '5noopyrulez'

    Creates or sets the Cyberdyne app pool to run as the `PEANUTS\charliebrown` domain account, under .NET 4.0, with an integrated pipeline.
    #>
    [CmdletBinding(DefaultParameterSetName='AsServiceAccount')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The app pool's name.
        $Name,
        
        [string]
        [ValidateSet('v1.0','v1.1','v2.0','v4.0')]
        # The managed .NET runtime version to use.  Default is 'v4.0'.  Valid values are `v1.0`, `v1.1`, `v2.0`, or `v4.0`.
        $ManagedRuntimeVersion = 'v4.0',
        
        [int]
        [ValidateScript({$_ -gt 0})]
        #Idle Timeout value in minutes. Default is 0.
        $IdleTimeout = 0,
        
        [Switch]
        # Use the classic pipeline mode, i.e. don't use an integrated pipeline.
        $ClassicPipelineMode,
        
        [Switch]
        # Enable 32-bit applications.
        $Enable32BitApps,
        
        [Parameter(ParameterSetName='AsServiceAccount')]
        [string]
        [ValidateSet('NetworkService','LocalService','LocalSystem','ApplicationPoolIdentity')]
        # Run the app pool under the given local service account.  Valid values are `NetworkService`, `LocalService`, `LocalSystem`, and `ApplicationPoolIdentity`.  Specifying `ApplicationPoolIdentity` causes IIS to create a custom local user account for the app pool's identity.
        $ServiceAccount,
        
        [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true)]
        [string]
        # Runs the app pool under a specific user account.
        $UserName,
        
        [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true)]
        # The password for the user account.  Can be a string or a SecureString.
        $Password
    )
    
    if( -not (Test-IisAppPoolExists -Name $Name) )
    {
        Invoke-AppCmd add apppool /name:`"$Name`" /commit:apphost
    }
    
    $pipelineMode = 'Integrated'
    if( $ClassicPipelineMode )
    {
        $pipelineMode = 'Classic'
    }
    
    Invoke-AppCmd set apppool `"$Name`" /managedRuntimeVersion:$ManagedRuntimeVersion /managedPipelineMode:$pipelineMode
    
    Invoke-AppCmd set config /section:applicationPools /[name=`'$Name`'].processModel.idleTimeout:"$(New-TimeSpan -minutes $IdleTimeout)"
    
    Invoke-AppCmd set config /section:applicationPools /[name=`'$name`'].enable32BitAppOnWin64:$Enable32BitApps
    
    if( $pscmdlet.ParameterSetName -eq 'AsServiceAccount' )
    {
        if( $ServiceAccount )
        {
            Invoke-AppCmd set config /section:applicationPools /[name=`'$Name`'].processModel.identityType:$ServiceAccount
        }
    }
    elseif( $pscmdlet.ParameterSetName -eq 'AsSpecificUser' )
    {
        if( $Password -is [Security.SecureString] )
        {
            $Password = Convert-SecureStringToString $Password
        }
        Invoke-AppCmd set config /section:applicationPools /[name=`'$Name`'].processModel.identityType:SpecificUser `
                                                           /[name=`'$Name`'].processModel.userName:$UserName `
                                                           /[name=`'$Name`'].processModel.password:$Password
    }
}

function Install-IisVirtualDirectory
{
    <#
    .SYNOPSIS
    Installs a virtual directory.

    .DESCRIPTION
    This function creates a virtual directory under website `SiteName` at `/Name`, serving files out of `Path`.  If a virtual directory called `Name` already exists, it is deleted first, and a new virtual directory is created.

    .EXAMPLE
    Install-IisVirtualDirectory -SiteName 'Peanuts' -Name 'DogHouse' -Path C:\Peanuts\Doghouse

    Creates a /DogHouse virtual directory, which serves files from the C:\Peanuts\Doghouse directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/DogHouse`.

    .EXAMPLE
    Install-IisVirtualDirectory -SiteName 'Peanuts' -Name 'Brown/Snoopy/DogHouse' -Path C:\Peanuts\DogHouse

    Creates a DogHouse virtual directory under the `Peanuts` website at `/Brown/Snoopy/DogHouse` serving files out of the `C:\Peanuts\DogHouse` directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/Brown/Snoopy/DogHouse`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the virtual directory should be created.
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the virtual directory.  This can contain multiple directory segments for virtual directories not at the root of the website, e.g. First/Second/VirtualDirectory.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The file system path to the virtual directory.
        $Path
    )
    
    $vdirID = """$SiteName/$Name"""
    $output = Invoke-AppCmd list vdir $vdirID
    if( $output -like "*$vdirID*" )
    {
        Invoke-AppCmd delete vdir $vdirID
    }
    
    Invoke-AppCmd add vdir /app.name:"$SiteName/" / /path:/$Name /physicalPath:"$Path"       
}

function Install-IisWebsite
{
    <# 
    .SYNOPSIS
    Installs a website.

    .DESCRIPTION
    Installs a website named `Name`, serving files out of the file system from `Path`.  If no app pool name is given (via the `AppPoolName` parameter), IIS will pick one for you, usually the `DefaultAppPool`.  If a site with name `Name` already exists, it is deleted, and a new site is created.

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

    .EXAMPLE
    Install-IisWebsite -Name 'Peanuts' -Path C:\Peanuts.com

    Creates a website named `Peanuts` serving files out of the `C:\Peanuts.com` directory.  The website listens on all the computer's IP addresses on port 80.

    .EXAMPLE
    Install-IisWebsite -Name 'Peanuts' -Path C:\Peanuts.com -Bindings 'http/*:80:peanuts.com:'

    Creates a website named `Peanuts` which uses name-based hosting to respond to all requests to any of the machine's IP addresses for the `peanuts.com` domain.

    .EXAMPLE
    Install-IisWebsite -Name 'Peanuts' -Path C:\Peanuts.com -AppPoolName 'PeanutsAppPool'

    Creates a website named `Peanuts` that runs under the `PeanutsAppPool` app pool
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        # The name of the website
        $Name,
        
        [Parameter(Position=1,Mandatory=$true)]
        [string]
        # The path to the website
        $Path,
        
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
        Remove-IisWebsite -Name $Name
    }
    
    if( -not (Test-Path $Path -PathType Container) )
    {
        $null = New-Item $Path -ItemType Directory -Force
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
    Invoke-AppCmd add site /name:"$Name" /physicalPath:"$Path" /bindings:$bindingsArg
    
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

function Invoke-AppCmd
{
    <#
    .SYNOPSIS
    Invokes appcmd.exe, the IIS command line configuration utility.

    .DESCRIPTION
    Runs appcmd.exe, passing all the arguments that get passed to `Invoke-AppCmd`.

    .EXAMPLE
    Invoke-AppCmd list site Peanuts

    Runs `appcmd.exe list site Peanuts`, which will list the configuration for the Peanuts website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        # The arguments to pass to appcmd.
        $AppCmdArgs
    )
    
    Write-Verbose ($AppCmdArgs -join " ")
    & (Join-Path $env:SystemRoot 'System32\inetsrv\appcmd.exe') $AppCmdArgs
    if( $LastExitCode -ne 0 )
    {
        Write-Error "``AppCmd $($AppCmdArgs)`` exited with code $LastExitCode."
    }
}

function Remove-IisWebsite
{
    <#
    .SYNOPSIS
    Removes a website

    .DESCRIPTION
    Pretty simple: removes the website named `Name`.  If no website with that name exists, nothing happens.

    .EXAMPLE
    Remove-IisWebsite -Name 'MyWebsite'
    
    Removes MyWebsite.

    .EXAMPLE
    Remove-IisWebsite 1

    Removes the website whose ID is 1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        # The name or ID of the website to remove.
        $Name
    )
    
    if( Test-IisWebsite -Name $Name )
    {
        Invoke-AppCmd delete site `"$Name`"
    }
}

function Enable-IisDirectoryBrowsing
{
    <#
    .SYNOPSIS
    Enables directory browsing under all or part of a website.

    .DESCRIPTION
    Enables directory browsing (i.e. showing the contents of a directory by requesting that directory in a web browser) for a website.  To enable directory browsing on a directory under the website, pass the virtual path to that directory as the value to the `Directory` parameter.

    .EXAMPLE
    Enable-IisDirectoryBrowsing -SiteName Peanuts

    Enables directory browsing on the `Peanuts` website.

    .EXAMPLE
    Enable-IisDirectoryBrowsing -SiteName Peanuts -Directory Snoopy/DogHouse

    Enables directory browsing on the `/Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the site where the virtual directory is located.
        $SiteName,
        
        [string]
        # The directory where directory browsing should be enabled.
        $Path
    )
    
    $location = "$SiteName$Path"
    if( $Path -notlike '/*' )
    {
        $location = "$SiteName/$Path"
    }
    
    Write-Verbose "Enabling directory browsing at location '$location'."
    Invoke-AppCmd set config `"$location`" /section:directoryBrowse /enabled:true /commit:apphost
}

function Set-IisHttpRedirect
{
    <#
    .SYNOPSIS
    Turns on HTTP redirect for all or part of a website.

    .DESCRIPTION
    Configures all or part of a website to redirect all requests to another website/URL.  By default, it operates on a specific website.  To configure a directory under a website, set `Path` to the virtual path of that directory.

    .LINK
    http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx

    .EXAMPLE
    Set-IisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-IisHttpRedirect -SiteName Peanuts -Path Snoopy/DogHouse -Destination 'http://new.peanuts.com'

    Redirects all requests to the `/Snoopy/DogHouse` path on the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-IisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com' -StatusCode 'Temporary'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com` with a temporary HTTP status code.  You can also specify `Found` (HTTP 302), or `Permanent` (HTTP 301).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the redirection should be setup.
        $SiteName,
        
        [string]
        # The optional path where redirection should be setup.
        $Path = '',
        
        [Parameter(Mandatory=$true)]
        [string]
        # The destination to redirect to.
        $Destination,
        
        [ValidateSet('Found','Permanent','Temporary')]
        [string]
        # The HTTP status code to use.  Default is `Found`.  Should be one of `Found` (HTTP 302), `Permanent` (HTTP 301), or `Temporary` (HTTP 307).
        $StatusCode = 'Found',
        
        [Switch]
        # Redirect all requests to exact destination (instead of relative to destination).  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
        $ExactDestination,
        
        [Switch]
        # Only redirect requests to content in site and/or path, but nothing below it.  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
        $ChildOnly
    )
    
    $statusArg = "/httpResponseStatus:$StatusCode"
    $exactDestinationArg =  "/exactDestination:$ExactDestination"
    $childOnlyArg = "/childOnly:$ChildOnly"
    
    Write-Host "Updating IIS settings for $SiteName/$Path to redirect to $destination."
    Invoke-AppCmd set config "$SiteName/$Path" /section:httpRedirect /enabled:true /destination:$destination $statusArg $exactDestinationArg $childOnlyArg /commit:apphost
}

function Enable-IisSsl
{
    <#
    .SYNOPSIS
    Turns on and configures SSL for a website or part of a website.

    .DESCRIPTION
    This function enables SSL and optionally the site/directory to: 

     * Require SSL (the `RequireSsl` switch)
     * Ignore/accept/require client certificates (the `AcceptClientCertificates` and `RequireClientCertificates` switches).
     * Requiring 128-bit SSL (the `Require128BitSsl` switch).

    By default, this function will enable SSL, make SSL connections optional, ignores client certificates, and not require 128-bit SSL.

    Changing any SSL settings will do you no good if the website doesn't have an SSL binding or doesn't have an SSL certificate.  The configuration will most likely succeed, but won't work in a browser.  So sad.
    
    Beginning with IIS 7.5, the `Require128BitSsl` parameter won't actually change the behavior of a website since [there are no longer 128-bit crypto providers](https://forums.iis.net/p/1163908/1947203.aspx) in versions of Windows running IIS 7.5.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts

    Enables SSL on the `Peanuts` website's, making makes SSL connections optional, ignoring client certificates, and making 128-bit SSL optional.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -Path Snoopy/DogHouse -RequireSsl
    
    Configures the `/Snoopy/DogHouse` directory in the `Peanuts` site to require SSL.  It also turns off any client certificate settings and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -AcceptClientCertificates

    Enables SSL on the `Peanuts` website and configures it to accept client certificates, makes SSL optional, and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -RequireSsl -RequireClientCertificates

    Enables SSL on the `Peanuts` website and configures it to require SSL and client certificates.  You can't require client certificates without also requiring SSL.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -Require128BitSsl

    Enables SSL on the `Peanuts` website and require 128-bit SSL.  Also, makes SSL connections optional and ignores client certificates.

    .LINK
    Set-IisWebsiteSslCertificate
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='IgnoreClientCertificates')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The website whose SSL flags should be modifed.
        $SiteName,
        
        [string]
        # The path to the folder/virtual directory/application under the website whose SSL flags should be set.
        $Path = '',
        
        [Parameter(ParameterSetName='IgnoreClientCertificates')]
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Parameter(Mandatory=$true,ParameterSetName='RequireClientCertificates')]
        [Switch]
        # Should SSL be required?
        $RequireSsl,
        
        [Switch]
        # Requires 128-bit SSL.  Only changes IIS behavior in IIS 7.0.
        $Require128BitSsl,
        
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Switch]
        # Should client certificates be accepted?
        $AcceptClientCertificates,
        
        [Parameter(Mandatory=$true,ParameterSetName='RequireClientCertificates')]
        [Switch]
        # Should client certificates be required?  Also requires SSL ('RequireSsl` switch).
        $RequireClientCertificates
    )
    
    $flags = @()
    if( $RequireSSL -or $RequireClientCertificates )
    {
        $flags += 'Ssl'
    }
    
    if( $AcceptClientCertificates -or $RequireClientCertificates )
    {
        $flags += 'SslNegotiateCert'
    }
    
    if( $RequireClientCertificates )
    {
        $flags += 'SslRequireCert'
    }
    
    if( $Require128BitSsl )
    {
        $flags += 'Ssl128'
    }
    
    if( $pscmdlet.ShouldProcess( "$SiteName/$Path", "enable SSL" ) )
    {
        Invoke-AppCmd set config "$SiteName/$Path" "-section:system.webServer/security/access" "/sslFlags:""$($flags -join ',')""" /commit:apphost
    }
}

function Set-IisWebsiteSslCertificate
{
    <#
    .SYNOPSIS
    Sets a website's SSL certificate.

    .DESCRIPTION
    SSL won't work on a website if an SSL certificate hasn't been bound to all the IP addresses it's listening on.  This function binds a certificate to all a website's IP addresses.  Make sure you call this method *after* you create a website's bindings.  Any previous SSL bindings on those IP addresses are deleted.

    .EXAMPLE
    Set-IisWebsiteSslCertificate -SiteName Peanuts -Thumbprint 'a909502dd82ae41433e6f83886b00d4277a32a7b' -ApplicationID $PeanutsAppID

    Binds the certificate whose thumbprint is `a909502dd82ae41433e6f83886b00d4277a32a7b` to the `Peanuts` website.  It's a good idea to re-use the same GUID for each distinct application.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose SSL certificate is being set.
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The thumbprint of the SSL certificate to use.
        $Thumbprint,

        [Parameter(Mandatory=$true)]        
        [Guid]
        # A GUID that uniquely identifies this website.  Create your own.
        $ApplicationID
    )
    
    $site = Get-IisWebsite -SiteName $SiteName
    if( -not $site ) 
    {
        Write-Error "Unable to find website '$SiteName'."
        return
    }
    
    $site.Bindings | Where-Object { $_.Protocol -eq 'https' } | ForEach-Object {
        $ipAddress = $_.IPAddress
        if( $ipAddress -eq '*' )
        {
            $ipAddress = '0.0.0.0'
        }
        Set-SslCertificateBinding -IPPort "$IPAddress`:$($_.Port)" -ApplicationID $ApplicationID -Thumbprint $Thumbprint
    }
}

function Test-IisAppPoolExists
{
    <# 
    .SYNOPSIS
    Checks if an app pool exists.

    .DESCRIPTION 
    Returns `True` if an app pool with `Name` exists.  `False` if it doesn't exist.

    .EXAMPLE
    Test-IisAppPoolExists -Name Peanuts

    Returns `True` if the Peanuts app pool exists, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app pool.
        $Name
    )
    
    $apppools = Invoke-AppCmd list apppool
    foreach( $apppool in $apppools )
    {
        if( $apppool -match "^APPPOOL ""$Name""" )
        {
            return $true
        }
    }
    return $false
}

function Test-IisWebsite
{
    <#
    .SYNOPSIS
    Tests if a website exists.

    .DESCRIPTION
    Returns `True` if a website with name `Name` exists.  `False` if it doesn't.

    .EXAMPLE
    Test-IisWebsite -Name 'Peanuts'

    Returns `True` if the `Peanuts` website exists.  `False` if it doesn't.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose existence to check.
        $Name
    )
    
    $output = Invoke-AppCmd list site -ErrorAction SilentlyContinue
    foreach( $line in $output )
    {
        if( $line -like "SITE ""$Name""*" )
        {
            return $true
        }
    }
    return $false
}

function Unlock-IisBasicAuthentication
{
    <#
    .SYNOPSIS
    Unlocks basic authentication IIS configuration so that sites can enable/disable basic authentication.

    .DESCRIPTION
    By default, IIS locks the basic authentication configuration, so that no sites can enable it.  This function unlocks it so Windows authentication can be enabled.  Specifically, it unlocks the `system.webServer/security/authentication/basicAuthentication` IIS configuration section.

    .EXAMPLE
    Unlock-IisBasicAuthentication

    Unlocks basic authentication configuration so that websites can enable, configure and use basic authentication.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    $commonParams = @{}
    if( $pscmdlet.MyInvocation.BoundParameters.ContainsKey('WhatIf') )
    {
        $commonParams.WhatIf = $true
    }
    
    Unlock-IisConfigSection -Name basicAuthentication @commonParams
}

function Unlock-IisCgi
{
    <#
    .SYNOPSIS
    Unlocks CGI IIS configuration so that websites can configure their own CGI settings.

    .DESCRIPTION
    By default, IIS locks the CGI section so that no websites can enable or configure it.  This function unlocks CGI configuration so that websites can configure their own CGI settings.  Specifically, it unlocks the `system.webServer/cgi` IIS configuration section.

    .EXAMPLE
    Unlock-IisCgi

    Unlocks the CGI IIS configuration section so that websites can configure their own CGI settings.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    $commonParams = @{}
    if( $pscmdlet.MyInvocation.BoundParameters.ContainsKey('WhatIf') )
    {
        $commonParams.WhatIf = $true
    }
    
    Unlock-IisConfigSection -Name cgi @commonParams
}

function Unlock-IisConfigSection
{
    <#
    .SYNOPSIS
    Unlocks a section in the IIS server configuration.

    .DESCRIPTION
    Some sections/areas are locked by IIS, so that websites can't enable those settings, or have their own custom configurations.  This function will unlocks those locked sections.  You have to know the path to the section.  You can see a list of locked sections by running:

        C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?

    .EXAMPLE
    Unlock-IisConfigSection -Name 'system.webServer/cgi'

    Unlocks the CGI section so that websites can configure their own CGI settings.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the section to unlock.  For a list of sections, run
        #
        #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
        $Name
    )
    
    if( $pscmdlet.ShouldProcess( $Name, 'unlocking config section' ) )
    {
        Write-Host "Unlocking IIS configuration section '$Name'."
        Invoke-AppCmd unlock config "/section:$Name"
    }
}

function Unlock-IisWindowsAuthentication
{
    <#
    .SYNOPSIS
    Unlocks Windows authentication IIS configuration so that sites can enable/disable Windows authentication.

    .DESCRIPTION
    By default, IIS locks the Windows authentication configuration, so that no sites can enable it.  This function unlocks it so Windows authentication can be enabled.  Specifically, it unlocks the `system.webServer/security/authentication/windowsAuthentication` IIS configuration section.

    .EXAMPLE
    Unlock-IisWindowsAuthentication

    Unlocks Windows authentication configuration so that websites can enable, configure and use Windows authentication.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    $commonParams = @{}
    if( $pscmdlet.MyInvocation.BoundParameters.ContainsKey('WhatIf') )
    {
        $commonParams.WhatIf = $true
    }
    
    Unlock-IisConfigSection -Name windowsAuthentication @commonParams
}
