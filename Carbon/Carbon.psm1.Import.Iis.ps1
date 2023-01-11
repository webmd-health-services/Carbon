
if( $exportIisFunctions )
{
    function Add-CIisDefaultDocument
    {
        <#
        .SYNOPSIS
        Adds a default document name to a website.

        .DESCRIPTION
        If you need a custom default document for your website, this function will add it.  The `FileName` argument should be a filename IIS should use for a default document, e.g. home.html.

        If the website already has `FileName` in its list of default documents, this function silently returns.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Add-CIisDefaultDocument -SiteName MySite -FileName home.html

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
            # The default document to add.
            $FileName,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/defaultDocument' -NoWarn
        if( -not $section )
        {
            return
        }

        [Microsoft.Web.Administration.ConfigurationElementCollection]$files = $section.GetCollection('files')
        $defaultDocElement = $files | Where-Object { $_["value"] -eq $FileName }
        if( -not $defaultDocElement )
        {
            Write-IisVerbose $SiteName 'Default Document' '' $FileName -NoWarn
            $defaultDocElement = $files.CreateElement('add')
            $defaultDocElement["value"] = $FileName
            $files.Add( $defaultDocElement )
            $section.CommitChanges()
        }
    }


    filter Add-IisServerManagerMember
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            # The object on which the server manager members will be added.
            $InputObject,

            [Parameter(Mandatory=$true)]
            [Microsoft.Web.Administration.ServerManager]
            # The server manager object to use as the basis for the new members.
            $ServerManager,

            [Switch]
            # If set, will return the input object.
            $PassThru,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $InputObject |
            Add-Member -MemberType NoteProperty -Name 'ServerManager' -Value $ServerManager -PassThru |
            Add-Member -MemberType ScriptMethod -Name 'CommitChanges' -Value { $this.ServerManager.CommitChanges() }

        if( $PassThru )
        {
            return $InputObject
        }
    }


    function Disable-CIisSecurityAuthentication
    {
        <#
        .SYNOPSIS
        Disables anonymous or basic authentication for all or part of a website.

        .DESCRIPTION
        By default, disables an authentication type for an entire website.  You can disable an authentication type at a specific path under a website by passing the virtual path (*not* the physical path) to that directory as the value of the `VirtualPath` parameter.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        Enable-CIisSecurityAuthentication

        .LINK
        Get-CIisSecurityAuthentication

        .LINK
        Test-CIisSecurityAuthentication

        .EXAMPLE
        Disable-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

        Turns off anonymous authentication for the `Peanuts` website.

        .EXAMPLE
        Disable-CIisSecurityAuthentication -SiteName Peanuts Snoopy/DogHouse -Basic

        Turns off basic authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where anonymous authentication should be set.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path where anonymous authentication should be set.
            $VirtualPath = '',

            [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
            [Switch]
            # Enable anonymouse authentication.
            $Anonymous,

            [Parameter(Mandatory=$true,ParameterSetName='Basic')]
            [Switch]
            # Enable basic authentication.
            $Basic,

            [Parameter(Mandatory=$true,ParameterSetName='Windows')]
            [Switch]
            # Enable Windows authentication.
            $Windows,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $authType = $pscmdlet.ParameterSetName
        $getArgs = @{ $authType = $true; }
        $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getArgs -NoWarn

        if( -not $authSettings.GetAttributeValue('enabled') )
        {
            return
        }

        $authSettings.SetAttributeValue('enabled', 'False')
        $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn
        if( $pscmdlet.ShouldProcess( $fullPath, ("disable {0} authentication" -f $authType) ) )
        {
            $authSettings.CommitChanges()
        }
    }


    function Enable-CIisDirectoryBrowsing
    {
        <#
        .SYNOPSIS
        Enables directory browsing under all or part of a website.

        .DESCRIPTION
        Enables directory browsing (i.e. showing the contents of a directory by requesting that directory in a web browser) for a website.  To enable directory browsing on a directory under the website, pass the virtual path to that directory as the value to the `Directory` parameter.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Enable-CIisDirectoryBrowsing -SiteName Peanuts

        Enables directory browsing on the `Peanuts` website.

        .EXAMPLE
        Enable-CIisDirectoryBrowsing -SiteName Peanuts -Directory Snoopy/DogHouse

        Enables directory browsing on the `/Snoopy/DogHouse` directory under the `Peanuts` website.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the site where the virtual directory is located.
            $SiteName,

            [Alias('Path')]
            [string]
            # The directory where directory browsing should be enabled.
            $VirtualPath,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $section = Get-CIisConfigurationSection -SiteName $SiteName -SectionPath 'system.webServer/directoryBrowse' -NoWarn

        if( $section['enabled'] -ne 'true' )
        {
            Write-IisVerbose $SiteName 'Directory Browsing' 'disabled' 'enabled' -NoWarn
            $section['enabled'] = $true
            $section.CommitChanges()
        }

    }


    function Enable-CIisSecurityAuthentication
    {
        <#
        .SYNOPSIS
        Enables anonymous or basic authentication for an entire site or a sub-directory of that site.

        .DESCRIPTION
        By default, enables an authentication type on an entire website.  You can enable an authentication type at a specific path under a website by passing the virtual path (*not* the physical path) to that directory as the value of the `VirtualPath` parameter.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        Disable-CIisSecurityAuthentication

        .LINK
        Get-CIisSecurityAuthentication

        .LINK
        Test-CIisSecurityAuthentication

        .EXAMPLE
        Enable-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

        Turns on anonymous authentication for the `Peanuts` website.

        .EXAMPLE
        Enable-CIisSecurityAuthentication -SiteName Peanuts Snoopy/DogHouse -Basic

        Turns on anonymous authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.

        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where anonymous authentication should be set.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path where anonymous authentication should be set.
            $VirtualPath = '',

            [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
            [Switch]
            # Enable anonymouse authentication.
            $Anonymous,

            [Parameter(Mandatory=$true,ParameterSetName='Basic')]
            [Switch]
            # Enable basic authentication.
            $Basic,

            [Parameter(Mandatory=$true,ParameterSetName='Windows')]
            [Switch]
            # Enable Windows authentication.
            $Windows,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $authType = $pscmdlet.ParameterSetName
        $getArgs = @{ $authType = $true; }
        $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getArgs -NoWarn

        if( $authSettings.GetAttributeValue('enabled') )
        {
            return
        }

        $authSettings.SetAttributeValue('enabled', 'true')

        $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn
        if( $pscmdlet.ShouldProcess( $fullPath, ("enable {0}" -f $authType) ) )
        {
            $authSettings.CommitChanges()
        }
    }


    function Enable-CIisSsl
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

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        http://support.microsoft.com/?id=907274

        .EXAMPLE
        Enable-CIisSsl -Site Peanuts

        Enables SSL on the `Peanuts` website's, making makes SSL connections optional, ignoring client certificates, and making 128-bit SSL optional.

        .EXAMPLE
        Enable-CIisSsl -Site Peanuts -VirtualPath Snoopy/DogHouse -RequireSsl

        Configures the `/Snoopy/DogHouse` directory in the `Peanuts` site to require SSL.  It also turns off any client certificate settings and makes 128-bit SSL optional.

        .EXAMPLE
        Enable-CIisSsl -Site Peanuts -AcceptClientCertificates

        Enables SSL on the `Peanuts` website and configures it to accept client certificates, makes SSL optional, and makes 128-bit SSL optional.

        .EXAMPLE
        Enable-CIisSsl -Site Peanuts -RequireSsl -RequireClientCertificates

        Enables SSL on the `Peanuts` website and configures it to require SSL and client certificates.  You can't require client certificates without also requiring SSL.

        .EXAMPLE
        Enable-CIisSsl -Site Peanuts -Require128BitSsl

        Enables SSL on the `Peanuts` website and require 128-bit SSL.  Also, makes SSL connections optional and ignores client certificates.

        .LINK
        Set-CIisWebsiteSslCertificate
        #>
        [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='IgnoreClientCertificates')]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The website whose SSL flags should be modifed.
            $SiteName,

            [Alias('Path')]
            [string]
            # The path to the folder/virtual directory/application under the website whose SSL flags should be set.
            $VirtualPath = '',

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
            $RequireClientCertificates,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $SslFlags_Ssl = 8
        $SslFlags_SslNegotiateCert = 32
        $SslFlags_SslRequireCert = 64
        $SslFlags_SslMapCert = 128
        $SslFlags_Ssl128 = 256

        $intFlag = 0
        $flags = @()
        if( $RequireSSL -or $RequireClientCertificates )
        {
            $flags += 'Ssl'
            $intFlag = $intFlag -bor $SslFlags_Ssl
        }

        if( $AcceptClientCertificates -or $RequireClientCertificates )
        {
            $flags += 'SslNegotiateCert'
            $intFlag = $intFlag -bor $SslFlags_SslNegotiateCert
        }

        if( $RequireClientCertificates )
        {
            $flags += 'SslRequireCert'
            $intFlag = $intFlag -bor $SslFlags_SslRequireCert
        }

        if( $Require128BitSsl )
        {
            $flags += 'Ssl128'
            $intFlag = $intFlag -bor $SslFlags_Ssl128
        }

        $section = Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath 'system.webServer/security/access' -NoWarn
        if( -not $section )
        {
            return
        }

        $flags = $flags -join ','
        $currentIntFlag = $section['sslFlags']
        $currentFlags = @( )
        if( $currentIntFlag -band $SslFlags_Ssl )
        {
            $currentFlags += 'Ssl'
        }
        if( $currentIntFlag -band $SslFlags_SslNegotiateCert )
        {
            $currentFlags += 'SslNegotiateCert'
        }
        if( $currentIntFlag -band $SslFlags_SslRequireCert )
        {
            $currentFlags += 'SslRequireCert'
        }
        if( $currentIntFlag -band $SslFlags_SslMapCert )
        {
            $currentFlags += 'SslMapCert'
        }
        if( $currentIntFlag -band $SslFlags_Ssl128 )
        {
            $currentFlags += 'Ssl128'
        }

        if( -not $currentFlags )
        {
            $currentFlags += 'None'
        }

        $currentFlags = $currentFlags -join ','


        if( $section['sslFlags'] -ne $intFlag )
        {
            Write-IisVerbose $SiteName 'SslFlags' ('{0} ({1})' -f $currentIntFlag,$currentFlags) ('{0} ({1})' -f $intFlag,$flags) -VirtualPath $VirtualPath -NoWarn
            $section['sslFlags'] = $flags
            if( $pscmdlet.ShouldProcess( (Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn), "enable SSL" ) )
            {
                $section.CommitChanges()
            }
        }
    }


    function Get-CIisApplication
    {
        <#
        .SYNOPSIS
        Gets an IIS application as an `Application` object.

        .DESCRIPTION
        Uses the `Microsoft.Web.Administration` API to get an IIS application object.  If the application doesn't exist, `$null` is returned.

        The objects returned have two dynamic properties and one dynamic methods added.

        * `ServerManager { get; }` - The `ServerManager` object which created the `Application` object.
        * `CommitChanges()` - Persists any configuration changes made to the object back into IIS's configuration files.
        * `PhysicalPath { get; }` - The physical path to the application.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        Microsoft.Web.Administration.Application.

        .EXAMPLE
        Get-CIisApplication -SiteName 'DeathStar`

        Gets all the applications running under the `DeathStar` website.

        .EXAMPLE
        Get-CIisApplication -SiteName 'DeathStar' -VirtualPath '/'

        Demonstrates how to get the main application for a website: use `/` as the application name.

        .EXAMPLE
        Get-CIisApplication -SiteName 'DeathStar' -VirtualPath 'MainPort/ExhaustPort'

        Demonstrates how to get a nested application, i.e. gets the application at `/MainPort/ExhaustPort` under the `DeathStar` website.
        #>
        [CmdletBinding()]
        [OutputType([Microsoft.Web.Administration.Application])]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where the application is running.
            $SiteName,

            [Parameter()]
            [Alias('Name')]
            [string]
            # The name of the application.  Default is to return all applications running under the website `$SiteName`.
            $VirtualPath,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $site = Get-CIisWebsite -SiteName $SiteName -NoWarn
        if( -not $site )
        {
            return
        }

        $site.Applications |
            Where-Object {
                if( $VirtualPath )
                {
                    return ($_.Path -eq "/$VirtualPath")
                }
                return $true
            } |
            Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru -NoWarn
    }


    function Get-CIisAppPool
    {
        <#
        .SYNOPSIS
        Gets a `Microsoft.Web.Administration.ApplicationPool` object for an application pool.

        .DESCRIPTION
        The `Get-CIisAppPool` function returns an IIS application pools as a `Microsoft.Web.Administration.ApplicationPool` object. Use the `Name` parameter to return the application pool. If that application pool isn't found, `$null` is returned.

        Carbon adds a `CommitChanges` method on each object returned that you can use to save configuration changes.

        Beginning in Carbon 2.0, `Get-CIisAppPool` will return all application pools installed on the current computer.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        http://msdn.microsoft.com/en-us/library/microsoft.web.administration.applicationpool(v=vs.90).aspx

        .OUTPUTS
        Microsoft.Web.Administration.ApplicationPool.

        .EXAMPLE
        Get-CIisAppPool

        Demonstrates how to get *all* application pools.

        .EXAMPLE
        Get-CIisAppPool -Name 'Batcave'

        Gets the `Batcave` application pool.

        .EXAMPLE
        Get-CIisAppPool -Name 'Missing!'

        Returns `null` since, for purposes of this example, there is no `Missing~` application pool.
        #>
        [CmdletBinding()]
        [OutputType([Microsoft.Web.Administration.ApplicationPool])]
        param(
            [string]
            # The name of the application pool to return. If not supplied, all application pools are returned.
            $Name,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $mgr = New-Object Microsoft.Web.Administration.ServerManager
        $mgr.ApplicationPools |
            Where-Object {
                if( -not $PSBoundParameters.ContainsKey('Name') )
                {
                    return $true
                }
                return $_.Name -eq $Name
            } |
            Add-IisServerManagerMember -ServerManager $mgr -PassThru -NoWarn
    }


    function Get-CIisConfigurationSection
    {
        <#
        .SYNOPSIS
        Gets a Microsoft.Web.Adminisration configuration section for a given site and path.

        .DESCRIPTION
        Uses the Microsoft.Web.Administration API to get a `Microsoft.Web.Administration.ConfigurationSection`.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        Microsoft.Web.Administration.ConfigurationSection.

        .EXAMPLE
        Get-CIisConfigurationSection -SiteName Peanuts -Path Doghouse -Path 'system.webServer/security/authentication/anonymousAuthentication'

        Returns a configuration section which represents the Peanuts site's Doghouse path's anonymous authentication settings.
        #>
        [CmdletBinding(DefaultParameterSetName='Global')]
        [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
        param(
            [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
            [string]
            # The site whose configuration should be returned.
            $SiteName,

            [Parameter(ParameterSetName='ForSite')]
            [Alias('Path')]
            [string]
            # The optional site path whose configuration should be returned.
            $VirtualPath = '',

            [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
            [Parameter(Mandatory=$true,ParameterSetName='Global')]
            [string]
            # The path to the configuration section to return.
            $SectionPath,

            [Type]
            # The type of object to return.  Optional.
            $Type = [Microsoft.Web.Administration.ConfigurationSection],

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $config = $mgr.GetApplicationHostConfiguration()

        $section = $null
        $qualifier = ''
        try
        {
            if( $PSCmdlet.ParameterSetName -eq 'ForSite' )
            {
                $qualifier = Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn
                $section = $config.GetSection( $SectionPath, $Type, $qualifier )
            }
            else
            {
                $section = $config.GetSection( $SectionPath, $Type )
            }
        }
        catch
        {
        }

        if( $section )
        {
            $section | Add-IisServerManagerMember -ServerManager $mgr -PassThru -NoWarn
        }
        else
        {
            Write-Error ('IIS:{0}: configuration section {1} not found.' -f $qualifier,$SectionPath)
            return
        }
    }


    function Get-CIisHttpHeader
    {
        <#
        .SYNOPSIS
        Gets the HTTP headers for a website or directory under a website.

        .DESCRIPTION
        For each custom HTTP header defined under a website and/or a sub-directory under a website, returns a `Carbon.Iis.HttpHeader` object.  This object has two properties:

        * Name: the name of the HTTP header
        * Value: the value of the HTTP header

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        Carbon.Iis.HttpHeader.

        .LINK
        Set-CIisHttpHeader

        .EXAMPLE
        Get-CIisHttpHeader -SiteName SopwithCamel

        Returns the HTTP headers for the `SopwithCamel` website.

        .EXAMPLE
        Get-CIisHttpHeader -SiteName SopwithCamel -Path Engine

        Returns the HTTP headers for the `Engine` directory under the `SopwithCamel` website.

        .EXAMPLE
        Get-CIisHttpHeader -SiteName SopwithCambel -Name 'X-*'

        Returns all HTTP headers which match the `X-*` wildcard.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the website whose headers to return.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path under `SiteName` whose headers to return.
            $VirtualPath = '',

            [string]
            # The name of the HTTP header to return.  Optional.  If not given, all headers are returned.  Wildcards supported.
            $Name = '*',

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $httpProtocol = Get-CIisConfigurationSection -SiteName $SiteName `
                                                    -VirtualPath $VirtualPath `
                                                    -SectionPath 'system.webServer/httpProtocol' `
                                                    -NoWarn
        $httpProtocol.GetCollection('customHeaders') |
            Where-Object { $_['name'] -like $Name } |
            ForEach-Object { New-Object Carbon.Iis.HttpHeader $_['name'],$_['value'] }
    }


    function Get-CIisHttpRedirect
    {
        <#
        .SYNOPSIS
        Gets the HTTP redirect settings for a website or virtual directory/application under a website.

        .DESCRIPTION
        Returns a `Carbon.Iis.HttpRedirectConfigurationSection` object for the given HTTP redirect settings.  The object contains the following properties:

        * Enabled - `True` if the redirect is enabled, `False` otherwise.
        * Destination - The URL where requests are directed to.
        * HttpResponseCode - The HTTP status code sent to the browser for the redirect.
        * ExactDestination - `True` if redirects are to destination, regardless of the request path.  This will send all requests to `Destination`.
        * ChildOnly - `True` if redirects are only to content in the destination directory (not subdirectories).

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        http://www.iis.net/configreference/system.webserver/httpredirect

        .OUTPUTS
        Carbon.Iis.HttpRedirectConfigurationSection.

        .EXAMPLE
        Get-CIisHttpRedirect -SiteName ExampleWebsite

        Gets the redirect settings for ExampleWebsite.

        .EXAMPLE
        Get-CIisHttpRedirect -SiteName ExampleWebsite -Path MyVirtualDirectory

        Gets the redirect settings for the MyVirtualDirectory virtual directory under ExampleWebsite.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site's whose HTTP redirect settings will be retrieved.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path to a sub-directory under `SiteName` whose settings to return.
            $VirtualPath = '',

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        Get-CIisConfigurationSection -SiteName $SiteName `
                                    -VirtualPath $VirtualPath `
                                    -SectionPath 'system.webServer/httpRedirect' `
                                    -Type ([Carbon.Iis.HttpRedirectConfigurationSection]) `
                                    -NoWarn
    }


    function Get-CIisMimeMap
    {
        <#
        .SYNOPSIS
        Gets the file extension to MIME type mappings.

        .DESCRIPTION
        IIS won't serve static content unless there is an entry for it in the web server or website's MIME map configuration. This function will return all the MIME maps for the current server.  The objects returned are instances of the `Carbon.Iis.MimeMap` class, and contain the following properties:

        * `FileExtension`: the mapping's file extension
        * `MimeType`: the mapping's MIME type

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        Carbon.Iis.MimeMap.

        .LINK
        Set-CIisMimeMap

        .EXAMPLE
        Get-CIisMimeMap

        Gets all the the file extension to MIME type mappings for the web server.

        .EXAMPLE
        Get-CIisMimeMap -FileExtension .htm*

        Gets all the file extension to MIME type mappings whose file extension matches the `.htm*` wildcard.

        .EXAMPLE
        Get-CIisMimeMap -MimeType 'text/*'

        Gets all the file extension to MIME type mappings whose MIME type matches the `text/*` wildcard.

        .EXAMPLE
        Get-CIisMimeMap -SiteName DeathStar

        Gets all the file extenstion to MIME type mappings for the `DeathStar` website.

        .EXAMPLE
        Get-CIisMimeMap -SiteName DeathStar -VirtualPath ExhaustPort

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
            $MimeType = '*',

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $getIisConfigSectionParams = @{ }
        if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
        {
            $getIisConfigSectionParams['SiteName'] = $SiteName
            $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
        }

        $staticContent = Get-CIisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams -NoWarn
        $staticContent.GetCollection() |
            Where-Object { $_['fileExtension'] -like $FileExtension -and $_['mimeType'] -like $MimeType } |
            ForEach-Object {
                New-Object 'Carbon.Iis.MimeMap' ($_['fileExtension'],$_['mimeType'])
            }
    }


    function Get-CIisSecurityAuthentication
    {
        <#
        .SYNOPSIS
        Gets a site's (and optional sub-directory's) security authentication configuration section.

        .DESCRIPTION
        You can get the anonymous, basic, digest, and Windows authentication sections by using the `Anonymous`, `Basic`, `Digest`, or `Windows` switches, respectively.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        Microsoft.Web.Administration.ConfigurationSection.

        .EXAMPLE
        Get-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

        Gets the `Peanuts` site's anonymous authentication configuration section.

        .EXAMPLE
        Get-CIisSecurityAuthentication -SiteName Peanuts -VirtualPath Doghouse -Basic

        Gets the `Peanuts` site's `Doghouse` sub-directory's basic authentication configuration section.
        #>
        [CmdletBinding()]
        [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where anonymous authentication should be set.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path where anonymous authentication should be set.
            $VirtualPath = '',

            [Parameter(Mandatory=$true,ParameterSetName='anonymousAuthentication')]
            [Switch]
            # Gets a site's (and optional sub-directory's) anonymous authentication configuration section.
            $Anonymous,

            [Parameter(Mandatory=$true,ParameterSetName='basicAuthentication')]
            [Switch]
            # Gets a site's (and optional sub-directory's) basic authentication configuration section.
            $Basic,

            [Parameter(Mandatory=$true,ParameterSetName='digestAuthentication')]
            [Switch]
            # Gets a site's (and optional sub-directory's) digest authentication configuration section.
            $Digest,

            [Parameter(Mandatory=$true,ParameterSetName='windowsAuthentication')]
            [Switch]
            # Gets a site's (and optional sub-directory's) Windows authentication configuration section.
            $Windows,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $sectionPath = 'system.webServer/security/authentication/{0}' -f $pscmdlet.ParameterSetName
        Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath $sectionPath -NoWarn
    }


    function Get-CIisVersion
    {
        <#
        .SYNOPSIS
        Gets the version of IIS.

        .DESCRIPTION
        Reads the version of IIS from the registry, and returns it as a `Major.Minor` formatted string.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Get-CIisVersion

        Returns `7.0` on Windows 2008, and `7.5` on Windows 7 and Windows 2008 R2.
        #>
        [CmdletBinding()]
        param(
            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $props = Get-ItemProperty hklm:\Software\Microsoft\InetStp
        return $props.MajorVersion.ToString() + "." + $props.MinorVersion.ToString()
    }


    function Get-CIisWebsite
    {
        <#
        .SYNOPSIS
        Returns all the websites installed on the local computer, or a specific website.

        .DESCRIPTION
        Returns a Microsoft.Web.Administration.Site object.

        Each object will have a `CommitChanges` script method added which will allow you to commit/persist any changes to the website's configuration.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        Microsoft.Web.Administration.Site.

        .LINK
        http://msdn.microsoft.com/en-us/library/microsoft.web.administration.site.aspx

        .EXAMPLE
        Get-CIisWebsite

        Returns all installed websites.

        .EXAMPLE
        Get-CIisWebsite -SiteName 'WebsiteName'

        Returns the details for the site named `WebsiteName`.
        #>
        [CmdletBinding()]
        [OutputType([Microsoft.Web.Administration.Site])]
        param(
            [string]
            [Alias('SiteName')]
            # The name of the site to get.
            $Name,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        if( $Name -and -not (Test-CIisWebsite -Name $Name -NoWarn) )
        {
            return $null
        }

        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $mgr.Sites |
            Where-Object {
                if( $Name )
                {
                    $_.Name -eq $Name
                }
                else
                {
                    $true
                }
            } | Add-IisServerManagerMember -ServerManager $mgr -PassThru -NoWarn
    }


    function Install-CIisApplication
    {
        <#
        .SYNOPSIS
        Creates a new application under a website.

        .DESCRIPTION
        Creates a new application at `VirtualPath` under website `SiteName` running the code found on the file system under `PhysicalPath`, i.e. if SiteName is is `example.com`, the application is accessible at `example.com/VirtualPath`.  If an application already exists at that path, it is removed first.  The application can run under a custom application pool using the optional `AppPoolName` parameter.  If no app pool is specified, the application runs under the same app pool as the website it runs under.

        Beginning with Carbon 2.0, returns a `Microsoft.Web.Administration.Application` object for the new application if one is created or modified.

        Beginning with Carbon 2.0, if no app pool name is given, existing application's are updated to use `DefaultAppPool`.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Install-CIisApplication -SiteName Peanuts -VirtualPath CharlieBrown -PhysicalPath C:\Path\To\CharlieBrown -AppPoolName CharlieBrownPool

        Creates an application at `Peanuts/CharlieBrown` which runs from `Path/To/CharlieBrown`.  The application runs under the `CharlieBrownPool`.

        .EXAMPLE
        Install-CIisApplication -SiteName Peanuts -VirtualPath Snoopy -PhysicalPath C:\Path\To\Snoopy

        Create an application at Peanuts/Snoopy, which runs from C:\Path\To\Snoopy.  It uses the same application as the Peanuts website.
        #>
        [CmdletBinding()]
        [OutputType([Microsoft.Web.Administration.Application])]
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
            # The app pool for the application. Default is `DefaultAppPool`.
            $AppPoolName,

            [Switch]
            # Returns IIS application object. This switch is new in Carbon 2.0.
            $PassThru,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $site = Get-CIisWebsite -SiteName $SiteName -NoWarn
        if( -not $site )
        {
            Write-Error ('[IIS] Website ''{0}'' not found.' -f $SiteName)
            return
        }

        $iisAppPath = Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn

        $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath -NoWarn
        if( -not (Test-Path $PhysicalPath -PathType Container) )
        {
            Write-Verbose ('IIS://{0}: creating physical path {1}' -f $iisAppPath,$PhysicalPath)
            $null = New-Item $PhysicalPath -ItemType Directory
        }

        $apps = $site.GetCollection()

        $appPath = "/{0}" -f $VirtualPath
        $app = Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath -NoWarn
        $modified = $false
        if( -not $app )
        {
            Write-Verbose ('IIS://{0}: creating application' -f $iisAppPath)
            $app = $apps.CreateElement('application') |
                        Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru -NoWarn
            $app['path'] = $appPath
            $apps.Add( $app ) | Out-Null
            $modified = $true
        }

        if( $app['path'] -ne $appPath )
        {
            $app['path'] = $appPath
            $modified = $true
        }

        if( $AppPoolName -and $app['applicationPool'] -ne $AppPoolName)
        {
            $app['applicationPool'] = $AppPoolName
            $modified = $true
        }

        $vdir = $null
        if( $app | Get-Member 'VirtualDirectories' )
        {
            $vdir = $app.VirtualDirectories |
                        Where-Object { $_.Path -eq '/' }
        }

        if( -not $vdir )
        {
            Write-Verbose ('IIS://{0}: creating virtual directory' -f $iisAppPath)
            $vdirs = $app.GetCollection()
            $vdir = $vdirs.CreateElement('virtualDirectory')
            $vdir['path'] = '/'
            $vdirs.Add( $vdir ) | Out-Null
            $modified = $true
        }

        if( $vdir['physicalPath'] -ne $PhysicalPath )
        {
            Write-Verbose ('IIS://{0}: setting physical path {1}' -f $iisAppPath,$PhysicalPath)
            $vdir['physicalPath'] = $PhysicalPath
            $modified = $true
        }

        if( $modified )
        {
            Write-Verbose ('IIS://{0}: committing changes' -f $iisAppPath)
            $app.CommitChanges()
        }

        if( $PassThru )
        {
            return Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath -NoWarn
        }

    }


    function Install-CIisAppPool
    {
        <#
        .SYNOPSIS
        Creates a new app pool.

        .DESCRIPTION
        By default, creates a 64-bit app pool running as the `ApplicationPoolIdentity` service account under .NET v4.0 with an integrated pipeline.

        You can control which version of .NET is used to run an app pool with the `ManagedRuntimeVersion` parameter: versions `v1.0`, `v1.1`, `v2.0`, and `v4.0` are supported. Use an empty string if you're running .NET Core or to set the .NET framework version to `No Managed Code`.

        To run an application pool using the classic pipeline mode, set the `ClassicPipelineMode` switch.

        To run an app pool using the 32-bit version of the .NET framework, set the `Enable32BitApps` switch.

        An app pool can run as several built-in service accounts, by passing one of them as the value of the `ServiceAccount` parameter: `NetworkService`, `LocalService`, or `LocalSystem`  The default is `ApplicationPoolIdentity`, which causes IIS to create and use a custom local account with the name of the app pool.  See [Application Pool Identities](http://learn.iis.net/page.aspx/624/application-pool-identities/) for more information.

        To run the app pool as a specific user, pass the credentials with the `Credential` parameter. (In some versions of Carbon, there is no `Credential` parameter, so use the `UserName` and `Password` parameters instead.) The user will be granted the `SeBatchLogonRight` privilege.

        If an existing app pool exists with name `Name`, it's settings are modified.  The app pool isn't deleted.  (You can't delete an app pool if there are any websites using it, that's why.)

        By default, this function will create an application pool running the latest version of .NET, with an integrated pipeline, as the NetworkService account.

        Beginning with Carbon 2.0, the `PassThru` switch will cause this function to return a `Microsoft.Web.Administration.ApplicationPool` object for the created/updated application pool.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        http://learn.iis.net/page.aspx/624/application-pool-identities/

        .LINK
        New-CCredential

        .EXAMPLE
        Install-CIisAppPool -Name Cyberdyne -ServiceAccount NetworkService

        Creates a new Cyberdyne application pool, running as NetworkService, using .NET 4.0 and an integrated pipeline.  If the Cyberdyne app pool already exists, it is modified to run as NetworkService, to use .NET 4.0 and to use an integrated pipeline.

        .EXAMPLE
        Install-CIisAppPool -Name Cyberdyne -ServiceAccount NetworkService -Enable32BitApps -ClassicPipelineMode

        Creates or sets the Cyberdyne app pool to run as NetworkService, in 32-bit mode (i.e. 32-bit applications are enabled), using the classic IIS request pipeline.

        .EXAMPLE
        Install-CIisAppPool -Name Cyberdyne -Credential $charlieBrownCredential

        Creates or sets the Cyberdyne app pool to run as the `PEANUTS\charliebrown` domain account, under .NET 4.0, with an integrated pipeline.
        #>
        [CmdletBinding(DefaultParameterSetName='AsServiceAccount')]
        [OutputType([Microsoft.Web.Administration.ApplicationPool])]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The app pool's name.
            $Name,

            [string]
            [ValidateSet('v1.0','v1.1','v2.0','v4.0','')]
            # The managed .NET runtime version to use.  Default is 'v4.0'.  Valid values are `v1.0`, `v1.1`, `v2.0`, or `v4.0`. Use an empty string if you're using .NET Core or to set the .NET framework version to `No Managed Code`.
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

            [string]
            [ValidateSet('NetworkService','LocalService','LocalSystem')]
            # Run the app pool under the given local service account.  Valid values are `NetworkService`, `LocalService`, and `LocalSystem`.  The default is `ApplicationPoolIdentity`, which causes IIS to create a custom local user account for the app pool's identity.  The default is `ApplicationPoolIdentity`.
            $ServiceAccount,

            [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true,DontShow=$true)]
            [string]
            # OBSOLETE. The `UserName` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
            $UserName,

            [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true,DontShow=$true)]
            # OBSOLETE. The `Password` parameter will be removed in a future major version of Carbon. Use the `Credential` parameter instead.
            $Password,

            [Parameter(ParameterSetName='AsSpecificUserWithCredential',Mandatory=$true)]
            [pscredential]
            # The credential to use to run the app pool.
            #
            # The `Credential` parameter is new in Carbon 2.0.
            $Credential,

            [Switch]
            # Return an object representing the app pool.
            $PassThru,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        if( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' )
        {
            if( $PSCmdlet.ParameterSetName -notlike '*WithCredential' )
            {
                Write-CWarningOnce ('`Install-CIisAppPool` function''s `UserName` and `Password` parameters are obsolete and will be removed in a future major version of Carbon. Please use the `Credential` parameter instead.')
                $Credential = New-CCredential -UserName $UserName -Password $Password
            }
        }

        if( $PSCmdlet.ParameterSetName -eq 'AsSpecificUser' -and -not (Test-CIdentity -Name $Credential.UserName) )
        {
            Write-Error ('Identity {0} not found. {0} IIS websites and applications assigned to this app pool won''t run.' -f $Credential.UserName,$Name)
        }

        if( -not (Test-CIisAppPool -Name $Name -NoWarn) )
        {
            Write-Verbose ('Creating IIS Application Pool {0}' -f $Name)
            $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
            $appPool = $mgr.ApplicationPools.Add($Name)
            $mgr.CommitChanges()
        }

        $appPool = Get-CIisAppPool -Name $Name -NoWarn

        $updated = $false

        if( $appPool.ManagedRuntimeVersion -ne $ManagedRuntimeVersion )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting ManagedRuntimeVersion = {0}' -f $Name,$ManagedRuntimeVersion)
            $appPool.ManagedRuntimeVersion = $ManagedRuntimeVersion
            $updated = $true
        }

        $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Integrated
        if( $ClassicPipelineMode )
        {
            $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Classic
        }
        if( $appPool.ManagedPipelineMode -ne $pipelineMode )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting ManagedPipelineMode = {0}' -f $Name,$pipelineMode)
            $appPool.ManagedPipelineMode = $pipelineMode
            $updated = $true
        }

        $idleTimeoutTimeSpan = New-TimeSpan -Minutes $IdleTimeout
        if( $appPool.ProcessModel.IdleTimeout -ne $idleTimeoutTimeSpan )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting idle timeout = {0}' -f $Name,$idleTimeoutTimeSpan)
            $appPool.ProcessModel.IdleTimeout = $idleTimeoutTimeSpan
            $updated = $true
        }

        if( $appPool.Enable32BitAppOnWin64 -ne ([bool]$Enable32BitApps) )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting Enable32BitAppOnWin64 = {0}' -f $Name,$Enable32BitApps)
            $appPool.Enable32BitAppOnWin64 = $Enable32BitApps
            $updated = $true
        }

        if( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' )
        {
            if( $appPool.ProcessModel.UserName -ne $Credential.UserName )
            {
                Write-Verbose ('IIS Application Pool {0}: Setting username = {0}' -f $Name,$Credential.UserName)
                $appPool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::SpecificUser
                $appPool.ProcessModel.UserName = $Credential.UserName
                $appPool.ProcessModel.Password = $Credential.GetNetworkCredential().Password

                # On Windows Server 2008 R2, custom app pool users need this privilege.
                Grant-CPrivilege -Identity $Credential.UserName -Privilege SeBatchLogonRight -Verbose:$VerbosePreference
                $updated = $true
            }
        }
        else
        {
            $identityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::ApplicationPoolIdentity
            if( $ServiceAccount )
            {
                $identityType = $ServiceAccount
            }

            if( $appPool.ProcessModel.IdentityType -ne $identityType )
            {
                Write-Verbose ('IIS Application Pool {0}: Setting IdentityType = {0}' -f $Name,$identityType)
                $appPool.ProcessModel.IdentityType = $identityType
                $updated = $true
            }
        }

        if( $updated )
        {
            $appPool.CommitChanges()
        }

        # TODO: Pull this out into its own Start-IisAppPool function.  I think.
        $appPool = Get-CIisAppPool -Name $Name -NoWarn
        if($appPool -and $appPool.state -eq [Microsoft.Web.Administration.ObjectState]::Stopped )
        {
            try
            {
                $appPool.Start()
            }
            catch
            {
                Write-Error ('Failed to start {0} app pool: {1}' -f $Name,$_.Exception.Message)
            }
        }

        if( $PassThru )
        {
            $appPool
        }
    }


    function Install-CIisVirtualDirectory
    {
        <#
        .SYNOPSIS
        Installs a virtual directory.

        .DESCRIPTION
        The `Install-CIisVirtualDirectory` function creates a virtual directory under website `SiteName` at `/VirtualPath`, serving files out of `PhysicalPath`.  If a virtual directory at `VirtualPath` already exists, it is updated in palce. (Before Carbon 2.0, the virtual directory was deleted before installation.)

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Install-CIisVirtualDirectory -SiteName 'Peanuts' -VirtualPath 'DogHouse' -PhysicalPath C:\Peanuts\Doghouse

        Creates a /DogHouse virtual directory, which serves files from the C:\Peanuts\Doghouse directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/DogHouse`.

        .EXAMPLE
        Install-CIisVirtualDirectory -SiteName 'Peanuts' -VirtualPath 'Brown/Snoopy/DogHouse' -PhysicalPath C:\Peanuts\DogHouse

        Creates a DogHouse virtual directory under the `Peanuts` website at `/Brown/Snoopy/DogHouse` serving files out of the `C:\Peanuts\DogHouse` directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/Brown/Snoopy/DogHouse`.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where the virtual directory should be created.
            $SiteName,

            [Parameter(Mandatory=$true)]
            [Alias('Name')]
            [string]
            # The name of the virtual directory.  This can contain multiple directory segments for virtual directories not at the root of the website, e.g. First/Second/VirtualDirectory.
            $VirtualPath,

            [Parameter(Mandatory=$true)]
            [Alias('Path')]
            [string]
            # The file system path to the virtual directory.
            $PhysicalPath,

            [Switch]
            # Deletes the virttual directory before installation, if it exists. Preserves default beheaviro in Carbon before 2.0.
            #
            # *Does not* delete custom configuration for the virtual directory, just the virtual directory. If you've customized the location of the virtual directory, those customizations will remain in place.
            #
            # The `Force` switch is new in Carbon 2.0.
            $Force,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $site = Get-CIisWebsite -Name $SiteName -NoWarn
        [Microsoft.Web.Administration.Application]$rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
        if( -not $rootApp )
        {
            Write-Error ('Default website application not found.')
            return
        }

        $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath -NoWarn

        $VirtualPath = $VirtualPath.Trim('/')
        $VirtualPath = '/{0}' -f $VirtualPath

        $vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq $VirtualPath }
        if( $Force -and $vdir )
        {
            Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'REMOVE' '' '' -NoWarn
            $rootApp.VirtualDirectories.Remove($vdir)
            $site.CommitChanges()
            $vdir = $null

            $site = Get-CIisWebsite -Name $SiteName -NoWarn
            $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
        }

        $modified = $false

        if( -not $vdir )
        {
            [Microsoft.Web.Administration.ConfigurationElementCollection]$vdirs = $rootApp.GetCollection()
            $vdir = $vdirs.CreateElement('virtualDirectory')
            Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'VirtualPath' '' $VirtualPath -NoWarn
            $vdir['path'] = $VirtualPath
            [void]$vdirs.Add( $vdir )
            $modified = $true
        }

        if( $vdir['physicalPath'] -ne $PhysicalPath )
        {
            Write-IisVerbose $SiteName -VirtualPath $VirtualPath 'PhysicalPath' $vdir['physicalPath'] $PhysicalPath -NoWarn
            $vdir['physicalPath'] = $PhysicalPath
            $modified = $true
        }

        if( $modified )
        {
            $site.CommitChanges()
        }
    }


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
            $Force,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

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

        $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath -NoWarn
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
            Uninstall-CIisWebsite -Name $Name -NoWarn
        }

        [Microsoft.Web.Administration.Site]$site = $null
        $modified = $false
        if( -not (Test-CIisWebsite -Name $Name -NoWarn) )
        {
            Write-Verbose -Message ('Creating website ''{0}'' ({1}).' -f $Name,$PhysicalPath)
            $firstBinding = $Binding | Select-Object -First 1 | ConvertTo-Binding
            $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
            $site = $mgr.Sites.Add( $Name, $firstBinding.Protocol, $firstBinding.BindingInformation, $PhysicalPath )
            $mgr.CommitChanges()
        }

        $site = Get-CIisWebsite -Name $Name -NoWarn

        $expectedBindings = New-Object 'Collections.Generic.Hashset[string]'
        $Binding | ConvertTo-Binding | ForEach-Object { [void]$expectedBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }

        $bindingsToRemove = $site.Bindings | Where-Object { -not $expectedBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }
        foreach( $bindingToRemove in $bindingsToRemove )
        {
            Write-IisVerbose $Name 'Binding' ('{0}/{1}' -f $bindingToRemove.Protocol,$bindingToRemove.BindingInformation) -NoWarn
            $site.Bindings.Remove( $bindingToRemove )
            $modified = $true
        }

        $existingBindings = New-Object 'Collections.Generic.Hashset[string]'
        $site.Bindings | ForEach-Object { [void]$existingBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }
        $bindingsToAdd = $Binding | ConvertTo-Binding | Where-Object { -not $existingBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }
        foreach( $bindingToAdd in $bindingsToAdd )
        {
            Write-IisVerbose $Name 'Binding' '' ('{0}/{1}' -f $bindingToAdd.Protocol,$bindingToAdd.BindingInformation) -NoWarn
            $site.Bindings.Add( $bindingToAdd.BindingInformation, $bindingToAdd.Protocol ) | Out-Null
            $modified = $true
        }

        [Microsoft.Web.Administration.Application]$rootApp = $null
        if( $site.Applications.Count -eq 0 )
        {
            $rootApp = $site.Applications.Add("/", $PhysicalPath)
            $modified = $true
        }
        else
        {
            $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
        }

        if( $site.PhysicalPath -ne $PhysicalPath )
        {
            Write-IisVerbose $Name 'PhysicalPath' $site.PhysicalPath $PhysicalPath -NoWarn
            [Microsoft.Web.Administration.VirtualDirectory]$vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq '/' }
            $vdir.PhysicalPath = $PhysicalPath
            $modified = $true
        }

        if( $AppPoolName )
        {
            if( $rootApp.ApplicationPoolName -ne $AppPoolName )
            {
                Write-IisVerbose $Name 'AppPool' $rootApp.ApplicationPoolName $AppPoolName -NoWarn
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
            Set-CIisWebsiteID -SiteName $Name -ID $SiteID -NoWarn
        }

        # Make sure anonymous authentication is enabled and uses the application pool identity
        $security = Get-CIisSecurityAuthentication -SiteName $Name -VirtualPath '/' -Anonymous -NoWarn
        Write-IisVerbose $Name 'Anonymous Authentication UserName' $security['username'] '' -NoWarn
        $security['username'] = ''
        $security.CommitChanges()

        # Now, wait until site is actually running
        $tries = 0
        $website = $null
        do
        {
            $website = Get-CIisWebsite -SiteName $Name -NoWarn
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


    function Join-CIisVirtualPath
    {
        <#
        .SYNOPSIS
        Combines a path and a child path for an IIS website, application, virtual directory into a single path.

        .DESCRIPTION
        Removes extra slashes.  Converts backward slashes to forward slashes.  Relative portions are not removed.  Sorry.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Join-CIisVirtualPath 'SiteName' 'Virtual/Path'

        Demonstrates how to join two IIS paths together.  REturns `SiteName/Virtual/Path`.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true,Position=0)]
            [string]
            # The parent path.
            $Path,

            [Parameter(Position=1)]
            [string]
            $ChildPath,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        if( $ChildPath )
        {
            $Path = Join-Path -Path $Path -ChildPath $ChildPath
        }
        $Path.Replace('\', '/').Trim('/')
    }


    function Lock-CIisConfigurationSection
    {
        <#
        .SYNOPSIS
        Locks an IIS configuration section so that it can't be modified/overridden by individual websites.

        .DESCRIPTION
        Locks configuration sections globally so they can't be modified by individual websites.  For a list of section paths, run

            C:\Windows\System32\inetsrv\appcmd.exe lock config /section:?

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Lock-CIisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication'

        Locks the `basicAuthentication` configuration so that sites can't override/modify those settings.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string[]]
            # The path to the section to lock.  For a list of sections, run
            #
            #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
            $SectionPath,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $SectionPath |
            ForEach-Object {
                $section = Get-CIisConfigurationSection -SectionPath $_ -NoWarn
                $section.OverrideMode = 'Deny'
                if( $pscmdlet.ShouldProcess( $_, 'locking IIS configuration section' ) )
                {
                    $section.CommitChanges()
                }
            }
    }


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
            $FileExtension,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $getIisConfigSectionParams = @{ }
        if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
        {
            $getIisConfigSectionParams['SiteName'] = $SiteName
            $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
        }

        $staticContent = Get-CIisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams -NoWarn
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


    function Set-CIisHttpHeader
    {
        <#
        .SYNOPSIS
        Sets an HTTP header for a website or a directory under a website.

        .DESCRIPTION
        If the HTTP header doesn't exist, it is created.  If a header exists, its value is replaced.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        Get-CIisHttpHeader

        .EXAMPLE
        Set-CIisHttpHeader -SiteName 'SopwithCamel' -Name 'X-Flown-By' -Value 'Snoopy'

        Sets or creates the `SopwithCamel` website's `X-Flown-By` HTTP header to the value `Snoopy`.

        .EXAMPLE
        Set-CIisHttpHeader -SiteName 'SopwithCamel' -VirtualPath 'Engine' -Name 'X-Powered-By' -Value 'Root Beer'

        Sets or creates the `SopwithCamel` website's `Engine` sub-directory's `X-Powered-By` HTTP header to the value `Root Beer`.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the website where the HTTP header should be set/created.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path under `SiteName` where the HTTP header should be set/created.
            $VirtualPath = '',

            [Parameter(Mandatory=$true)]
            [string]
            # The name of the HTTP header.
            $Name,

            [Parameter(Mandatory=$true)]
            [string]
            # The value of the HTTP header.
            $Value,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $httpProtocol = Get-CIisConfigurationSection -SiteName $SiteName `
                                                    -VirtualPath $VirtualPath `
                                                    -SectionPath 'system.webServer/httpProtocol' `
                                                    -NoWarn
        $headers = $httpProtocol.GetCollection('customHeaders')
        $header = $headers | Where-Object { $_['name'] -eq $Name }

        if( $header )
        {
            $action = 'setting'
            $header['name'] = $Name
            $header['value'] = $Value
        }
        else
        {
            $action = 'adding'
            $addElement = $headers.CreateElement( 'add' )
            $addElement['name'] = $Name
            $addElement['value'] = $Value
            [void] $headers.Add( $addElement )
        }

        $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn
        if( $pscmdlet.ShouldProcess( $fullPath, ('{0} HTTP header {1}' -f $action,$Name) ) )
        {
            $httpProtocol.CommitChanges()
        }
    }


    function Set-CIisHttpRedirect
    {
        <#
        .SYNOPSIS
        Turns on HTTP redirect for all or part of a website.

        .DESCRIPTION
        Configures all or part of a website to redirect all requests to another website/URL.  By default, it operates on a specific website.  To configure a directory under a website, set `VirtualPath` to the virtual path of that directory.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        http://www.iis.net/configreference/system.webserver/httpredirect#005

        .LINK
        http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx

        .EXAMPLE
        Set-CIisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com'

        Redirects all requests to the `Peanuts` website to `http://new.peanuts.com`.

        .EXAMPLE
        Set-CIisHttpRedirect -SiteName Peanuts -VirtualPath Snoopy/DogHouse -Destination 'http://new.peanuts.com'

        Redirects all requests to the `/Snoopy/DogHouse` path on the `Peanuts` website to `http://new.peanuts.com`.

        .EXAMPLE
        Set-CIisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com' -StatusCode 'Temporary'

        Redirects all requests to the `Peanuts` website to `http://new.peanuts.com` with a temporary HTTP status code.  You can also specify `Found` (HTTP 302), or `Permanent` (HTTP 301).
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where the redirection should be setup.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path where redirection should be setup.
            $VirtualPath = '',

            [Parameter(Mandatory=$true)]
            [string]
            # The destination to redirect to.
            $Destination,

            [Carbon.Iis.HttpResponseStatus]
            # The HTTP status code to use.  Default is `Found`.  Should be one of `Found` (HTTP 302), `Permanent` (HTTP 301), or `Temporary` (HTTP 307).
            [Alias('StatusCode')]
            $HttpResponseStatus = [Carbon.Iis.HttpResponseStatus]::Found,

            [Switch]
            # Redirect all requests to exact destination (instead of relative to destination).  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
            $ExactDestination,

            [Switch]
            # Only redirect requests to content in site and/or path, but nothing below it.  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
            $ChildOnly,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $settings = Get-CIisHttpRedirect -SiteName $SiteName -Path $VirtualPath -NoWarn
        $settings.Enabled = $true
        $settings.Destination = $destination
        $settings.HttpResponseStatus = $HttpResponseStatus
        $settings.ExactDestination = $ExactDestination
        $settings.ChildOnly = $ChildOnly

        if( $pscmdlet.ShouldProcess( (Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn), "set HTTP redirect settings" ) )
        {
            $settings.CommitChanges()
        }
    }


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
            $MimeType,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $getIisConfigSectionParams = @{ }
        if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
        {
            $getIisConfigSectionParams['SiteName'] = $SiteName
            $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
        }

        $staticContent = Get-CIisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams -NoWarn
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


    function Set-CIisWebsiteID
    {
        <#
        .SYNOPSIS
        Sets a website's ID to an explicit number.

        .DESCRIPTION
        IIS handles assigning websites individual IDs.  This method will assign a website explicit ID you manage (e.g. to support session sharing in a web server farm).

        If another site already exists with that ID, you'll get an error.

        When you change a website's ID, IIS will stop the site, but not start the site after saving the ID change. This function waits until the site's ID is changed, and then will start the website.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Set-CIisWebsiteID -SiteName Holodeck -ID 483

        Sets the `Holodeck` website's ID to `483`.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The website name.
            $SiteName,

            [Parameter(Mandatory=$true)]
            [int]
            # The website's new ID.
            $ID,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        if( -not (Test-CIisWebsite -Name $SiteName -NoWarn) )
        {
            Write-Error ('Website {0} not found.' -f $SiteName)
            return
        }

        $websiteWithID = Get-CIisWebsite -NoWarn | Where-Object { $_.ID -eq $ID -and $_.Name -ne $SiteName }
        if( $websiteWithID )
        {
            Write-Error -Message ('ID {0} already in use for website {1}.' -f $ID,$SiteName) -Category ResourceExists
            return
        }

        $website = Get-CIisWebsite -SiteName $SiteName -NoWarn
        $startWhenDone = $false
        if( $website.ID -ne $ID )
        {
            if( $PSCmdlet.ShouldProcess( ('website {0}' -f $SiteName), ('set site ID to {0}' -f $ID) ) )
            {
                $startWhenDone = ($website.State -eq 'Started')
                $website.ID = $ID
                $website.CommitChanges()
            }
        }

        if( $PSBoundParameters.ContainsKey('WhatIf') )
        {
            return
        }

        # Make sure the website's ID gets updated
        $website = $null
        $maxTries = 100
        $numTries = 0
        do
        {
            Start-Sleep -Milliseconds 100
            $website = Get-CIisWebsite -SiteName $SiteName -NoWarn
            if( $website -and $website.ID -eq $ID )
            {
                break
            }
            $numTries++
        }
        while( $numTries -lt $maxTries )

        if( -not $website -or $website.ID -ne $ID )
        {
            Write-Error ('IIS:/{0}: site ID hasn''t changed to {1} after waiting 10 seconds. Please check IIS configuration.' -f $SiteName,$ID)
        }

        if( -not $startWhenDone )
        {
            return
        }

        # Now, start the website.
        $numTries = 0
        do
        {
            # Sometimes, the website is invalid and Start() throws an exception.
            try
            {
                if( $website )
                {
                    $null = $website.Start()
                }
            }
            catch
            {
                $website = $null
            }

            Start-Sleep -Milliseconds 100
            $website = Get-CIisWebsite -SiteName $SiteName -NoWarn
            if( $website -and $website.State -eq 'Started' )
            {
                break
            }
            $numTries++
        }
        while( $numTries -lt $maxTries )

        if( -not $website -or $website.State -ne 'Started' )
        {
            Write-Error ('IIS:/{0}: failed to start website after setting ID to {1}' -f $SiteName,$ID)
        }
    }


    function Set-CIisWebsiteSslCertificate
    {
        <#
        .SYNOPSIS
        Sets a website's SSL certificate.

        .DESCRIPTION
        SSL won't work on a website if an SSL certificate hasn't been bound to all the IP addresses it's listening on.  This function binds a certificate to all a website's IP addresses.  Make sure you call this method *after* you create a website's bindings.  Any previous SSL bindings on those IP addresses are deleted.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Set-CIisWebsiteSslCertificate -SiteName Peanuts -Thumbprint 'a909502dd82ae41433e6f83886b00d4277a32a7b' -ApplicationID $PeanutsAppID

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
            $ApplicationID,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $site = Get-CIisWebsite -SiteName $SiteName -NoWarn
        if( -not $site )
        {
            Write-Error "Unable to find website '$SiteName'."
            return
        }

        $site.Bindings | Where-Object { $_.Protocol -eq 'https' } | ForEach-Object {
            $installArgs = @{ }
            if( $_.Endpoint.Address -ne '0.0.0.0' )
            {
                $installArgs.IPAddress = $_.Endpoint.Address.ToString()
            }
            if( $_.Endpoint.Port -ne '*' )
            {
                $installArgs.Port = $_.Endpoint.Port
            }
            Set-CSslCertificateBinding @installArgs -ApplicationID $ApplicationID -Thumbprint $Thumbprint -NoWarn
        }
    }


    function Set-CIisWindowsAuthentication
    {
        <#
        .SYNOPSIS
        Configures the settings for Windows authentication.

        .DESCRIPTION
        By default, configures Windows authentication on a website.  You can configure Windows authentication at a specific path under a website by passing the virtual path (*not* the physical path) to that directory.

        The changes only take effect if Windows authentication is enabled (see `Enable-CIisSecurityAuthentication`).

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .LINK
        http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx

        .LINK
        Disable-CIisSecurityAuthentication

        .LINK
        Enable-CIisSecurityAuthentication

        .EXAMPLE
        Set-CIisWindowsAuthentication -SiteName Peanuts

        Configures Windows authentication on the `Peanuts` site to use kernel mode.

        .EXAMPLE
        Set-CIisWindowsAuthentication -SiteName Peanuts -VirtualPath Snoopy/DogHouse -DisableKernelMode

        Configures Windows authentication on the `Doghouse` directory of the `Peanuts` site to not use kernel mode.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where Windows authentication should be set.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path where Windows authentication should be set.
            $VirtualPath = '',

            [Switch]
            # Turn on kernel mode.  Default is false.  [More information about Kerndel Mode authentication.](http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx)
            $DisableKernelMode,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $useKernelMode = 'True'
        if( $DisableKernelMode )
        {
            $useKernelMode = 'False'
        }

        $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath -Windows -NoWarn
        $authSettings.SetAttributeValue( 'useKernelMode', $useKernelMode )

        $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn
        if( $pscmdlet.ShouldProcess( $fullPath, "set Windows authentication" ) )
        {
            $authSettings.CommitChanges()
        }
    }


    function Test-CIisAppPool
    {
        <#
        .SYNOPSIS
        Checks if an app pool exists.

        .DESCRIPTION
        Returns `True` if an app pool with `Name` exists.  `False` if it doesn't exist.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Test-CIisAppPool -Name Peanuts

        Returns `True` if the Peanuts app pool exists, `False` if it doesn't.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the app pool.
            $Name,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $appPool = Get-CIisAppPool -Name $Name -NoWarn
        if( $appPool )
        {
            return $true
        }

        return $false
    }

    Set-Alias -Name 'Test-IisAppPoolExists' -Value 'Test-CIisAppPool'


    function Test-CIisConfigurationSection
    {
        <#
        .SYNOPSIS
        Tests a configuration section.

        .DESCRIPTION
        You can test if a configuration section exists or wheter it is locked.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        System.Boolean.

        .EXAMPLE
        Test-CIisConfigurationSection -SectionPath 'system.webServer/I/Do/Not/Exist'

        Tests if a configuration section exists.  Returns `False`, because the given configuration section doesn't exist.

        .EXAMPLE
        Test-CIisConfigurationSection -SectionPath 'system.webServer/cgi' -Locked

        Returns `True` if the global CGI section is locked.  Otherwise `False`.

        .EXAMPLE
        Test-CIisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication' -SiteName `Peanuts` -VirtualPath 'SopwithCamel' -Locked

        Returns `True` if the `Peanuts` website's `SopwithCamel` sub-directory's `basicAuthentication` security authentication section is locked.  Otherwise, returns `False`.
        #>
        [CmdletBinding(DefaultParameterSetName='CheckExists')]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The path to the section to test.
            $SectionPath,

            [Parameter()]
            [string]
            # The name of the site whose configuration section to test.  Optional.  The default is the global configuration.
            $SiteName,

            [Parameter()]
            [Alias('Path')]
            [string]
            # The optional path under `SiteName` whose configuration section to test.
            $VirtualPath,

            [Parameter(Mandatory=$true,ParameterSetName='CheckLocked')]
            [Switch]
            # Test if the configuration section is locked.
            $Locked,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $getArgs = @{
                        SectionPath = $SectionPath;
                    }
        if( $SiteName )
        {
            $getArgs.SiteName = $SiteName
        }

        if( $VirtualPath )
        {
            $getArgs.VirtualPath = $VirtualPath
        }

        $section = Get-CIisConfigurationSection @getArgs -ErrorAction SilentlyContinue -NoWarn

        if( $pscmdlet.ParameterSetName -eq 'CheckExists' )
        {
            if( $section )
            {
                return $true
            }
            else
            {
                return $false
            }
        }

        if( -not $section )
        {
            Write-Error ('IIS:{0}: section {1} not found.' -f (Join-CIisVirtualPath $SiteName $VirtualPath -NoWarn),$SectionPath)
            return
        }

        if( $pscmdlet.ParameterSetName -eq 'CheckLocked' )
        {
            return $section.OverrideMode -eq 'Deny'
        }
    }


    function Test-CIisSecurityAuthentication
    {
        <#
        .SYNOPSIS
        Tests if IIS authentication types are enabled or disabled on a site and/or virtual directory under that site.

        .DESCRIPTION
        You can check if anonymous, basic, or Windows authentication are enabled.  There are switches for each authentication type.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .OUTPUTS
        System.Boolean.

        .EXAMPLE
        Test-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

        Returns `true` if anonymous authentication is enabled for the `Peanuts` site.  `False` if it isn't.

        .EXAMPLE
        Test-CIisSecurityAuthentication -SiteName Peanuts -VirtualPath Doghouse -Basic

        Returns `true` if basic authentication is enabled for`Doghouse` directory under  the `Peanuts` site.  `False` if it isn't.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The site where anonymous authentication should be set.
            $SiteName,

            [Alias('Path')]
            [string]
            # The optional path where anonymous authentication should be set.
            $VirtualPath = '',

            [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
            [Switch]
            # Tests if anonymous authentication is enabled.
            $Anonymous,

            [Parameter(Mandatory=$true,ParameterSetName='Basic')]
            [Switch]
            # Tests if basic authentication is enabled.
            $Basic,

            [Parameter(Mandatory=$true,ParameterSetName='Digest')]
            [Switch]
            # Tests if digest authentication is enabled.
            $Digest,

            [Parameter(Mandatory=$true,ParameterSetName='Windows')]
            [Switch]
            # Tests if Windows authentication is enabled.
            $Windows,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $getConfigArgs = @{ $pscmdlet.ParameterSetName = $true }
        $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getConfigArgs -NoWarn
        return ($authSettings.GetAttributeValue('enabled') -eq 'true')
    }



    function Test-CIisWebsite
    {
        <#
        .SYNOPSIS
        Tests if a website exists.

        .DESCRIPTION
        Returns `True` if a website with name `Name` exists.  `False` if it doesn't.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Test-CIisWebsite -Name 'Peanuts'

        Returns `True` if the `Peanuts` website exists.  `False` if it doesn't.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the website whose existence to check.
            $Name,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
        try
        {
            $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
            if( $site )
            {
                return $true
            }
            return $false
        }
        finally
        {
            $manager.Dispose()
        }
    }

    Set-Alias -Name 'Test-IisWebsiteExists' -Value 'Test-CIisWebsite'


    function Uninstall-CIisAppPool
    {
        <#
        .SYNOPSIS
        Removes an IIS application pool.

        .DESCRIPTION
        If the app pool doesn't exist, nothing happens.

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Uninstall-CIisAppPool -Name Batcave

        Removes/uninstalls the `Batcave` app pool.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the app pool to remove.
            $Name,

            # Don't show the warning message that this command was moved to a new module.
            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $appPool = Get-CIisAppPool -Name $Name -NoWarn
        if( $appPool )
        {
            if( $pscmdlet.ShouldProcess( ('IIS app pool {0}' -f $Name), 'remove' ) )
            {
                $appPool.Delete()
                $appPool.CommitChanges()
            }
        }
    }


    function Uninstall-CIisWebsite
    {
        <#
        .SYNOPSIS
        Removes a website

        .DESCRIPTION
        Pretty simple: removes the website named `Name`.  If no website with that name exists, nothing happens.

        Beginning with Carbon 2.0.1, this function is not available if IIS isn't installed.

        .LINK
        Get-CIisWebsite

        .LINK
        Install-CIisWebsite

        .EXAMPLE
        Uninstall-CIisWebsite -Name 'MyWebsite'

        Removes MyWebsite.

        .EXAMPLE
        Uninstall-CIisWebsite 1

        Removes the website whose ID is 1.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Position=0,Mandatory=$true)]
            [string]
            # The name or ID of the website to remove.
            $Name,

            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        if( Test-CIisWebsite -Name $Name -NoWarn )
        {
            $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
            try
            {
                $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
                $manager.Sites.Remove( $site )
                $manager.CommitChanges()
            }
            finally
            {
                $manager.Dispose()
            }
        }
    }

    Set-Alias -Name 'Remove-IisWebsite' -Value 'Uninstall-CIisWebsite'


    function Unlock-CIisConfigurationSection
    {
        <#
        .SYNOPSIS
        Unlocks a section in the IIS server configuration.

        .DESCRIPTION
        Some sections/areas are locked by IIS, so that websites can't enable those settings, or have their own custom configurations.  This function will unlocks those locked sections.  You have to know the path to the section.  You can see a list of locked sections by running:

            C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?

        Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

        .EXAMPLE
        Unlock-IisConfigSection -Name 'system.webServer/cgi'

        Unlocks the CGI section so that websites can configure their own CGI settings.
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [string[]]
            # The path to the section to unlock.  For a list of sections, run
            #
            #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
            $SectionPath,

            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        $SectionPath |
            ForEach-Object {
                $section = Get-CIisConfigurationSection -SectionPath $_ -NoWarn
                $section.OverrideMode = 'Allow'
                if( $pscmdlet.ShouldProcess( $_, 'unlocking IIS configuration section' ) )
                {
                    $section.CommitChanges()
                }
            }
    }


    function Write-IisVerbose
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true,Position=0)]
            [string]
            # The name of the site.
            $SiteName,

            [string]
            $VirtualPath = '',

            [Parameter(Position=1)]
            [string]
            # The name of the setting.
            $Name,

            [Parameter(Position=2)]
            [string]
            $OldValue = '',

            [Parameter(Position=3)]
            [string]
            $NewValue = '',

            [switch] $NoWarn
        )

        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $NoWarn)
        {
            Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.IIS'
        }

        if( $VirtualPath )
        {
            $SiteName = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath -NoWarn
        }

        Write-Verbose -Message ('[IIS Website] [{0}] {1,-34} {2} -> {3}' -f $SiteName,$Name,$OldValue,$NewValue)
    }


    if( -not (Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Site' -MemberName 'PhysicalPath') )
    {
        Write-Timing ('Updating Microsoft.Web.Administration.Site type data.')
        Update-TypeData -TypeName 'Microsoft.Web.Administration.Site' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value {
                $this.Applications |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty VirtualDirectories |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty PhysicalPath
            }
    }

    if( -not (Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Application' -MemberName 'PhysicalPath') )
    {
        Write-Timing ('Updating Microsoft.Web.Administration.Application type data.')
        Update-TypeData -TypeName 'Microsoft.Web.Administration.Application' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value {
                $this.VirtualDirectories |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty PhysicalPath
            }
    }
}
