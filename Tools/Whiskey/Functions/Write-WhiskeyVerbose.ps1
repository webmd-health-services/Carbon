
function Write-WhiskeyVerbose
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The current context.
        $Context,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        # The message to write.
        $Message
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
        Write-Verbose -Message ('[{0}][{1}][{2}]  {3}' -f $Context.PipelineName,$Context.TaskIndex,$Context.TaskName,$Message)
    }
}
