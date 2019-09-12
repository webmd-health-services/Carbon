
function Uninstall-CIisAppPool
{
    <#
    .SYNOPSIS
    Removes an IIS application pool.
    
    .DESCRIPTION
    If the app pool doesn't exist, nothing happens.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Uninstall-CIisAppPool -Name Batcave
    
    Removes/uninstalls the `Batcave` app pool.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app pool to remove.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name
    if( $appPool )
    {
        if( $pscmdlet.ShouldProcess( ('IIS app pool {0}' -f $Name), 'remove' ) )
        {
            $appPool.Delete()
            $appPool.CommitChanges()
        }
    }
}

