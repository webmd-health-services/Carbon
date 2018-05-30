<#
.SYNOPSIS
Packages and publishes Carbon packages.
#>

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

[CmdletBinding()]
param(
    [Version]
    # The version to build. If not supplied, build the version as currently defined.
    $Version,

    [string]
    # The pre-release version, e.g. alpha.39, rc.1, etc.
    $PreReleaseVersion,

    [string]
    # Build metadata.
    $BuildMetadata,

    [string]
    $PipelineName
)

#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Whiskey\Import-Whiskey.ps1' -Resolve)

$optionalParams = @{ }
if( $PipelineName )
{
    $optionalParams['PipelineName'] = $PipelineName
}

$whiskeyYmlPath = Join-Path -Path $PSScriptRoot -ChildPath 'whiskey.yml'
$context = New-WhiskeyContext -Environment 'Dev' -ConfigurationPath $whiskeyYmlPath

$apiKeys = @{
                'powershellgallery.com' = 'env:';
                'nuget.org' = 'env:';
                'chocolatey.org' = 'env:'
            }
foreach( $apiKeyID in $apiKeys.Keys )
{
    Add-WhiskeyApiKey -Context $context -ID $apiKeyID -Value $apiKeys[$apiKeyID]
}
Invoke-WhiskeyBuild -Context $context @optionalParams

return

<#& (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\Import-Silk.ps1' -Resolve)
Set-ModuleVersion -ManifestPath (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Carbon.psd1') `
                  -SolutionPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.sln') `
                  -AssemblyInfoPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Properties\AssemblyVersion.cs') `
                  -Version $Version `
                  -PreReleaseVersion $PreReleaseVersion `
                  -BuildMetadata $BuildMetadata `
                  -ReleaseNotesPath (Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE NOTES.txt' -Resolve) `
                  -NuspecPath (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.nuspec' -Resolve)

#>