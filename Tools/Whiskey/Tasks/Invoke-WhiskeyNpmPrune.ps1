
function Invoke-WhiskeyNpmPrune
{
    [Whiskey.Task('NpmPrune')]
    [Whiskey.RequiresTool('Node','NodePath',VersionParameterName='NodeVersion')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The context the task is running under.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The parameters/configuration to use to run the task.
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-WhiskeyNpmCommand -Name 'prune' -ArgumentList '--production' -NodePath $TaskParameter['NodePath'] -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
}
