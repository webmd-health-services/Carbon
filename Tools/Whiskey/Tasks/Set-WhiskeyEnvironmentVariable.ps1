
function Set-WhiskeyEnvironmentVariable
{
    [Whiskey.Task("EnvironmentVariable")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    foreach( $name in $TaskParameter.Keys )
    {
        $value = $TaskParameter[$name]
        Write-Verbose -Message ('  {0} -> {1}' -f $name,$value)
        [Environment]::SetEnvironmentVariable($name,$value,[EnvironmentVariableTarget]::Process)
        #Set-Item -Path ('env:{0}' -f $name) -Value $value
    }
}