
function Set-WhiskeyTaskDefaults
{
    [CmdletBinding()]
    [Whiskey.Task("TaskDefaults",SupportsClean=$true,SupportsInitialize=$true)]
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

    foreach ($taskName in $TaskParameter.Keys)
    {
        foreach ($propertyName in $TaskParameter[$taskName].Keys)
        {
            Add-WhiskeyTaskDefault -Context $TaskContext -TaskName $taskName -PropertyName $propertyname -Value $TaskParameter[$taskName][$propertyName] -Force
        }
    }
}
