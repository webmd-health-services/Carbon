
function Write-WhiskeyTiming
{
    [CmdletBinding()]
    param(
        $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $now = Get-Date
    Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $buildStartedAt),$Message)
}