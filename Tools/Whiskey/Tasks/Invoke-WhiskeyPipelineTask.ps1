 function Invoke-WhiskeyPipelineTask 
{
    [CmdletBinding()]
    [Whiskey.Task("Pipeline", SupportsClean=$true, SupportsInitialize=$true)]
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

    if( -not $TaskParameter['Name'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Name is a mandatory property, but is missing or doesn''t have a value. It should be set to a list of pipeline names you want to run as part of another pipeline, e.g.
        
    Build:
    - Pipeline:
        Name:
        - One
        - Two
        
    One:
    - TASK
    
    Two:
    - TASK
 
')
    }

    $currentPipeline = $TaskContext.PipelineName
    try
    {
        foreach( $name in $TaskParameter['Name'] )
        {
            Invoke-WhiskeyPipeline -Context $TaskContext -Name $name
        }
    }
    finally
    {
        $TaskContext.PipelineName = $currentPipeline
    }
}