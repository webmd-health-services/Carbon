
function Get-WhiskeyMSBuildConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context of the current build.
        $Context
    )

    Set-StrictMode -Version 'Latest'

    $configuration = 'Debug'
    if( $Context.ByBuildServer )
    {
        $configuration = 'Release'
    }
    return $configuration
}