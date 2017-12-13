
function Invoke-WhiskeyNuGetPush
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        $Uri,

        [Parameter(Mandatory=$true)]
        [string]
        $ApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $NuGetPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    & $NuGetPath push $Path -Source $Uri -ApiKey $ApiKey

}