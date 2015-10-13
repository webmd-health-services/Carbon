<#
.SYNOPSIS
Packages and publishes Carbon packages.
#>

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
    $BuildMetadata
)

#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\Import-Silk.ps1' -Resolve)

$moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon' -Resolve
if( -not $Version )
{
    $Version = Test-ModuleManifest -Path (Join-Path -Path $moduleRoot -ChildPath 'Carbon.psd1') | Select-Object -ExpandProperty 'Version'
    if( -not $Version )
    {
        return
    }
}

$releaseNotesFileName = 'RELEASE NOTES.txt'
$releaseNotesPath = Join-Path -Path $PSScriptRoot -ChildPath $releaseNotesFileName -Resolve
$newVersionHeader = "# {0}" -f $Version
$updatedVersion = $false
$releaseNotes = Get-Content -Path $releaseNotesPath |
                    ForEach-Object {
                        if( -not $updatedVersion -and $_ -match '^#\s+' )
                        {
                            $updatedVersion = $true
                            return $newVersionHeader
                        }

                        return $_
                    }
$releaseNotes | Set-Content -Path $releaseNotesPath

Set-ModuleVersion -ManifestPath (Join-Path -Path $moduleRoot -ChildPath 'Carbon.psd1') `
                  -SolutionPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.sln') `
                  -AssemblyInfoPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Properties\AssemblyVersion.cs') `
                  -Version $Version `
                  -PreReleaseVersion $PreReleaseVersion `
                  -BuildMetadata $BuildMetadata
