
function Get-CPrincipal
{
    <#
    .SYNOPSIS
    INTERNAL.

    .DESCRIPTION
    INTERNAL.

    .EXAMPLE
    INTERNAL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        # The principal to search for.
        [DirectoryServices.AccountManagement.Principal]$Principal,

        [Parameter(Mandatory)]
        [scriptblock]$Filter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $principalTypeName = 'principal'
    if( $Principal -is [DirectoryServices.AccountManagement.UserPrincipal] )
    {
        $principalTypeName = 'user'
    }
    elseif( $Principal -is [DirectoryServices.AccountManagement.GroupPrincipal] )
    {
        $principalTypeName = 'group'
    }
    
    Write-Timing 'Get-CPrincipal'
    Write-Timing ('                {0}' -f $principalTypeName)

    $searcher = New-Object 'DirectoryServices.AccountManagement.PrincipalSearcher' $Principal
    try
    {
        $principals = @()

        $maxTries = 100
        $tryNum = 0
        while( $tryNum++ -lt $maxTries )
        {
            $numErrorsBefore = $Global:Error.Count
            try
            {
                Write-Timing ('                [{0,3} of {1}]  FindAll()  Begin' -f $tryNum,$maxTries)
                $principals = 
                    $searcher.FindAll() |
                    Where-Object -FilterScript $Filter
                Write-Timing ('                              FindAll()  End')
                break
            }
            catch
            {
                Write-Timing ('                              FindAll()  Failed')
                $_ | Out-String | Write-Debug 

                $lastTry = $tryNum -ge $maxTries
                if( $lastTry )
                {
                    Write-Error -Message ('We tried {0} times to read {1} information, but kept getting exceptions. We''ve given up. Here''s the last error we got: {2}.' -f $maxTries,$principalTypeName,$_) -ErrorAction $ErrorActionPreference
                    return
                }

                $numErrors = $Global:Error.Count - $numErrorsBefore
                for( $idx = 0; $idx -lt $numErrors; ++$idx )
                {
                    $Global:Error.RemoveAt(0)
                }

                Start-Sleep -Milliseconds 100
            }
        }
        return $principals
    }
    finally
    {
        $searcher.Dispose()
        Write-Timing ('Get-CPrincipal')
    }
}