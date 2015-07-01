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
    $PreReleaseVersion
)

#Requires -Version 4
Set-StrictMode -Version Latest

if( $Version )
{
    if( $Version.Build -lt 0 )
    {
        Write-Error ('Version number must have a build number, i.e. it must have three parts.' -f $Version)
        return
    }

    if( $Version.Revision -ge 0 )
    {
        Write-Error ('Version number must not have a revision number, i.e. it must only have three parts.' -f $Version)
        return
    }

    $releaseNotesFileName = 'RELEASE NOTES.txt'
    $releaseNotesPath = Join-Path $PSScriptRoot $releaseNotesFileName -Resolve
    $newVersionHeader = "# {0}" -f $Version
    $updatedVersion = $false
    $releaseNotes = Get-Content -Path $releaseNotesPath |
                        ForEach-Object {
                            if( -not $updatedVersion -and $_ -match '^# (Next|\d+\.\d+\.\d+)$' )
                            {
                                $updatedVersion = $true
                                return $newVersionHeader
                            }
                            return $_
                        }
    $releaseNotes | Set-Content -Path $releaseNotesPath

    $manifestPath = Join-Path $PSScriptRoot Carbon\Carbon.psd1 -Resolve
    $manifest = Get-Content $manifestPath
    $manifest |
        ForEach-Object {
            if( $_ -like 'ModuleVersion = *' )
            {
                'ModuleVersion = ''{0}''' -f $Version.ToString()
            }
            else
            {
                $_
            }
        } |
        Set-Content -Path $manifestPath

    $assemblyVersionPath = Join-Path -Path $PSScriptRoot -ChildPath 'Source\Properties\AssemblyVersion.cs'
    $assemblyVersionRegex = 'Assembly(File|Informational)?Version\("[^"]*"\)'
    $assemblyVersion = Get-Content -Path $assemblyVersionPath |
                            ForEach-Object {
                                if( $_ -match $assemblyVersionRegex )
                                {
                                    $infoVersion = ''
                                    if( $Matches[1] -eq 'Informational' -and $PreReleaseVersion)
                                    {
                                        $infoVersion = '-{0}' -f $PreReleaseVersion
                                    }
                                    return $_ -replace $assemblyVersionRegex,('Assembly$1Version("{0}{1}")' -f $Version,$infoVersion)
                                }
                                $_
                            }
    $assemblyVersion | Set-Content -Path $assemblyVersionPath
}

$msbuildRoot = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\12.0 -Name 'MSBuildToolsPath' | Select-Object -ExpandProperty 'MSBuildToolsPath'
$msbuildExe = Join-Path -Path $msbuildRoot -ChildPath 'MSBuild.exe' -Resolve
if( -not $msbuildExe )
{
    return
}

$carbonBinPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\bin'
Get-ChildItem -Path $carbonBinPath -Exclude *.ps1,'Ionic.Zip.dll','Microsoft.Web.XmlTransform.dll' | Remove-Item
& $msbuildExe /target:"clean;build" (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.sln') /v:m /nologo
Get-ChildItem -Path $carbonBinPath -Filter *.pdb | Remove-Item
