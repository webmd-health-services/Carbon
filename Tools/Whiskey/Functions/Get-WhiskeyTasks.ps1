

function Get-WhiskeyTask
{
    [CmdLetBinding()]
    [OutputType([Whiskey.TaskAttribute])]
    param()

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    [Management.Automation.FunctionInfo]$functionInfo = $null;
    
    foreach( $functionInfo in (Get-Command -CommandType Function) )
    {
        $functionInfo.ScriptBlock.Attributes | 
            Where-Object { $_ -is [Whiskey.TaskAttribute] } |
            ForEach-Object {
                $_.CommandName = $functionInfo.Name
                $_
            }
    }
}