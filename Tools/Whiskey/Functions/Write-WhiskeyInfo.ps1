
function Write-WhiskeyInfo
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
        $Message,

        [int]
        $Indent = 0
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $Message = '[{0}][{1}][{2}]  {3}{4}' -f $Context.PipelineName,$Context.TaskIndex,$Context.TaskName,(' ' * ($Indent * 2)),$Message
        if( $supportsWriteInformation )
        {
            Write-Information -MessageData $Message -InformationAction Continue
        }
        else
        {
            Write-Output -InputObject $Message
        }
    }
}
