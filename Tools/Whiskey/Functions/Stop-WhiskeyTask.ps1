
function Stop-WhiskeyTask
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [string]
        $Message,

        [string]
        $PropertyName,

        [string]
        $PropertyDescription
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if( -not ($PropertyDescription) )
    {
        $PropertyDescription = 'Build[{0}]: {1}' -f $TaskContext.TaskIndex,$TaskContext.TaskName
    }

    if( $PropertyName )
    {
        $PropertyName = ': {0}' -f $PropertyName
    }

    if( $ErrorActionPreference -ne 'Ignore' )
    {
        throw '{0}: {1}{2}: {3}' -f $TaskContext.ConfigurationPath,$PropertyDescription,$PropertyName,$Message
    }
}
