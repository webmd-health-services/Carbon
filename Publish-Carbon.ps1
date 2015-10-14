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

function Copy-Carbon
{
    param(
        $Source,
        $Destination
    )

    foreach( $item in @( 'Carbon', 'Website', 'Examples', $licenseFileName, $releaseNotesFileName, $noticeFileName ) )
    {
        $sourcePath = Join-Path -Path $Source -ChildPath $item

        if( (Test-Path -Path $sourcePath -PathType Container) )
        {
            robocopy $sourcePath (Join-Path -Path $Destination -ChildPath $item) /MIR /XF *.orig /XF *.pdb | Write-Debug
        }
        else
        {
            Copy-Item -Path $sourcePath -Destination $Destination
        }
    }

    # Put another copy of the license file with the module.
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $noticeFileName) `
                -Destination (Join-Path -Path $Destination -ChildPath 'Carbon')
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $licenseFileName) `
                -Destination (Join-Path -Path $Destination -ChildPath 'Carbon')
}

function Test-Uri
{
    param(
        [Uri]
        $Uri
    )

    try
    {
        $resp = Invoke-WebRequest -Uri $Uri -ErrorAction Ignore
        return ($resp.StatusCode -eq 200)
    }
    catch
    {
        return $false
    }
}

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)
& (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\Import-Silk.ps1' -Resolve)

$licenseFileName = 'LICENSE.txt'
$noticeFileName = 'NOTICE.txt'
$releaseNotesFileName = 'RELEASE NOTES.txt'
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

if( -not $SkipWebsite )
{
    Write-Verbose -Message ('Generating website.')
    & (Join-Path -Path $PSScriptRoot -ChildPath 'New-Website.ps1' -Resolve)
    hg addremove 'Website'
    if( (hg status 'Website') )
    {
        hg commit -m ('[{0}] Updating website.' -f $manifest.Version) 'Website'
        hg log -rtip
    }
}

$tags = Get-Content -Raw -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tags.json') |
            ConvertFrom-Json |
            ForEach-Object { $_ } |
            Select-Object -ExpandProperty 'Tags' |
            Select-Object -Unique |
            Sort-Object |
            ForEach-Object { $_.ToLower() -replace ' ','-' }
$tags += @( 'PSModule', 'DscResources', 'setup', 'automation', 'admin' )

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

if( -not (hg log -r ('tag({0})' -f $manifest.Version)) )
{
    hg tag $manifest.Version.ToString()
    hg log -rtip
}

# Create a clean clone so that our packages don't pick up any cruft.
$cloneDir = New-TempDirectory -Prefix 'Carbon'
hg clone . $cloneDir
hg update -r ('tag({0})' -f $manifest.Version) -R $cloneDir

$carbonZipFileName = "Carbon-{0}.zip" -f $manifest.Version
$zipDownloadUrl = 'https://bitbucket.org/splatteredbits/carbon/downloads/{0}' -f $carbonZipFileName

if( (Test-Uri $zipDownloadUrl) )
{
    Write-Warning -Message ('Bitbucket ZIP file already published.')
}
else
{
    $zipRoot = New-TempDirectory -Prefix 'Carbon'
    try
    {
        Copy-Carbon -Source $cloneDir -Destination $zipRoot

        if( Test-Path $carbonZipFileName -PathType Leaf )
        {
            Remove-Item $carbonZipFileName
        }

        Compress-Item -Path (Get-ChildItem -Path $zipRoot) `
                      -OutFile (Join-Path -Path $PSScriptRoot -ChildPath $carbonZipFileName)

        Publish-BitbucketDownload -Username 'splatteredbits' `
                                  -ProjectName 'carbon' `
                                  -FilePath $carbonZipFileName

        $resp = Invoke-WebRequest -Uri $zipDownloadUrl
        $resp | Select-Object -Property 'StatusCode','StatusDescription',@{ Name = 'Uri'; Expression = { $zipDownloadUrl }}
    }
    finally
    {
        Remove-Item -Path $zipRoot -Recurse
    }
}

$nugetPackageUrl = 'http://www.nuget.org/api/v2/package/Carbon/{0}' -f $manifest.Version
$publishToNuGet = -not (Test-Uri -Uri $nugetPackageUrl)

$chocolatelyPackageUrl = 'https://chocolatey.org/api/v2/package/carbon/{0}' -f $manifest.Version
$publishToChocolatey = -not (Test-Uri -Uri $chocolatelyPackageUrl)

if( -not $publishToNuGet -and -not $publishToChocolatey )
{
    Write-Warning -Message ('NuGet and Chocolatey packages already published.')
}
else
{
    Write-Verbose -Message ('Publishing NuGet/Chocolatey packages.')
    $nugetRoot = New-TempDirectory -Prefix 'CarbonNuGet'
    try
    {
        Copy-Carbon -Source $cloneDir -Destination $nugetRoot

        # Create the NuGet package.
        foreach( $file in @( '*.txt', 'Carbon.nuspec' ) )
        {
            Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $file) `
                        -Destination $nugetRoot
        }

        $toolsDir = Join-Path -Path $nugetRoot -ChildPath 'tools'
        New-Item -Path $toolsDir -ItemType 'directory' | Out-String | Write-Verbose
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Tools') -Filter 'chocolatey*.ps1' |
            Copy-Item -Destination $toolsDir

        $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\bin\nuget.exe' -Resolve
        if( -not $nugetPath )
        {
            return
        }

        Push-Location -Path $nugetRoot
        try
        {
            & $nugetPath pack '.\Carbon.nuspec' -BasePath '.' -NoPackageAnalysis
            $carbonNupkgPath = Join-Path -Path $nugetRoot -ChildPath ('Carbon.{0}.nupkg' -f $nuGetVersion) -Resolve
            if( -not $carbonNupkgPath )
            {
                return
            }
        }
        finally
        {
            Pop-Location
        }
        
        # Publish to NuGet
        if( $publishToNuGet )
        {
            Publish-NuGetPackage -FilePath $carbonNupkgPath
            $resp = Invoke-WebRequest -Uri $nugetPackageUrl
            $resp | Select-Object -Property 'StatusCode','StatusDescription',@{ Name = 'Uri'; Expression = { $nugetPackageUrl }}
        }
        else
        {
            Write-Warning ('NuGet package already published.')
        }

        # Publish to NuGet
        if( $publishToChocolatey )
        {
            Publish-ChocolateyPackage -FilePath $carbonNupkgPath
            $resp = Invoke-WebRequest -Uri $chocolatelyPackageUrl
            $resp | Select-Object -Property 'StatusCode','StatusDescription',@{ Name = 'Uri'; Expression = { $chocolatelyPackageUrl }}
        }
        else
        {
            Write-Warning ('Chocolatey package already published.')
        }
    }
    finally
    {
        Remove-Item -Path $nugetRoot -Recurse
    }
}

Publish-PowerShellGalleryModule -Name 'Carbon' `
                                -Path (Join-Path -Path $cloneDir -ChildPath 'Carbon') `
                                -Version $manifest.Version `
                                -LicenseUri 'http://www.apache.org/licenses/LICENSE-2.0' `
                                -ReleaseNotes $versionReleaseNotes `
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

$announcement = @'
[Carbon](http://get-carbon.org) {0} is out. You can [download Carbon as a .ZIP archive, NuGet package, Chocolatey package, or from the PowerShell Gallery](http://get-carbon.org/about_Carbon_Installation.html). It may take a week or two for the package to show up at chocolatey.org.

{1}
'@ -f $manifest.Version,$versionReleaseNotes

& $newModuleReleasedAnnouncement -ModuleName 'Carbon' -Version $manifest.Version -Content $announcement

