
function Restore-WhiskeyNuGetPackage
{
    [CmdletBinding()]
    [Whiskey.TaskAttribute("NuGetRestore")]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'

    $nuGetPath = Install-WhiskeyNuGet -DownloadRoot $TaskContext.BuildRoot -Version $TaskParameter['Version']

    foreach( $item in $path )
    {
        & $nuGetPath 'restore' $item $TaskParameter['Argument']
    }
}
