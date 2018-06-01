
function New-WhiskeyBuildMetadataObject
{
    [CmdletBinding()]
    [OutputType([Whiskey.BuildInfo])]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    return New-Object -TypeName 'Whiskey.BuildInfo'
}
