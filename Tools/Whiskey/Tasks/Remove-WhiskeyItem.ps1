function Remove-WhiskeyItem
{
    [Whiskey.TaskAttribute('Delete', SupportsClean=$true)]
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
    
    foreach( $path in $TaskParameter['Path'] )
    {
        $path = $path | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path' -ErrorAction Ignore
        if( -not $path )
        {
            continue
        }

        foreach( $pathItem in $path )
        {
            Remove-WhiskeyFileSystemItem -Path $pathitem -ErrorAction Stop
        }
    }
}