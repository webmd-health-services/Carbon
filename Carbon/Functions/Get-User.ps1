
function Get-CUser
{
    <#
    .SYNOPSIS
    Gets *local* users.

    .DESCRIPTION
    `Get-CUser` gets all *local* users. Use the `UserName` parameter to get a specific user by its username.

    The objects returned by `Get-CUser` are instances of `System.DirectoryServices.AccountManagement.UserPrincipal`. These objects use external resources, which, if they are disposed of correctly, will cause memory leaks. When you're done using the objects returne by `Get-CUser`, call `Dispose()` on each one to clean up its external resources.

    `Get-CUser` is new in Carbon 2.0.

    .OUTPUTS
    System.DirectoryServices.AccountManagement.UserPrincipal.

    .LINK
    Install-CUser

    .LINK
    Test-CUser

    .LINK
    Uninstall-CUser

    .EXAMPLE
    Get-CUser

    Demonstrates how to get all local users.

    .EXAMPLE
    Get-CUser -Username LSkywalker 

    Demonstrates how to get a specific user.
    #>
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.AccountManagement.UserPrincipal])]
    param(
        [ValidateLength(1,20)]
        # The username for the user.
        [string]$UserName 
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Timing 'Get-CUser'
    
    Write-Timing ('           Creating searcher')
    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $query = New-Object 'DirectoryServices.AccountManagement.UserPrincipal' $ctx
    $searcher = New-Object 'DirectoryServices.AccountManagement.PrincipalSearcher' $query
    try
    {
        $users = @()

        $maxTries = 100
        $tryNum = 0
        while( $tryNum++ -lt $maxTries )
        {
            $numErrorsBefore = $Global:Error.Count
            $lastTry = $tryNum -ge $maxTries
            try
            {
                Write-Timing ('           [{0,3} of {1}]  FindAll()  Begin' -f $tryNum,$maxTries)
                $users = 
                    $searcher.FindAll() |
                    Where-Object {
                        if( $UserName )
                        {
                            return $_.SamAccountName -eq $UserName
                        }
                        return $true
                    }
                Write-Timing ('                         FindAll()  End')
                break
            }
            catch
            {
                Write-Timing ('                         FindAll()  Failed')
                $_ | Out-String | Write-Debug 

                if( $lastTry )
                {
                    Write-Error -Message ('We tried {0} times to read user information, but kept getting exceptions. We''ve given up. Here''s the last error we got: {1}.' -f $maxTries,$_)
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

        if( $UserName )
        {
            $usersCount = $users | Measure-Object | Select-Object -ExpandProperty 'Count'
            if( $usersCount -gt 1 )
            {
                Write-Error -Message ('Found {0} users with username "{1}".' -f $userCount,$UserName) -ErrorAction $ErrorActionPreference
            }
            if( $usersCount -eq 0 )
            {
                Write-Error -Message ('Local user "{0}" not found.' -f $Username) -ErrorAction:$ErrorActionPreference
            }
        }

        return $users
    }
    finally
    {
        $searcher.Dispose()
        $query.Dispose()
        Write-Timing ('Get-CUser')
    }
}
