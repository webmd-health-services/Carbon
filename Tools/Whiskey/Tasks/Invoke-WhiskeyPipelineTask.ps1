 function Invoke-WhiskeyPipelineTask 
{
    <#
    .SYNOPSIS
    Runs the tasks in a Whiskey pipeline.

    .DESCRIPTION
    The `Pipeline` task runs pipelines defined in your `whiskey.yml` file. Pipelines are properties that contain a list of tasks. You are required to have a default `Build` pipeline. Other pipelines exist side-by-side with your `Build` pipeline, e.g.

        Build:
        - Pipeline:
            Name: BuildASpecificThing

        BuildASpecificThing:
        - MSBuild:
            Path: SpecificThing.sln

    In this example, the default `Build` pipeline runs the `BuildASpecificThing` pipeline. 

    Use the `Pipeline` task if you want the ability to run parts of your builds in isolation, e.g. if you have multiple applications to build, you can declare a dedicated pipeline for each. Your default build runs them all, but you can run a specific pipeline by passing that pipeline's name to the `Invoke-WhiskeyBuild` function.

    ## Properties

    * `Name`: a list of pipelines to run. Pipelines are run in the order declared.

    ## Examples

    ### Example 1

        Build:
        - Pipeline:
            Name: BuildASpecificThing

        BuildASpecificThing:
        - MSBuild:
            Path SpecificThing.sln
            
    This example declares two pipelines: `Build` and `BuildASpecificThing`. The `Build` pipeline runs the `BuildASpecificThing` pipeline.           


    ### Example 2

        Build:
        - Pipeline:
            Name: 
            - BuildASpecificThing
            - BuildAnotherThing

        BuildASpecificThing:
        - MSBuild:
            Path SpecificThing.sln
            
        BuildAnotherThing:
        - MSBuild:
            Path BuildAnotherThing.sln
            
    This example demonstrates how to run multiple pipelines with the `Pipeline` task. In this example, the `BuildASpecificTing` tasks will run, followed by the `BuildAnotherThing` tasks.
    #>
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