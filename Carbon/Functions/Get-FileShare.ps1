
function Get-CFileShare
{
    <#
    .SYNOPSIS
    Gets the file/SMB shares on the local computer.

    .DESCRIPTION
    The `Get-CFileShare` function uses WMI to get the file/SMB shares on the current/local computer. The returned objects are `Win32_Share` WMI objects.

    Use the `Name` paramter to get a specific file share by its name. If a share with the given name doesn't exist, an error is written and nothing is returned.
    
    The `Name` parameter supports wildcards. If you're using wildcards to find a share, and no shares are found, no error is written and nothing is returned.

    `Get-CFileShare` was added in Carbon 2.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa394435.aspx

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Test-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Get-CFileShare

    Demonstrates how to get all the file shares on the local computer.

    .EXAMPLE
    Get-CFileShare -Name 'Build'

    Demonstrates how to get a specific file share.

    .EXAMPLE
    Get-CFileShare -Name 'Carbon*'

    Demonstrates that you can use wildcards to find all shares that match a wildcard pattern.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $filter = '(Type = 0 or Type = 2147483648)'
    $wildcardSearch = [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
    if( $Name -and -not $wildcardSearch)
    {
        $filter = '{0} and Name = ''{1}''' -f $filter,$Name
    }

    $shares = Get-WmiObject -Class 'Win32_Share' -Filter $filter |
                    Where-Object { 
                        if( -not $wildcardSearch )
                        {
                            return $true
                        }

                        return $_.Name -like $Name
                    }
    
    if( $Name -and -not $shares -and -not $wildcardSearch )
    {
        Write-Error ('Share ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
    }

    $shares
}

