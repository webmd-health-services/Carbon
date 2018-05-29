
function Resolve-WhiskeyDotNetSdkVersion
{
    <#
    .SYNOPSIS
    Searches for a version of the .NET Core SDK to ensure it exists and returns the resolved version.

    .DESCRIPTION
    The `Resolve-WhiskeyDotNetSdkVersion` function ensures a given version is a valid released version of the .NET Core SDK. By default, the function will return the latest LTS version of the SDK. If a `Version` number is given then that version is compared against the list of released SDK versions to ensure the given version is valid. If no valid version is found matching `Version`, then an error is written and nothing is returned.

    .EXAMPLE
    Resolve-WhiskeyDotNetSdkVersion -LatestLTS

    Demonstrates returning the latest LTS version of the .NET Core SDK.

    .EXAMPLE
    Resolve-WhiskeyDotNetSdkVersion -Version '2.1.2'

    Demonstrates ensuring that version '2.1.2' is a valid released version of the .NET Core SDK.

    .EXAMPLE
    Resolve-WhiskeyDotNetSdkVersion -Version '2.*'

    Demonstrates resolving the latest '2.x.x' version of the .NET Core SDK.
    #>
    [CmdletBinding(DefaultParameterSetName='LatestLTS')]
    param(
        [Parameter(ParameterSetName='LatestLTS')]
        [switch]
        # Returns the latest LTS version of the .NET Core SDK.
        $LatestLTS,

        [Parameter(Mandatory=$true, ParameterSetName='Version')]
        [string]
        # Version of the .NET Core SDK to search for and resolve. Accepts wildcards.
        $Version
    )

    Set-StrictMode -version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($Version)
    {
        $releasesJsonUri = 'https://raw.githubusercontent.com/dotnet/core/master/release-notes/releases.json'

        Write-Verbose -Message ('[{0}] Resolving .NET Core SDK version ''{1}'' against known released versions at: ''{2}''' -f $MyInvocation.MyCommand,$Version,$releasesJsonUri)
        $releasesJson = Invoke-RestMethod -Uri $releasesJsonUri -ErrorAction Stop

        $sdkVersions =  $releasesJson |
                            Select-Object -ExpandProperty 'version-sdk' -Unique |
                            Where-Object { $_ -match '^\d+\.\d+\.\d+$' } |
                            Sort-Object -Descending

        $resolvedVersion =  $sdkVersions |
                                Where-Object { $_ -like $Version } |
                                Select-Object -First 1

        if (-not $resolvedVersion)
        {
            Write-Error -Message ('A released version of the .NET Core SDK matching ''{0}'' could not be found in ''{1}''' -f $Version, $releasesJsonUri)
            return
        }

        Write-Verbose -Message ('[{0}] SDK version ''{1}'' resolved to ''{2}''' -f $MyInvocation.MyCommand,$Version,$resolvedVersion)
    }
    else
    {
        $latestLTSVersionUri = 'https://dotnetcli.blob.core.windows.net/dotnet/Sdk/LTS/latest.version'

        Write-Verbose -Message ('[{0}] Resolving latest LTS version of .NET Core SDK from: ''{1}''' -f $MyInvocation.MyCommand,$latestLTSVersionUri)
        $latestLTSVersion = Invoke-RestMethod -Uri $latestLTSVersionUri -ErrorAction Stop

        if ($latestLTSVersion -match '(\d+\.\d+\.\d+)')
        {
            $resolvedVersion = $Matches[1]
        }
        else
        {
            Write-Error -Message ('Could not retrieve the latest LTS version of the .NET Core SDK. ''{0}'' returned:{1}{2}' -f $latestLTSVersionUri,[Environment]::NewLine,$latestLTSVersion)
            return
        }

        Write-Verbose -Message ('[{0}] Latest LTS version resolved as: ''{1}''' -f $MyInvocation.MyCommand,$resolvedVersion)
    }

    return $resolvedVersion
}
