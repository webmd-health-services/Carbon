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

    foreach( $item in @( 'Carbon', 'Website', 'Examples', $licenseFileName, $releaseNotesFileName ) )
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
$releaseNotesFileName = 'RELEASE NOTES.txt'
$releaseNotesPath = Join-Path -Path $PSScriptRoot -ChildPath $releaseNotesFileName -Resolve

$carbonModule = Get-Module -Name 'Carbon'
$version = $carbonModule.Version
Write-Verbose -Message ('Publishing version {0}.' -f $version)

$versionReleaseNotes = $null
foreach( $line in (Get-Content -Path $releaseNotesPath) )
{
    if( $line -match '^# ' )
    {
        $versionReleaseNotes = $line
        break
    }
}

if( $versionReleaseNotes -notmatch [regex]::Escape($version.ToString()) )
{
    Write-Error ('Unable to publish Carbon. Latest version in release notes file ''{0}'' is not {1}. Please build Carbon at that version, run tests, then publish again.' -f $versionReleaseNotes,$Version)
    return
}

$badAssemblies = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\bin') -Filter 'Carbon*.dll' |
                        Where-Object { 
                            -not ($_.VersionInfo.FileVersion.ToString().StartsWith($Version.ToString())) -or -not ($_.VersionInfo.ProductVersion.ToString().StartsWith($Version.ToString()))
                        } |
                        ForEach-Object {
                            ' * {0} (FileVersion: {1}; ProductVersion: {2})' -f $_.Name,$_.VersionInfo.FileVersion,$_.VersionInfo.ProductVersion
                        }
if( $badAssemblies )
{
    Write-Error ('Unable to publish Carbon. Versions of the following assemblies are not {0}. Please build Carbon at that version, run tests, then publish again.{1}{2}' -f $version,([Environment]::NewLine),($badAssemblies -join ([Environment]::NewLine)))
    return
}

$newVersionHeader = "# {0} ({1})" -f $version,((Get-Date).ToString("d MMMM yyyy"))
$releaseNotes = Get-Content -Path $releaseNotesPath |
                    ForEach-Object {
                        if( $_ -match '^# Next$' )
                        {
                            return $newVersionHeader
                        }
                        elseif( $_ -match '^# {0}\s*$' -f [regex]::Escape($version.ToString()) )
                        {
                            return $newVersionHeader
                        }
                        return $_
                    }
$releaseNotes | Set-Content -Path $releaseNotesPath
if( hg status $releaseNotesPath )
{
    hg commit -m ('[{0}] Updating release date in release notes.' -f $version) $releaseNotesPath
    hg log -rtip
}

if( -not $SkipWebsite )
{
    Write-Verbose -Message ('Generating website.')
    & (Join-Path -Path $PSScriptRoot -ChildPath 'New-Website.ps1' -Resolve)
    hg addremove 'Website'
    if( (hg status 'Website') )
    {
        hg commit -m ('[{0}] Updating website.' -f $version) 'Website'
        hg log -rtip
    }
}

$carbonNuspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.nuspec' -Resolve
if( -not $carbonNuspecPath )
{
    return
}

$foundVersion = $false
$versionReleaseNotes = Get-Content -Path $releaseNotesPath |
                        Where-Object {
                            $line = $_
                            if( -not $foundVersion )
                            {
                                if( $line -match ('^# {0}' -f [regex]::Escape($version)) )
                                {
                                    $foundVersion = $true
                                    return
                                }
                            }
                            else
                            {
                                if( $line -match ('^# (?!{0})' -f [regex]::Escape($version)) )
                                {
                                    $foundVersion = $false
                                }
                            }
                            return( $foundVersion )
                        }

$carbonNuspec = [xml](Get-Content -Raw -Path $carbonNuspecPath)
if( $carbonNuspec.package.metadata.version -ne $version.ToString() )
{
    $nuGetVersion = $version -replace '-([A-Z0-9]+)[^A-Z0-9]*(\d+)$','-$1$2'
    $carbonNuspec.package.metadata.version = $nugetVersion
    $carbonNuspec.package.metadata.releaseNotes = $versionReleaseNotes -join ([Environment]::NewLine)
    $carbonNuspec.Save( $carbonNuspecPath )
}

