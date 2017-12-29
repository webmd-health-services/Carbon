
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

    $scope = $TaskParameter['Scope']
    if( -not $scope )
    {
        $scope = 'Process'
    }

    foreach( $name in $TaskParameter.Keys )
    {
        if( $name -eq 'Scope' )
        {
            continue
        }

        foreach( $scopeItem in $scope )
        {
            $value = $TaskParameter[$name]
            Write-Verbose -Message ('  {0}@{1} -> {2}' -f $name,$scopeItem,$value)
            [Environment]::SetEnvironmentVariable($name,$value,$scopeItem)
        }
    }
}