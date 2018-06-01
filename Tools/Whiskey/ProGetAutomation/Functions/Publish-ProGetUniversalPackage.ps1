
function Publish-ProGetUniversalPackage
{
    <#
    .SYNOPSIS
    Publishes a package to the specified ProGet instance

    .DESCRIPTION
    The `Publish-ProGetUniversalPackage` function will upload a package to the `FeedName` universal feed. It uses .NET 4.5's `HttpClient` to upload the file.

    .EXAMPLE
    Publish-ProGetUniversalPackage -Session $ProGetSession -FeedName 'Apps' -PackagePath 'C:\ProGetPackages\TestPackage.upack'

    Demonstrates how to call `Publish-ProGetUniversalPackage`. In this case, the package named 'TestPackage.upack' will be published to the 'Apps' feed located at $Session.Uri using the $Session.Credential authentication credentials
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [pscustomobject]
        # The session includes ProGet's URI and the credentials to use when utilizing ProGet's API.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The feed name indicates the appropriate feed where the package should be published.
        $FeedName,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the package that will be published to ProGet.
        $PackagePath,

        [int]
        # The timeout (in seconds) for the upload. The default is 100 seconds.
        $Timeout = 100,

        [Switch]
        # Replace the package if it already exists in ProGet.
        $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $shouldProcessCaption = ('creating {0} package' -f $PackagePath)
    $proGetPackageUri = New-Object 'Uri' $Session.Uri,('/upack/{0}' -f $FeedName)
    $proGetCredential = $Session.Credential

    $PackagePath = Resolve-Path -Path $PackagePath | Select-Object -ExpandProperty 'ProviderPath'
    if( -not $PackagePath )
    {
        Write-Error -Message ('Package ''{0}'' does not exist.' -f $PSBoundParameters['PackagePath'])
        return
    }

    $userMsg = ''
    if( $proGetCredential )
    {
        $userMsg = ' as ''{0}''' -f $proGetCredential.UserName
    }

    if( -not $Force )
    {
        $version = $null
        $name = $null
        $group = $null
        $zip = $null
        $foundUpackJson = $true
        $invalidUpackJson = $false
        try
        {
            $zip = [IO.Compression.ZipFile]::OpenRead($PackagePath)
            $foundUpackJson = $false
            foreach( $entry in $zip.Entries )
            {
                if($entry.FullName -ne "upack.json" )
                {
                    continue
                }

                $foundUpackJson = $true
                $stream = $entry.Open()
                $stringReader = New-Object 'IO.StreamReader' $stream
                try
                {
                    $packageJson = $stringReader.ReadToEnd() | ConvertFrom-Json
                    $version = $packageJson.version
                    $name = $packageJson.name
                    if( $packageJson | Get-Member -Name 'group' )
                    {
                        $group = $packageJson.group
                    }
                }
                catch
                {
                    $invalidUpackJson = $true
                }
                finally
                {
                    $stringReader.Close()
                    $stream.Close()
                }
                break
            }
        }
        catch
        {
            Write-Error -Message ('The upack file ''{0}'' isn''t a valid ZIP file.' -f $PackagePath)
            return
        }
        finally
        {
            if( $zip )
            {
                $zip.Dispose()
            }
        }

        if( -not $foundUpackJson )
        {
            Write-Error -Message ('The upack file ''{0}'' is invalid. It must contain a upack.json metadata file. See http://inedo.com/support/documentation/various/universal-packages/universal-feed-api for more information.' -f $PackagePath) 
            return
        }

        if( $invalidUpackJson )
        {
            Write-Error -Message (@"
The upack.json metadata file in '$($PackagePath)' is invalid. It must be a valid JSON file with ''version'' and ''name'' properties that have values, e.g. 
    
    {
        ""name"": ""HDARS"",
        ""version": ""1.3.9""
    }
    
See http://inedo.com/support/documentation/various/universal-packages/universal-feed-api for more information.
    
"@)        
            return
        }

        if( -not $name -or -not $version )
        {
            [string[]]$propertyNames = @( 'name', 'version') | Where-Object { -not (Get-Variable -Name $_ -ValueOnly) }
            $description = 'property doesn''t have a value'
            if( $propertyNames.Count -gt 1 )
            {
                $description = 'properties don''t have values'
            }
            $emptyPropertyNames =  $propertyNames -join ''' and '''
                                    
            Write-Error -Message ('The upack.json metadata file in ''{0}'' is invalid. The ''{1}'' {2}. See http://inedo.com/support/documentation/various/universal-packages/universal-feed-api for more information.' -f $PackagePath,$emptyPropertyNames,$description)
            return
        }

        $groupParam = ''
        if( $group )
        {
            $groupParam = '&group={0}' -f [Web.HttpUtility]::UrlEncode($group)
        }
        $path = '/upack/{0}/packages?name={1}{2}' -f $FeedName,[Web.HttpUtility]::UrlEncode($name),$groupParam
        $packageInfo = Invoke-ProGetRestMethod -Session $Session -Path $path -Method Get -ErrorAction Ignore
        if( $packageInfo -and $packageInfo.versions -contains $version )
        {
            Write-Error -Message ('Package {0} {1} already exists in universal ProGet feed ''{2}''.' -f $name,$version,$proGetPackageUri)
            return
        }
    }

    $operationDescription = 'Uploading ''{0}'' package to ProGet at ''{1}''{2}.' -f ($PackagePath | Split-Path -Leaf), $proGetPackageUri, $userMsg
    if( $PSCmdlet.ShouldProcess($operationDescription, $operationDescription, $shouldProcessCaption) )
    {
        Write-Verbose -Message $operationDescription

        $networkCred = $null
        if( $proGetCredential )
        {
            $networkCred = $proGetCredential.GetNetworkCredential()
        }

        $maxDuration = New-Object 'TimeSpan' 0,0,$Timeout

        [Net.Http.HttpClientHandler]$httpClientHandler = $null
        [Net.Http.HttpClient]$httpClient = $null
        [IO.FileStream]$packageStream = $null
        [Net.Http.StreamContent]$streamContent = $null
        [Threading.Tasks.Task[Net.Http.HttpResponseMessage]]$httpResponseMessage = $null
        [Net.Http.HttpResponseMessage]$response = $null
        try
        {
            $httpClientHandler = New-Object 'Net.Http.HttpClientHandler'
            if( $proGetCredential )
            {
                $httpClientHandler.UseDefaultCredentials = $false
                $httpClientHandler.Credentials = $networkCred
            }

            $httpClientHandler.PreAuthenticate = $true;

            $httpClient = New-Object 'Net.Http.HttpClient' ([Net.Http.HttpMessageHandler]$httpClientHandler)
            $httpClient.Timeout = $maxDuration

            $packageStream = New-Object 'IO.FileStream' ($PackagePath, 'Open', 'Read')
            $streamContent = New-Object 'Net.Http.StreamContent' ([IO.Stream]$packageStream)
            $streamContent.Headers.ContentType = New-Object 'Net.Http.Headers.MediaTypeHeaderValue' ('application/octet-stream')
            $httpResponseMessage = $httpClient.PutAsync($proGetPackageUri, [Net.Http.HttpContent]$streamContent)
            if( -not $httpResponseMessage.Wait($maxDuration) )
            {
                Write-Error -Message ('Uploading file ''{0}'' to ''{1}'' timed out after {2} second(s). To increase this timeout, set the Timeout parameter to the number of seconds to wait for the upload to complete.' -f $PackagePath,$proGetPackageUri,$Timeout)
                return
            }
                        
            $response = $httpResponseMessage.Result
            if( -not $response.IsSuccessStatusCode )
            {
                Write-Error -Message ('Failed to upload ''{0}'' to ''{1}''. We received the following ''{2} {3}'' response:{4} {4}{5}{4} {4}' -f $PackagePath,$proGetPackageUri,[int]$response.StatusCode,$response.StatusCode,[Environment]::NewLine,$response.Content.ReadAsStringAsync().Result)
                return
            }
        }
        catch
        {
            $ex = $_.Exception
            while( $ex.InnerException )
            {
                $ex = $ex.InnerException
            }

            if( $ex -is [Threading.Tasks.TaskCanceledException] )
            {
                Write-Error -Message ('Uploading file ''{0}'' to ''{1}'' was cancelled. This is usually because the upload took longer than the timeout, which was {2} second(s). Use the Timeout parameter to increase the upload timeout.' -f $PackagePath,$proGetPackageUri,$Timeout) 
                return
            }

            Write-Error -Message ('An unknown error occurred uploading ''{0}'' to ''{1}'': {2}' -f $PackagePath,$proGetPackageUri,$_)
            return
        }
        finally
        {
            $disposables = @( 'httpClientHandler', 'httpClient', 'packageStream', 'streamContent', 'httpResponseMessage', 'response' ) 
            $disposables |
                ForEach-Object { Get-Variable -Name $_ -ValueOnly -ErrorAction Ignore } |
                Where-Object { $_ -ne $null } |
                ForEach-Object { $_.Dispose() }
            $disposables | ForEach-Object { Remove-Variable -Name $_ -Force -ErrorAction Ignore }
        }
    }
}
