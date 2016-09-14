
function Assert-ModuleVersion
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module's manifest.
        $ManifestPath,

        [string[]]
        # Path to any additional assemblies whose versions should get checked.
        $AssemblyPath,

        [string]
        # Path to a release notes file.
        $ReleaseNotesPath,

        [string]
        # The path to the module's nuspec file.
        $NuspecPath,

        [string[]]
        # A list of assembly file names that should be excluded from the version check. Wildcards allowed. Only assembly names are matched
        $ExcludeAssembly
    )

    Set-StrictMode -Version 'Latest'

    $errorsAtStart = $Error.Count

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $version = $manifest.Version

    Write-Verbose -Message ('Checking that {0} module is at version {1}.' -f $manifest.Name,$version)

    $badAssemblies = Invoke-Command {
                            $manifest.RequiredAssemblies | 
                                ForEach-Object { 
                                    if( -not [IO.Path]::IsPathRooted($_) )
                                    {
                                        Join-Path -Path (Split-Path -Parent -Path $manifest.Path) -ChildPath $_
                                    }
                                    else
                                    {
                                        $_
                                    }
                                }
                            if( $AssemblyPath )
                            {
                                $AssemblyPath
                            }
                        } |
                        Where-Object { 
                            foreach( $exclusion in $ExcludeAssembly )
                            {
                                if( (Split-Path -Leaf -Path $_) -like $exclusion )
                                {
                                    return $false
                                }
                            }
                            return $true
                        } |
                        Get-Item | 
                        Where-Object { 
                            -not ($_.VersionInfo.FileVersion.ToString().StartsWith($version.ToString())) -or -not ($_.VersionInfo.ProductVersion.ToString().StartsWith($version.ToString()))
                        } |
                        ForEach-Object {
                            ' * {0} (FileVersion: {1}; ProductVersion: {2})' -f $_.Name,$_.VersionInfo.FileVersion,$_.VersionInfo.ProductVersion
                        }
    if( $badAssemblies )
    {
        Write-Error -Message ('The following assemblies are not at version {0}.{1}{2}' -f $version,([Environment]::NewLine),($badAssemblies -join ([Environment]::NewLine)))
    }

    if( $ReleaseNotesPath )
    {
        $foundFirstVersion = $false
        $releaseNotesVersion = Get-Content -Path $ReleaseNotesPath |
                                    ForEach-Object {
                                        if( -not $foundFirstVersion -and $_ -match '^#\s+(\d+\.\d+\.\d+)' )
                                        {
                                            $foundFirstVersion = $true
                                            return [Version]$Matches[1]
                                        }
                                    }
        if( -not $releaseNotesVersion )
        {
            Write-Error -Message ('Version {0} not found in release notes ({1}).' -f $version,$ReleaseNotesPath)
        }
    }

    if( $NuspecPath )
    {
        $nuspec = [xml](Get-Content -Raw -Path $NuspecPath)
        if( $nuspec )
        {
            $nuspecVersion = [Version]($nuspec.package.metadata.version)
            if( $nuspecVersion )
            {
                if( $version -ne $nuspecVersion )
                {
                    Write-Error -Message ('Nuspec file ''{0}'' is at version {1}, but should be at version {2}..' -f $NuspecPath,$nuspecVersion,$version)
                }
            }
            else
            {
                Write-Error -Message ('Nuspec file ''{0}'' contains an invalid version.' -f $NuspecPath)
            }
        }
        else
        {
            Write-Error -Message ('Nuspec file ''{0}'' does not contain valid XML.' -f $NuspecPath)
        }
    }

    return (($Error.Count - $errorsAtStart) -eq 0)
}