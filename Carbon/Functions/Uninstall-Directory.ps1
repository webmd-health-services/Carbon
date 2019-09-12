
function Uninstall-CDirectory
{
    <#
    .SYNOPSIS
    Removes a directory, if it exists.

    .DESCRIPTION
    The `Uninstall-CDirectory` function removes a directory. If the directory doesn't exist, it does nothing. If the directory has any files or sub-directories, you will be prompted to confirm the deletion of the directory and all its contents. To avoid the prompt, use the `-Recurse` switch.

    `Uninstall-CDirectory` was added in Carbon 2.1.0.

    .EXAMPLE
    Uninstall-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to remove/delete a directory. In this case, the directory `C:\Projects\Carbon` will be deleted, if it exists.

    .EXAMPLE
    Uninstall-CDirectory -Path 'C:\Projects\Carbon' -Recurse

    Demonstrates how to remove/delete a directory that has items in it. In this case, the directory `C:\Projects\Carbon` *and all of its files and sub-directories* will be deleted, if the directory exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the directory to create.
        $Path,

        [Switch]
        # Delete the directory *and* everything under it.
        $Recurse
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-Path -Path $Path -PathType Container) )
    {
        Remove-Item -Path $Path -Recurse:$Recurse
    }
}