if( hg status $carbonNuspecPath )
{
    hg commit -m ('[{0}] Updating Carbon.' -f $version) $carbonNuspecPath
    hg log -rtip
}

if( -not (hg log -r ('tag({0})' -f $version)) )
{
    hg tag $version.ToString()
    hg log -rtip
}

# Create a clean clone so that our packages don't pick up any cruft.
$cloneDir = New-TempDirectory -Prefix 'Carbon'
hg clone . $cloneDir
hg update -r ('tag({0})' -f $version) -R $cloneDir

$carbonZipFileName = "Carbon-{0}.zip" -f $version
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

$nugetPackageUrl = 'http://www.nuget.org/api/v2/package/Carbon/{0}' -f $version
$publishToNuGet = -not (Test-Uri -Uri $nugetPackageUrl)

$chocolatelyPackageUrl = 'https://chocolatey.org/api/v2/package/carbon/{0}' -f $version
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
                                -Version $version `
                                -LicenseUri 'http://www.apache.org/licenses/LICENSE-2.0'

$pshdoRoot = Join-Path -Path $PSScriptRoot -ChildPath 'pshdo.com'
if( -not (Test-Path -Path $pshdoRoot -PathType Container) )
{
    hg clone https://bitbucket.org/splatteredbits/pshdo.com $pshdoRoot
}

Push-Location $pshdoRoot
try
{
    hg pull
    hg update -C

    $postsRoot = Join-Path -Path $pshdoRoot -ChildPath 'source/_posts'
    $postName = '{0:yyyy\-MM\-dd}-carbon-{1}-released.markdown' -f (Get-Date),$version
    $postPath = Join-Path -Path $postsRoot -ChildPath $postName

    if( -not (Test-Path -Path $postPath -PathType Leaf) )
    {
        if( -not (Test-Path -Path (Join-Path -Path $postsRoot -ChildPath '*carbon-2.0.0-released.markdown')) )
        {
            bundle exec rake ("new_post[Carbon {0} Released]" -f $version)
        }

        $crappyName = '*carbon-{0}-dot-{1}-{2}-released.markdown' -f $version.Major,$version.Minor,$version.Build
        $crappyName = Join-Path -Path $postsRoot -ChildPath $crappyName
        if( (Test-Path -Path $crappyName -PathType Leaf) )
        {
            Get-Item -Path $crappyName | Rename-Item -NewName $postName
        }

        if( -not (Test-Path -Path $postPath -PathType Leaf) )
        {
            Write-Error ('Post {0} not found.' -f $postName)
            return
        }
    }

    $inHeader = $false
    $pastHeader = $false
    $header = Get-Content -Path $postPath |
                    ForEach-Object {
                        if( $pastHeader )
                        {
                            return
                        }

                        $_

                        if( -not $inHeader -and $_ -eq '---' )
                        {
                            $inHeader = $true
                        }
                        elseif( $inHeader -and $_ -eq '---' )
                        {
                            $pastHeader = $true
                        }

                    }
    (@'
{0}
[Carbon](http://get-carbon.org) {1} is out. You can [download Carbon as a .ZIP archive, NuGet package, Chocolatey package, or from the PowerShell Gallery](http://get-carbon.org/about_Carbon_Installation.html). It may take a week or two for the package to show up at chocolatey.org.

{2}
'@ -f ($header -join ([Environment]::NewLine)),$version,($versionReleaseNotes -join ([Environment]::NewLine))) | Set-Content -Path $postPath
    
    bundle exec rake generate

    hg addremove

    if( hg status )
    {
        hg commit -m ('Carbon {0} Released' -f $version)
        hg log -rtip
    }

    if( hg out )
    {
        hg push
    }
}
finally
{
    Pop-Location
}