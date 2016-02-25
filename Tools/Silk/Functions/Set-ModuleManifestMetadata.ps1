
function Set-ModuleManifestMetadata
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        # The path to the module.
        $ManifestPath,

        [string[]]
        # Tags for the module.
        $Tag,

        [string]
        # The path to the module's release notes.
        $ReleaseNotesPath
    )

    Set-StrictMode -Version 'Latest'

    $releaseNotes = Get-ModuleReleaseNotes -ManifestPath $ManifestPath -ReleaseNotesPath $ReleaseNotesPath

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $module = Import-Module -Force -Name $manifestPath -PassThru

    $foundTags = $false
    $foundReleaseNotes = $false
    $inReleaseNotes = $false
    $releaseNotesWhitespacePrefix = ''
    $moduleManifestLines = Get-Content -Path $manifestPath |
                                ForEach-Object {
                                    $line = $_

                                    if( $inReleaseNotes )
                                    {
                                        if( $line -match '^(''|")@$' )
                                        {
                                            $inReleaseNotes = $false
                                            $foundReleaseNotes = $true
                                            return '{0}ReleaseNotes = @{1}{2}{3}{2}{1}@' -f $releaseNotesWhitespacePrefix,$Matches[1],[Environment]::NewLine,$releaseNotes.Trim()
                                        }
                                        return
                                    }

                                    if( $line -match '^(\s+)ReleaseNotes\ =\ @(''|")$' )
                                    {
                                        $inReleaseNotes = $true
                                        $releaseNotesWhitespacePrefix = $Matches[1]
                                        return
                                    }

                                    if( $line -match '^(\s+)Tags\ =\ @\(' )
                                    {
                                        $foundTags = $true
                                        return '{0}Tags = @(''{1}'')' -f $Matches[1],($Tag -join ''',''')
                                    }

                                    return $_
                                }
    if( -not $foundTags )
    {
        Write-Error -Message ('PrivateData PSData hashtable missing Tags metadata. Please add `Tags = @()` to the PSData section of {0} and re-run.' -f $ManifestPath)
        return
    }

    if( -not $foundReleaseNotes )
    {
        Write-Error -Message (@"
PrivateData PSData hasthable missing ReleaseNotes metadata. Please add a `ReleaseNotes` key to the PSData hashtable whose value is an empty here string, e.g. 
    
    PrivateData = @{

        PSData = @{

            ReleaseNotes = @'
'@
        }
    }
"@)
        return
    }

    $moduleManifestLines | Set-Content -Path $ManifestPath
}