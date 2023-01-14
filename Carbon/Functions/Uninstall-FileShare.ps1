
function Uninstall-CFileShare
{
    <#
    .SYNOPSIS
    Uninstalls/removes a file share from the local computer.

    .DESCRIPTION
    The `Uninstall-CFileShare` function uses WMI to uninstall/remove a file share from the local computer, if it exists.
    Pass the name of the share to delete to the `Name` parameter (or pipe the name or share objects to the function). If
    the file share exists, it is deleted. If it doesn't exist, nothing hapens.

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

    Demonstrates how to uninstall/remove a share from the local computer. If the share does not exist,
    `Uninstall-CFileShare` silently does nothing (i.e. it doesn't write an error).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of a specific share to uninstall/delete. Wildcards accepted. If the string contains WMI sensitive
        # characters, you'll need to escape them.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( -not (Test-CFileShare -Name $Name) )
        {
            return
        }

        foreach ($share in (Get-CFileShare -Name $Name))
        {
            $deletePhysicalPath = $false
            if (-not (Test-Path -Path $share.Path -PathType Container))
            {
                Install-CDirectory -Path $share.Path -InformationAction SilentlyContinue
                $deletePhysicalPath = $true
            }

            if( $PSCmdlet.ShouldProcess( "$($share.Name) ($($share.Path))", 'delete SMB file share' ) )
            {
                Write-Information "Deleting SMB file share ""$($share.Name)"" ($($share.Path))."
                $share | Invoke-CCimMethod -Name 'Delete'
            }

            if ($deletePhysicalPath -and (Test-Path -Path $share.Path))
            {
                Uninstall-CDirectory -Path $share.Path -Recurse -InformationAction SilentlyContinue
            }
        }
    }
}

