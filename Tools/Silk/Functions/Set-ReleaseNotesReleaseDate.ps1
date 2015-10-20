
function Set-ReleaseNotesReleaseDate
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module manifest whose release notes to update.
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the release notes file.
        $ReleaseNotesPath
    )

    Set-StrictMode -Version 'Latest'

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $setHeader = $false
    $releaseNotes = Get-Content -Path $ReleaseNotesPath |
                        ForEach-Object {
                            if( $_ -match '^# {0}\s*$' -f [regex]::Escape($manifest.Version.ToString()) )
                            {
                                $setHeader = $true
                                return "# {0} ({1})" -f $manifest.Version,((Get-Date).ToString("d MMMM yyyy"))
                            }
                            return $_
                        }
    if( $setHeader )
    {
        $releaseNotes | Set-Content -Path $releaseNotesPath
    }
}
