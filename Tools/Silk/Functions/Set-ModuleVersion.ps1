
function Set-ModuleVersion
{
    <#
    .SYNOPSIS
    Updates a module's version.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module's manifest.
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module's manifest.
        $SolutionPath,

        [Parameter(Mandatory=$true)]
        [string]
        # Path to an C# file to update with the assembly version.
        $AssemblyInfoPath,

        [Parameter(Mandatory=$true)]
        [Version]
        # The version to build.
        $Version,

        [string]
        # The pre-release version, e.g. alpha.39, rc.1, etc.
        $PreReleaseVersion,

        [string]
        # Build metadata.
        $BuildMetadata
    )

    Set-StrictMode -Version 'Latest'

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

        $moduleVersionRegex = 'ModuleVersion\s*=\s*(''|")([^''"])+(''|")' 
        $manifest = Get-Content -Raw -Path $manifestPath
        $manifest = $manifest -replace $moduleVersionRegex,('ModuleVersion = ''{0}''' -f $version)
        $manifest | Set-Content -Path $manifestPath

        $assemblyVersionRegex = 'Assembly(File|Informational)?Version\("[^"]*"\)'
        $assemblyVersion = Get-Content -Path $AssemblyInfoPath |
                                ForEach-Object {
                                    if( $_ -match $assemblyVersionRegex )
                                    {
                                        $infoVersion = ''
                                        if( $Matches[1] -eq 'Informational' )
                                        {
                                            if( $PreReleaseVersion )
                                            {
                                                $infoVersion = '-{0}' -f $PreReleaseVersion
                                            }
                                            if( $BuildMetadata )
                                            {
                                                $infoVersion = '{0}+{1}' -f $infoVersion,$BuildMetadata
                                            }
                                        }
                                        return $_ -replace $assemblyVersionRegex,('Assembly$1Version("{0}{1}")' -f $Version,$infoVersion)
                                    }
                                    $_
                                }
        $assemblyVersion | Set-Content -Path $AssemblyInfoPath
    }

    $msbuildRoot = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\12.0 -Name 'MSBuildToolsPath' | Select-Object -ExpandProperty 'MSBuildToolsPath'
    $msbuildExe = Join-Path -Path $msbuildRoot -ChildPath 'MSBuild.exe' -Resolve
    if( -not $msbuildExe )
    {
        return
    }

    & $msbuildExe /target:"clean;build" $SolutionPath /v:m /nologo
}