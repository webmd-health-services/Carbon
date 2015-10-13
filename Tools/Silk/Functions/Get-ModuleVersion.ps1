
function Get-ModuleVersion
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the module's manifest.
        $ManifestPath
    )

    Set-StrictMode -Version 'Latest'

}