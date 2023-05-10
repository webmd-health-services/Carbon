#!/usr/bin/env pwsh

<#
.SYNOPSIS
Starts a Whiskey build.

.DESCRIPTION
The `build.ps1` script starts a Whiskey build in the script's directory. It first download the latest `0.*` version of
Whiskey from Whiskey's GitHub [Releases](https://github.com/webmd-health-services/Whiskey/releases) and place it into a
`PSModules/Whiskey` directory. The script will look for a `whiskey.yml` file in the same directory as itself. If one
doesn't exit, it will create a new starter `whiskey.yml` file with empty `Build` and `Publish` pipelines. Finally,
`Invoke-WhiskeyBuild` is called to run the build tasks specified in the `whiskey.yml`.

Pass the token to use to authenticate to GitHub to the `GitHubBearerToken` parameter. Or, you can set the a
`GITHUB_BEARER_TOKEN` environment variable to the bearer token to use.

To download all the tools that are required for a build, use the `-Initialize` switch.

To run a specific pipeline from the whiskey.yml file, pass the pipeline name to the `PipelineName` parameter. By
default, runs the `Build` pipeline.

To run a build using a specific whiskey.yml file, use the `ConfigurationPath` parameter.

To cleanup downloaded build tools and artifacts created from previous builds, use the `-Clean` switch.

.EXAMPLE
./build.ps1

Starts a Whiskey build.

.EXAMPLE
./build.ps1 -Clean

Demonstrates how to use Whiskey to clean up any downloaded build tools and previously built artifacts.

.EXAMPLE
./build.ps1 -Initialize

Demonstrates how to initialize the build root with any tools that are required by tasks in the `whiskey.yml` file.

.EXAMPLE
./build.ps1 -PipelineName Test

Demonstrates how to run a specific pipeline from the whiskey.yml file. In this example, the `Test` pipeline is run.

.EXAMPLE
./build.ps1 -ConfigurationPath '../whiskey.yml'

Demonstrates how to run a build using a specific whiskey.yml file. In this example, the whiskey.yml file in the
current directory's parent directory will be used.
#>
[CmdletBinding(DefaultParameterSetName='Build')]
param(
    [Parameter(Mandatory,ParameterSetName='Clean')]
    # Runs the build in clean mode, which removes any files, tools, packages created by previous builds.
    [switch] $Clean,

    [Parameter(Mandatory,ParameterSetName='Initialize')]
    # Initializes the repository.
    [switch] $Initialize,

    # Run a specific pipeline. The default is to run the `Build` pipeline.
    [String] $PipelineName,

    # Run a build using a specific whiskey.yml file. The default is to use a whiskey.yml file in the same directory
    # as this script.
    [String] $ConfigurationPath,

    # The bearer token to use to authenticate with the GitHub API when getting the Whiskey releases. The default value
    # is the `GITHUB_BEARER_TOKEN` environment variable.
    [String] $GitHubBearerToken
)

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version Latest

# Set to a specific version to use a specific version of Whiskey.
$whiskeyVersion = '0.*'
$allowPrerelease = $false

$psModulesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'PSModules'
$whiskeyModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Whiskey'

if( -not (Test-Path -Path $whiskeyModuleRoot -PathType Container) )
{
    $headers = @{ 'Content-Type' = 'application/json' }
    if (-not $GitHubBearerToken -and $env:GITHUB_BEARER_TOKEN)
    {
        $GitHubBearerToken = $env:GITHUB_BEARER_TOKEN
        $headers['Authorization'] = "Bearer ${GitHubBearerToken}"
    }
    if ($GitHubBearerToken)
    {
        $headers['Authorization'] = "Bearer ${GitHubBearerToken}"
    }
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $release =
        Invoke-RestMethod -Uri 'https://api.github.com/repos/webmd-health-services/Whiskey/releases' -Headers $headers |
        ForEach-Object { $_ } |
        Where-Object { $_.name -like $whiskeyVersion } |
        Where-Object {
            if( $allowPrerelease )
            {
                return $true
            }
            [Version]::TryParse($_.name,[ref]$null)
        } |
        Sort-Object -Property 'created_at' -Descending |
        Select-Object -First 1

    if( -not $release )
    {
        Write-Error -Message ('Whiskey version "{0}" not found.' -f $whiskeyVersion) -ErrorAction Stop
        return
    }

    $zipUri =
        $release.assets |
        ForEach-Object { $_ } |
        Where-Object { $_.name -like 'Whiskey*.zip' } |
        Select-Object -ExpandProperty 'browser_download_url'

    if( -not $zipUri )
    {
        Write-Error -Message ('URI to Whiskey ZIP file does not exist.') -ErrorAction Stop
    }

    Write-Verbose -Message ('Found Whiskey {0}.' -f $release.name)

    if( -not (Test-Path -Path $psModulesRoot -PathType Container) )
    {
        New-Item -Path $psModulesRoot -ItemType 'Directory' | Out-Null
    }
    $zipFilePath = Join-Path -Path $psModulesRoot -ChildPath 'Whiskey.zip'
    & {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $zipUri -OutFile $zipFilePath
    }

    # Whiskey.zip uses Windows directory separator which extracts strangely on Linux. So, we have
    # to extract each entry by hand.
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    $zipFile = [IO.Compression.ZipFile]::OpenRead($zipFilePath)
    try
    {
        foreach( $entry in $zipFile.Entries )
        {
            $destinationPath = Join-Path -Path $whiskeyModuleRoot -ChildPath $entry.FullName
            $destinationDirectory = $destinationPath | Split-Path
            if( -not (Test-Path -Path $destinationDirectory -PathType Container) )
            {
                New-Item -Path $destinationDirectory -ItemType 'Directory' | Out-Null
            }
            Write-Debug -Message ('{0} -> {1}' -f $entry.FullName,$destinationPath)
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true)
        }
    }
    finally
    {
        $zipFile.Dispose()
    }

    # Remove any prerelease information.
    $moduleDirName = $release.name -replace '-.*$',''
    Rename-Item -Path (Join-Path -Path $whiskeyModuleRoot -ChildPath 'Whiskey') -NewName $moduleDirName

    Remove-Item -Path $zipFilePath
}

& {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module -Name $whiskeyModuleRoot -Force
}

if (-not $ConfigurationPath)
{
    $ConfigurationPath = Join-Path -Path $PSScriptRoot -ChildPath 'whiskey.yml'
    if( -not (Test-Path -Path $ConfigurationPath -PathType 'Leaf') )
    {
        @'
Build:
- Version:
    Version: 0.0.0

Publish:

'@ | Set-Content -Path $ConfigurationPath
    }
}

$optionalArgs = @{ }
if( $Clean )
{
    $optionalArgs['Clean'] = $true
}

if( $Initialize )
{
    $optionalArgs['Initialize'] = $true
}

if ($PipelineName)
{
    $optionalArgs['PipelineName'] = $PipelineName
}

$context = New-WhiskeyContext -Environment 'Dev' -ConfigurationPath $ConfigurationPath
Invoke-WhiskeyBuild -Context $context @optionalArgs
