
function Publish-WhiskeyNuGetPackage
{
    [Whiskey.Task("PublishNuGetLibrary")]
    [Whiskey.Task("PublishNuGetPackage")]
    [Whiskey.Task("NuGetPush")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,
    
        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( @( 'PublishNuGetLibrary', 'PublishNuGetPackage') -contains $TaskContext.TaskName )
    {
        Write-Warning -Message ('We have renamed the ''{0}'' task to ''NuGetPush''. Please rename the task in ''{1}''. In a future version of Whiskey, the `PublishNuGetLibrary` name will no longer work.' -f $TaskContext.TaskName,$TaskContext.ConfigurationPath)
    }

    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        $TaskParameter['Path'] = '.output\*.nupkg'
    }

    $publishSymbols = $TaskParameter['Symbols'] | ConvertFrom-WhiskeyYamlScalar

    $paths = $TaskParameter['Path'] | 
                Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path' | 
                Where-Object { 
                    $wildcard = '*.symbols.nupkg' 
                    if( $publishSymbols )
                    {
                        $_ -like $wildcard
                    }
                    else
                    {
                        $_ -notlike $wildcard
                    }
                }
       
    $source = $TaskParameter['Uri']
    if( -not $source )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Uri'' is mandatory. It should be the URI where NuGet packages should be published, e.g. 
            
    Build:
    - PublishNuGetPackage:
        Uri: https://nuget.org
    ')
    }

    $apiKeyID = $TaskParameter['ApiKeyID']
    if( -not $apiKeyID )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''ApiKeyID'' is mandatory. It should be the ID/name of the API key to use when publishing NuGet packages to {0}, e.g.:
            
    Build:
    - PublishNuGetPackage:
        Uri: {0}
        ApiKeyID: API_KEY_ID
             
Use the `Add-WhiskeyApiKey` function to add the API key to the build.

            ' -f $source)
    }
    $apiKey = Get-WhiskeyApiKey -Context $TaskContext -ID $apiKeyID -PropertyName 'ApiKeyID'

    $nuGetPath = Install-WhiskeyNuGet -DownloadRoot $TaskContext.BuildRoot -Version $TaskParameter['Version']
    if( -not $nugetPath )
    {
        return
    }

    foreach ($path in $paths)
    {
        $packageFilename = [IO.Path]::GetFileNameWithoutExtension(($path | Split-Path -Leaf))
        $packageName = $packageFilename -replace '\.\d+\.\d+\.\d+(-.*)?(\.symbols)?',''

        $packageFilename -match '(\d+\.\d+\.\d+(?:-[0-9a-z]+)?)'
        $packageVersion = $Matches[1]

        $packageUri = '{0}/package/{1}/{2}' -f $source,$packageName,$packageVersion
            
        # Make sure this version doesn't exist.
        $packageExists = $false
        $numErrorsAtStart = $Global:Error.Count
        try
        {
            Invoke-WebRequest -Uri $packageUri -UseBasicParsing | Out-Null
            $packageExists = $true
        }
        catch [Net.WebException]
        {
            $response = [Net.HttpWebResponse]([Net.WebException]$_.Exception).Response
            if( $response.StatusCode -ne [Net.HttpStatusCode]::NotFound )
            {
                $content = $response.GetResponseStream()
                $content.Position = 0
                $reader = New-Object 'IO.StreamReader' $content
                $error = $reader.ReadToEnd() -replace '<[^>]+?>',''
                $reader.Close()
                $response.Close()
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failure checking if {0} {1} package already exists at {2}. The web request returned a {3} ({4}) status code:{5} {5}{6}' -f $packageName,$packageVersion,$packageUri,$response.StatusCode,[int]$response.StatusCode,[Environment]::NewLine,$error)
            }

            for( $idx = 0; $idx -lt ($Global:Error.Count - $numErrorsAtStart); ++$idx )
            {
                $Global:Error.RemoveAt(0)
            }
        }

        if( $packageExists )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('{0} {1} already exists. Please increment your library''s version number in ''{2}''.' -f $packageName,$packageVersion,$TaskContext.ConfigurationPath)
        }

        # Publish package and symbols to NuGet
        Invoke-WhiskeyNuGetPush -Path $path -Uri $source -ApiKey $apiKey -NuGetPath $nuGetPath
        
        if( -not ($TaskParameter['SkipUploadedCheck'] | ConvertFrom-WhiskeyYamlScalar) )
        { 
            try
            {
                Invoke-WebRequest -Uri $packageUri -UseBasicParsing | Out-Null
            }
            catch [Net.WebException]
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to publish NuGet package {0} {1} to {2}. When we checked if that package existed, we got a {3} HTTP status code. Please see build output for more information.' -f $packageName,$packageVersion,$packageUri,$_.Exception.Response.StatusCode)
            }
        }
    }
} 
