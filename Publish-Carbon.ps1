<#
.SYNOPSIS
Packages and publishes Carbon packages.

.DESCRIPTION
The `Publish-Carbon.ps1` script packages and publishes a version of the Carbon module. It use the version defined in the Carbon.psd1 file. Before publishing, it adds the current date to the version in the release notes, updates the module's website, then tags the latest revision with the version number. It then publishes the module to Bitbucket, NuGet, Chocolatey, and PowerShell Gallery. If the version of Carbon being publishes already exists in a location, it is not re-published. If the PowerShellGet module isn't installed, the module is not publishes to the PowerShell Gallery.

.EXAMPLE
Publish-Carbon.ps1

Yup. That's it.
#>
[CmdletBinding()]
param(
    [Switch]
    # Skip generating the website.
    $SkipWebsite
)

#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)
& (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\Import-Silk.ps1' -Resolve)

$licenseFileName = 'LICENSE.txt'
$noticeFileName = 'NOTICE.txt'
$releaseNotesFileName = 'CHANGELOG.md'
$releaseNotesPath = Join-Path -Path $PSScriptRoot -ChildPath $releaseNotesFileName -Resolve

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Carbon.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath
if( -not $manifest )
{
    return
}

$additionalAssemblyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\bin\Carbon.*.dll'
$nuspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.nuspec'
$valid = Assert-ModuleVersion -ManifestPath $manifestPath -AssemblyPath $additionalAssemblyPath -ReleaseNotesPath $releaseNotesPath -NuspecPath $nuspecPath
if( -not $valid )
{
    Write-Error -Message ('Carbon isn''t at the right version. Please rebuild with build.ps1.')
    return
}

Set-ReleaseNotesReleaseDate -ManifestPath $manifestPath -ReleaseNotesPath $releaseNotesPath
if( hg status $releaseNotesPath )
{
    hg commit -m ('[{0}] Updating release date in release notes.' -f $manifest.Version) $releaseNotesPath
    hg log -rtip
}


if( -not $SkipWebsite )
{
    Write-Verbose -Message ('Generating website.')
    & (Join-Path -Path $PSScriptRoot -ChildPath 'New-Website.ps1' -Resolve)
    Write-Warning -Message ('Website updated. Make sure to commit and push all the changes.')
}

$tags = Get-Content -Raw -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tags.json') |
            ConvertFrom-Json |
            ForEach-Object { $_ } |
            Select-Object -ExpandProperty 'Tags' |
            Select-Object -Unique |
            Sort-Object |
            ForEach-Object { $_.ToLower() -replace ' ','-' }
$tags += @( 'PSModule', 'DscResources', 'setup', 'automation', 'admin' )

Set-ModuleManifestMetadata -ManifestPath $manifestPath -Tag $tags -ReleaseNotesPath $releaseNotesPath
if( hg status $manifestPath )
{
    hg commit -m ('[{0}] Updating module manifest.' -f $manifest.Version) $manifestPath
    hg log -r tip
}

$nuspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.nuspec' -Resolve
if( -not $nuspecPath )
{
    return
}

Set-ModuleNuspec -ManifestPath $manifestPath -NuspecPath $nuspecPath -ReleaseNotesPath $releaseNotesPath -Tags $tags

if( (hg status $nuspecPath) )
{
    hg commit -m ('[{0}] Updating Nuspec settings.' -f $manifest.Version) $nuspecPath
    hg log -rtip
}

if( -not (hg tags | Where-Object { $_ -match ('^{0}\b' -f [regex]::Escape($manifest.Version.ToString())) }) )
{
    hg tag $manifest.Version.ToString()
    hg log -rtip
}

# Create a clean clone so that our packages don't pick up any cruft.
$cloneDir = 'Carbon+{0}' -f [IO.Path]::GetRandomFileName()
$cloneDir = Join-Path -Path $env:TEMP -ChildPath $cloneDir
hg clone . $cloneDir
hg update -r ('tag({0})' -f $manifest.Version) -R $cloneDir

$zipRoot = 'Carbon+{0}' -f [IO.Path]::GetRandomFileName()
$zipRoot = Join-Path -Path $env:TEMP -ChildPath $zipRoot

$zipContents = @(
                    'Carbon',
                    'examples',
                    'Website', 
                    $licenseFileName, 
                    $releaseNotesFileName, 
                    $noticeFileName
                ) 

foreach( $item in $zipContents )
{
    $sourcePath = Join-Path -Path $cloneDir -ChildPath $item

    if( (Test-Path -Path $sourcePath -PathType Container) )
    {
        robocopy $sourcePath (Join-Path -Path $zipRoot -ChildPath $item) /MIR /XF *.orig /XF *.pdb | Write-Debug
    }
    else
    {
        Copy-Item -Path $sourcePath -Destination $zipRoot
    }
}

# Put another copy of the license and notice files with the module.
Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $noticeFileName) `
            -Destination (Join-Path -Path $zipRoot -ChildPath 'Carbon')
Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $licenseFileName) `
            -Destination (Join-Path -Path $zipRoot -ChildPath 'Carbon')

#Publish-BitbucketDownload -Username 'splatteredbits' `
#                          -ProjectName 'carbon' `
#                          -Path (Get-ChildItem -Path $zipRoot) `
#                          -ManifestPath $manifestPath

Publish-NuGetPackage -ManifestPath $manifestPath `
                     -NuspecPath (Join-Path -Path $cloneDir -ChildPath 'Carbon.nuspec') `
                     -NuspecBasePath $cloneDir `
                     -Repository @( 'nuget.org', 'chocolatey.org' )

Publish-PowerShellGalleryModule -ManifestPath $manifestPath `
                                -ModulePath (Join-Path -Path $cloneDir -ChildPath 'Carbon') `
                                -ReleaseNotesPath $releaseNotesPath `
                                -LicenseUri 'http://www.apache.org/licenses/LICENSE-2.0' `
                                -ProjectUri 'http://get-carbon.org/' `
                                -Tags $tags

$pshdoRoot = Join-Path -Path $PSScriptRoot -ChildPath 'pshdo.com'
if( -not (Test-Path -Path $pshdoRoot -PathType Container) )
{
    hg clone https://bitbucket.org/splatteredbits/pshdo.com $pshdoRoot
}

hg pull -R $pshdoRoot
hg update -C -R $pshdoRoot

$newModuleReleasedAnnouncement = Join-Path -Path $pshdoRoot -ChildPath 'New-ModuleReleasedAnnouncement.ps1' -Resolve
if( -not $newModuleReleasedAnnouncement )
{
    return
}

$releaseNotes = Get-ModuleReleaseNotes -ManifestPath $manifestPath -ReleaseNotesPath $releaseNotesPath
$announcement = @'
[Carbon](http://get-carbon.org) {0} is out. You can [download Carbon as a .ZIP archive, NuGet package, Chocolatey package, or from the PowerShell Gallery](http://get-carbon.org/about_Carbon_Installation.html). It may take a week or two for the package to show up at chocolatey.org.

{1}
'@ -f $manifest.Version,$releaseNotes

& $newModuleReleasedAnnouncement -ModuleName 'Carbon' -Version $manifest.Version -Content $announcement

