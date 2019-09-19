
function Uninstall-CScheduledTask
{
    <#
    .SYNOPSIS
    Uninstalls a scheduled task on the current computer.

    .DESCRIPTION
    The `Uninstall-CScheduledTask` function uses `schtasks.exe` to uninstall a scheduled task on the current computer. If the task doesn't exist, nothing happens.

    .LINK
    Get-CScheduledTask

    .LINK
    Test-CScheduledTask

    .LINK
    Install-CScheduledTask

    .EXAMPLE
    Uninstall-CScheduledTask -Name 'doc' 

    Demonstrates how to delete a scheduled task named `doc`.

    .EXAMPLE
    Uninstall-CScheduledTask -Name 'doc' -Force

    Demonstrates how to delete a scheduled task that is currently running.
    #>
    [CmdletBinding(DefaultParameterSetName='AsBuiltinPrincipal')]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to uninstall.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Name = Join-Path -Path '\' -ChildPath $Name

    $MAX_TRIES = 5
    $tryNum = 0
    do
    {
        if( -not (Test-CScheduledTask -Name $Name) )
        {
            Write-Verbose ('Scheduled task ''{0}'' not found.' -f $Name)
            return
        }

        $lastTry = (++$tryNum -ge $MAX_TRIES)
        Write-Verbose ('Deleting scheduled task ''{0}''.' -f $Name)
        $errFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Uninstall-CScheduledTask+{0}' -f ([IO.Path]::GetRandomFileName()))
        schtasks.exe /delete /tn $Name '/F' 2> $errFile | ForEach-Object { 
            if( $_ -match '\bERROR\b' )
            {
                if( $lastTry -or $err -notmatch 'The function attempted to use a name that is reserved for use by another transaction' )
                {
                    Write-Error $_
                }
            }
            elseif( $_ -match '\bWARNING\b' )
            {
                Write-Warning $_
            }
            else
            {
                Write-Verbose $_
            }
        }

        if( $LASTEXITCODE )
        {
            $err = (Get-Content -Path $errFile) -join ([Environment]::NewLine)
            if( -not $lastTry -and $err -match 'The function attempted to use a name that is reserved for use by another transaction' )
            {
                if( $Global:Error.Count -gt 0 )
                {
                    $Global:Error.RemoveAt(0)
                }
                if( $Global:Error.Count -gt 0 )
                {
                    $Global:Error.RemoveAt(0)
                }                    
                Write-Verbose ('Failed to delete scheduled task ''{0}'' (found ''The function attempted to use a name that is reserved for use by another transaction.'' error). Retrying (attempt #{1}).' -f $Name,$tryNum)
                Start-Sleep -Milliseconds 100
                continue
            }

            Write-Error $err
            break
        }
    }
    while( $true -and -not $lastTry)
}
