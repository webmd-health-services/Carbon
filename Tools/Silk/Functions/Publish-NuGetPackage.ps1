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

function Publish-NuGetPackage
{
    <#
    .SYNOPSIS
    Creates and publishes a NuGet package to nuget.org.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module manifest of the module you want to publish.
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the nuspec file for the NuGet package to publish.
        $NuspecPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The base directory for the files defined in the `NuspecPath` file.
        $NuspecBasePath,

        [string[]]
        # The server name(s) where the package should be published. Default is `nuget.org`.
        $Repository = @( 'nuget.org' ),

        [string]
        # The name of the NuGet package, if it is different than the module name.
        $PackageName,

        [object]
        # The API key(s) to use. To supply multiple API keys, use a hashtable where each key is a repository server name and the value is the API key for that repository. For example,
        #
        # @{ 'nuget.org' = '395edfa5-652f-4598-868e-c0a73be02c84' }
        #
        # If not specified, you'll be prompted for it. 
        $ApiKey
    )

    Set-StrictMode -Version 'Latest'

    $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath '..\bin\NuGet.exe' -Resolve
    if( -not $nugetPath )
    {
        return
    }

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    if( -not $PackageName )
    {
        $PackageName = $manifest.Name
    }

    Push-Location -Path $NuSpecBasePath
    try
    {

        $nupkgPath = Join-Path -Path (Get-Location) -ChildPath ('{0}.{1}.nupkg' -f $PackageName,$manifest.Version)
        if( (Test-Path -Path $nupkgPath -PathType Leaf) )
        {
            Remove-Item -Path $nupkgPath
        }

        foreach( $repoName in $Repository )
        {
            $serverUrl = 'https://{0}' -f $repoName
            $packageUrl = '{0}/api/v2/package/{1}/{2}' -f $serverUrl,$PackageName,$manifest.Version
            try
            {
                $resp = Invoke-WebRequest -Uri $packageUrl -ErrorAction Ignore
                $publish = ($resp.StatusCode -ne 200)
            }
            catch
            {
                $publish = $true
            }

            if( -not $publish )
            {
                Write-Warning ('NuGet package {0} {1} already published to {2}.' -f $PackageName,$manifest.Version,$repoName)
                continue
            }

            if( -not (Test-Path -Path $nupkgPath -PathType Leaf) )
            {
                & $nugetPath pack $NuspecPath -BasePath '.' -NoPackageAnalysis
                if( -not (Test-Path -Path $nupkgPath -PathType Leaf) )
                {
                    Write-Error ('NuGet package ''{0}'' not found.' -f $nupkgPath)
                    return
                }
            }

            $repoApiKey = $null
            if( $ApiKey -is [string] )
            {
                $repoApiKey = $ApiKey
            }
            elseif( $ApiKey -is [hashtable] -and $ApiKey.Contains($repoName) )
            {
                $repoApiKey = $ApiKey[$repoName]
            }
            elseif( $ApiKey )
            {
                Write-Error ('ApiKey parmaeter must be a [string] or a [hashtable], but is a [{0}].' -f $ApiKey.GetType())
                return
            }

            if( -not $repoApiKey )
            {
                $repoApiKey = Read-Host -Prompt ('Please enter your {0} API key' -f $repoName)
                if( -not $repoApiKey )
                {
                    Write-Error -Message ('The {0} API key is required. Package not published to {1}.' -f $repoName)
                    continue
                }
            }

            & $nugetPath push $nupkgPath -ApiKey $repoApiKey -Source $serverUrl

            $resp = Invoke-WebRequest -Uri $packageUrl
            $resp | Select-Object -Property 'StatusCode','StatusDescription',@{ Name = 'Uri'; Expression = { $packageUrl }}
        }
    }
    finally
    {
        Pop-Location
    }
}