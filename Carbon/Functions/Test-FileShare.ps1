
function Test-CFileShare
{
    <#
    .SYNOPSIS
    Tests if a file/SMB share exists on the local computer.

    .DESCRIPTION
    The `Test-CFileShare` function uses WMI to check if a file share exists on the local computer. If the share exists, `Test-CFileShare` returns `$true`. Otherwise, it returns `$false`.

    `Test-CFileShare` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Test-CFileShare -Name 'CarbonShare'

    Demonstrates how to test of a file share exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific share to check.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name ('{0}*' -f $Name) |
                Where-Object { $_.Name -eq $Name }

    return ($share -ne $null)
}

