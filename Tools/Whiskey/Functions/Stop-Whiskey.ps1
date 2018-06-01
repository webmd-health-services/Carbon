
function Stop-Whiskey
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object
        $Context,
              
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )
              
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
              
    throw '{0}: {1}' -f $Context.ConfigurationPath,$Message
}