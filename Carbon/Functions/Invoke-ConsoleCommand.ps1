
function Invoke-ConsoleCommand
{
    <#
    .SYNOPSIS
    INTERNAL.

    .DESCRIPTION
    INTERNAL.

    .EXAMPLE
    INTERNAL.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the action.
        $Target,

        [Parameter(Mandatory=$true)]
        [string]
        # The action/command being performed.
        $Action,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        # The command to run.
        $ScriptBlock
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $PSCmdlet.ShouldProcess( $Target, $Action ) )
    {
        return
    }

    $output = Invoke-Command -ScriptBlock $ScriptBlock
    if( $LASTEXITCODE )
    {
        $output = $output -join [Environment]::NewLine
        Write-Error ('Failed action ''{0}'' on target ''{1}'' (exit code {2}): {3}' -f $Action,$Target,$LASTEXITCODE,$output)
    }
    else
    {
        $output | Where-Object { $_ -ne $null } | Write-Verbose
    }
}
