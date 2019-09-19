
function Uninstall-CFileShare
{
    <#
    .SYNOPSIS
    Uninstalls/removes a file share from the local computer.

    .DESCRIPTION
    The `Uninstall-CFileShare` function uses WMI to uninstall/remove a file share from the local computer, if it exists. If the file shares does not exist, no errors are written and nothing happens. The directory on the file system the share points to is not removed.

    `Uninstall-CFileShare` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Test-CFileShare

    .EXAMPLE
    Uninstall-CFileShare -Name 'CarbonShare'

    Demonstrates how to uninstall/remove a share from the local computer. If the share does not exist, `Uninstall-CFileShare` silently does nothing (i.e. it doesn't write an error).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific share to uninstall/delete. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $errors = @{
                [uint32]2 = 'Access Denied';
                [uint32]8 = 'Unknown Failure';
                [uint32]9 = 'Invalid Name';
                [uint32]10 = 'Invalid Level';
                [uint32]21 = 'Invalid Parameter';
                [uint32]22 = 'Duplicate Share';
                [uint32]23 = 'Restricted Path';
                [uint32]24 = 'Unknown Device or Directory';
                [uint32]25 = 'Net Name Not Found';
            }

    if( -not (Test-CFileShare -Name $Name) )
    {
        return
    }

    Get-CFileShare -Name $Name |
        ForEach-Object { 
            $share = $_
            $deletePhysicalPath = $false
            if( -not (Test-Path -Path $share.Path -PathType Container) )
            {
                New-Item -Path $share.Path -ItemType 'Directory' -Force | Out-String | Write-Debug
                $deletePhysicalPath = $true
            }

            if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $share.Name,$share.Path), 'delete' ) )
            {
                Write-Verbose ('Deleting file share ''{0}'' (Path: {1}).' -f $share.Name,$share.Path)
                $result = $share.Delete() 
                if( $result.ReturnValue )
                {
                    Write-Error ('Failed to delete share ''{0}'' (Path: {1}). Win32_Share.Delete() method returned error code {2} which means: {3}.' -f $Name,$share.Path,$result.ReturnValue,$errors[$result.ReturnValue])
                }
            }

            if( $deletePhysicalPath -and (Test-Path -Path $share.Path) )
            {
                Remove-Item -Path $share.Path -Force -Recurse
            }
        }
}

