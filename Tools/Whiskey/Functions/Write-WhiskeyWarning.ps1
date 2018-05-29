
function Write-WhiskeyWarning
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Warning -Message ('{0}: Build[{1}]: {2}: {3}' -f $TaskContext.ConfigurationPath,$TaskContext.TaskIndex,$TaskContext.TaskName,$Message)
}
