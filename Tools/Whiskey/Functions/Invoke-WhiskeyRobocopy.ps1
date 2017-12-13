
function Invoke-WhiskeyRobocopy
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Source,

        [Parameter(Mandatory=$true)]
        [string]
        $Destination,

        [string[]]
        $WhiteList,

        [string[]]
        $Exclude
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $excludeParam = $Exclude | ForEach-Object { '/XF' ; $_ ; '/XD' ; $_ }
    robocopy $Source $Destination '/MIR' '/S' '/NP' '/R:0' '/NDL' '/NFL' '/NS' $WhiteList $excludeParam
}