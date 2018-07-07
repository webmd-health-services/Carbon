
function Invoke-WhiskeyNpmRunScript
{
    [Whiskey.Task('NpmRunScript')]
    [Whiskey.RequiresTool('Node','NodePath',VersionParameterName='NodeVersion')]
    [CmdletBinding()]
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

    $npmScripts = $TaskParameter['Script']
    if (-not $npmScripts)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''Script'' is mandatory. It should be a list of one or more npm scripts to run during your build, e.g.,

        Build:
        - NpmRunScript:
            Script:
            - build
            - test

        '
    }

    foreach ($script in $npmScripts)
    {
        Write-WhiskeyTiming -Message ('Running script ''{0}''.' -f $script)
        Invoke-WhiskeyNpmCommand -Name 'run-script' -ArgumentList $script -NodePath $TaskParameter['NodePath'] -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
        Write-WhiskeyTiming -Message ('COMPLETE')
    }
}
