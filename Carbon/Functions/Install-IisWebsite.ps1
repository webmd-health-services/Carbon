
function Install-CIisWebsite
{
    <# 
    .SYNOPSIS
    Installs a website.

    .DESCRIPTION
    `Install-CIisWebsite` installs an IIS website. Anonymous authentication is enabled, and the anonymous user is set to the website's application pool identity. Before Carbon 2.0, if a website already existed, it was deleted and re-created. Beginning with Carbon 2.0, existing websites are modified in place. 
    
    If you don't set the website's app pool, IIS will pick one for you (usually `DefaultAppPool`), and `Install-CIisWebsite` will never manage the app pool for you (i.e. if someone changes it manually, this function won't set it back to the default). We recommend always supplying an app pool name, even if it is `DefaultAppPool`.

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

     ## Troubleshooting

     In some situations, when you add a website to an application pool that another website/application is part of, the new website will fail to load in a browser with a 500 error saying `Failed to map the path '/'.`. We've been unable to track down the root cause. The solution is to recycle the app pool, e.g. `(Get-CIisAppPool -Name 'AppPoolName').Recycle()`.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisWebsite
    
    .LINK
    Uninstall-CIisWebsite

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com

    Creates a website named `Peanuts` serving files out of the `C:\Peanuts.com` directory.  The website listens on all the computer's IP addresses on port 80.

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -Binding 'http/*:80:peanuts.com'

    Creates a website named `Peanuts` which uses name-based hosting to respond to all requests to any of the machine's IP addresses for the `peanuts.com` domain.

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -AppPoolName 'PeanutsAppPool'

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
        [Alias('Bindings')]
        [string[]]
        # The site's network bindings.  Default is `http/*:80:`.  Bindings should be specified in protocol/IPAddress:Port:Hostname format.  
        #
        #  * Protocol should be http or https. 
        #  * IPAddress can be a literal IP address or `*`, which means all of the computer's IP addresses.  This function does not validate if `IPAddress` is actually in use on this computer.
        #  * Leave hostname blank for non-named websites.
        $Binding = @('http/*:80:'),
        
        [string]
        # The name of the app pool under which the website runs.  The app pool must exist.  If not provided, IIS picks one for you.  No whammy, no whammy! It is recommended that you create an app pool for each website. That's what the IIS Manager does.
        $AppPoolName,

        [int]
        # The site's IIS ID. IIS picks one for you automatically if you don't supply one. Must be greater than 0.
        #
        # The `SiteID` switch is new in Carbon 2.0.
        $SiteID,

        [Switch]
        # Return a `Microsoft.Web.Administration.Site` object for the website.
        #
        # The `PassThru` switch is new in Carbon 2.0.
        $PassThru,

        [Switch]
        # Deletes the website before installation, if it exists. Preserves default beheaviro in Carbon before 2.0.
        #
        # The `Force` switch is new in Carbon 2.0.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $bindingRegex = '^(?<Protocol>https?):?//?(?<IPAddress>\*|[\d\.]+):(?<Port>\d+):?(?<HostName>.*)$'

    filter ConvertTo-Binding
    {
        param(
            [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
            [string]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $InputObject -match $bindingRegex | Out-Null
        [pscustomobject]@{ 
                            'Protocol' = $Matches['Protocol'];
                            'IPAddress' = $Matches['IPAddress'];
                            'Port' = $Matches['Port'];
                            'HostName' = $Matches['HostName'];
                          } |
                            Add-Member -MemberType ScriptProperty -Name 'BindingInformation' -Value { '{0}:{1}:{2}' -f $this.IPAddress,$this.Port,$this.HostName } -PassThru
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        New-Item $PhysicalPath -ItemType Directory | Out-String | Write-Verbose
    }
    
    $invalidBindings = $Binding | 
                           Where-Object { $_ -notmatch $bindingRegex } 
    if( $invalidBindings )
    {
        $invalidBindings = $invalidBindings -join "`n`t"
        $errorMsg = "The following bindings are invalid. The correct format is protocol/IPAddress:Port:Hostname. Protocol and IP address must be separted by a single slash, not ://. IP address can be * for all IP addresses. Hostname is optional. If hostname is not provided, the binding must end with a colon.`n`t{0}" -f $invalidBindings
        Write-Error $errorMsg
        return
    }

    if( $Force )
    {
        Uninstall-CIisWebsite -Name $Name
    }

    [Microsoft.Web.Administration.Site]$site = $null
    $modified = $false
    if( -not (Test-CIisWebsite -Name $Name) )
    {
        Write-Verbose -Message ('Creating website ''{0}'' ({1}).' -f $Name,$PhysicalPath)
        $firstBinding = $Binding | Select-Object -First 1 | ConvertTo-Binding
        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $site = $mgr.Sites.Add( $Name, $firstBinding.Protocol, $firstBinding.BindingInformation, $PhysicalPath )
        $mgr.CommitChanges()
    }

    $site = Get-CIisWebsite -Name $Name

    $expectedBindings = New-Object 'Collections.Generic.Hashset[string]'
    $Binding | ConvertTo-Binding | ForEach-Object { [void]$expectedBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }

    $bindingsToRemove = $site.Bindings | Where-Object { -not $expectedBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }
    foreach( $bindingToRemove in $bindingsToRemove )
    {
        Write-IisVerbose $Name 'Binding' ('{0}/{1}' -f $bindingToRemove.Protocol,$bindingToRemove.BindingInformation)
        $site.Bindings.Remove( $bindingToRemove )
        $modified = $true
    }

    $existingBindings = New-Object 'Collections.Generic.Hashset[string]'
    $site.Bindings | ForEach-Object { [void]$existingBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }
    $bindingsToAdd = $Binding | ConvertTo-Binding | Where-Object { -not $existingBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }
    foreach( $bindingToAdd in $bindingsToAdd )
    {
        Write-IisVerbose $Name 'Binding' '' ('{0}/{1}' -f $bindingToAdd.Protocol,$bindingToAdd.BindingInformation)
        $site.Bindings.Add( $bindingToAdd.BindingInformation, $bindingToAdd.Protocol ) | Out-Null
        $modified = $true
    }
    
    [Microsoft.Web.Administration.Application]$rootApp = $null
    if( $site.Applications.Count -eq 0 )
    {
        $rootApp = $site.Applications.Add("/", $PhysicalPath)
        $modifed = $true
    }
    else
    {
        $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    }

    if( $site.PhysicalPath -ne $PhysicalPath )
    {
        Write-IisVerbose $Name 'PhysicalPath' $site.PhysicalPath $PhysicalPath 
        [Microsoft.Web.Administration.VirtualDirectory]$vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq '/' }
        $vdir.PhysicalPath = $PhysicalPath
        $modified = $true
    }
    
    if( $AppPoolName )
    {
        if( $rootApp.ApplicationPoolName -ne $AppPoolName )
        {
            Write-IisVerbose $Name 'AppPool' $rootApp.ApplicationPoolName $AppPoolName 
            $rootApp.ApplicationPoolName = $AppPoolName
            $modified = $true
        }
    }

    if( $modified )
    {
        $site.CommitChanges()
    }
    
    if( $SiteID )
    {
        Set-CIisWebsiteID -SiteName $Name -ID $SiteID
    }
    
    # Make sure anonymous authentication is enabled and uses the application pool identity
    $security = Get-CIisSecurityAuthentication -SiteName $Name -VirtualPath '/' -Anonymous
    Write-IisVerbose $Name 'Anonymous Authentication UserName' $security['username'] ''
    $security['username'] = ''
    $security.CommitChanges()

    # Now, wait until site is actually running
    $tries = 0
    $website = $null
    do
    {
        $website = Get-CIisWebsite -SiteName $Name
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

    if( $PassThru )
    {
        return $website
    }
}

