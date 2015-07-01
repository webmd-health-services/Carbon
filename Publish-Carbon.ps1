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
    [Parameter(Mandatory=$true)]
    [Version]
    # The version to be published.
    $Version,

    [Parameter(ParameterSetName='All')]
    [Switch]
    $All,
    
    [Parameter(ParameterSetName='Some')]
    [Switch]
    $ZipPackage,

    [Parameter(ParameterSetName='Some')]
    [Switch]
    # Updates the Carbon version and re-builds the binaries.
    $Build,

    [Parameter(ParameterSetName='Some')]
    [Switch]
    # Update the website.
    $Website,

    [Parameter(ParameterSetName='Some')]
    [Switch]
    # Commit any changes made by the publishing process.
    $Commit
)

#Requires -Version 4
Set-StrictMode -Version Latest

if( $PSCmdlet.ParameterSetName -eq 'Some' )
{
    $All = $false
}

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$licenseFileName = 'LICENSE.txt'
$releaseNotesFileName = 'RELEASE NOTES.txt'

if( $All -or $Build )
{
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
                                    return $_ -replace $assemblyVersionRegex,('Assembly$1Version("{0}.0")' -f $Version)
                                }
                                $_
                            }
    $assemblyVersion | Set-Content -Path $assemblyVersionPath

    $msbuildRoot = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\12.0 -Name 'MSBuildToolsPath' | Select-Object -ExpandProperty 'MSBuildToolsPath'
    $msbuildExe = Join-Path -Path $msbuildRoot -ChildPath 'MSBuild.exe' -Resolve
    if( -not $msbuildExe )
    {
        return
    }

    $carbonBinPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\bin'
    Get-ChildItem -Path $carbonBinPath -Exclude *.ps1,'Ionic.Zip.dll','Microsoft.Web.XmlTransform.dll' | Remove-Item
    & $msbuildExe /target:"clean;build" (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.sln') /property:Configuration=Release
    Get-ChildItem -Path $carbonBinPath -Filter *.pdb | Remove-Item
}

if( $All -or $Website )
{
    $helpDirPath = Join-Path $PSScriptRoot Website\help
    Get-ChildItem $helpDirPath *.html | Remove-Item 
        
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Out-Html.ps1' -Resolve) -OutputDir $helpDirPath        

    hg addremove $helpDirPath

}

if( $All -or $ZipPackage )
{
    $releaseNotesPath = Join-Path $PSScriptRoot $releaseNotesFileName -Resolve
    $newVersionHeader = "# {0} ({1})" -f $Version,((Get-Date).ToString("d MMMM yyyy"))
    $releaseNotes = Get-Content -Path $releaseNotesPath |
                        ForEach-Object {
                            if( $_ -match '^# Next$' )
                            {
                                return $newVersionHeader
                            }
                            elseif( $_ -match '^# {0}\s*' -f [regex]::Escape($Version.ToString()) )
                            {
                                return $newVersionHeader
                            }
                            return $_
                        }
    $releaseNotes | Set-Content -Path $releaseNotesPath

    $carbonZipFileName = "Carbon-{0}.zip" -f $Version

    $aspNetClientPath = Join-Path -Path $PSScriptRoot -ChildPath 'Website\aspnet_client'
    if( (Test-Path -Path $aspNetClientPath -PathType Container) )
    {
        Remove-Item -Path $aspNetClientPath -Recurse
    }
        
    if( Test-Path $carbonZipFileName -PathType Leaf )
    {
        Remove-Item $carbonZipFileName
    }

    $tempDir = [IO.Path]::GetRandomFileName()
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir

    New-Item -Path $tempDir -ItemType 'Directory' | Out-String | Write-Verbose

    try
    {
        foreach( $item in @( 'Carbon', 'Website', 'Examples', $licenseFileName, $releaseNotesFileName ) )
        {
            $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath $item
            $extraFiles = hg st --unknown --ignored $sourcePath
            if( $extraFiles )
            {
                Write-Error ('Unable to package: there are unknown/ignored files in {0}:{1} {2}' -f $sourcePath,([Environment]::NewLine),($extraFiles -join ('{0} ' -f ([Environment]::NewLine))))
                return
            }

            if( (Test-Path -Path $sourcePath -PathType Container) )
            {
                robocopy $sourcePath (Join-Path -Path $tempDir -ChildPath $item) /MIR /XF *.orig /XF *.pdb | Write-Verbose
            }
            else
            {
                Copy-Item -Path $sourcePath -Destination $tempDir
            }
        }

        # Put another copy of the license file with the module.
        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $licenseFileName) -Destination (Join-Path -Path $tempDir -ChildPath 'Carbon')

        Compress-Item -Path (Get-ChildItem -Path $tempDir) -OutFile (Join-Path -Path $PSScriptRoot -ChildPath $carbonZipFileName)
    }
    finally
    {
        Remove-Item -Recurse -Path $tempDir
    }
}

if( $All -or $Commit )
{
    if( $All )
    {   
        hg commit -m ("Releasing version {0}." -f $Version) --include $releaseNotesFileName --include .\Website --include Carbon\Carbon.psd1 --include Carbon\bin
        if( -not (hg tags | Where-Object { $_ -like "$version*" } ) )
        {
            hg tag $version
        }
    }
}