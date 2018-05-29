
function New-WhiskeyContextObject
{
    [CmdletBinding()]
    [OutputType([Whiskey.Context])]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    return New-Object -TypeName 'Whiskey.Context'
}