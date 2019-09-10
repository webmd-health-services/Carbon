
function Install-CDirectory
{
    <#
    .SYNOPSIS
    Creates a directory, if it doesn't exist.

    .DESCRIPTION
    The `Install-CDirectory` function creates a directory. If the directory already exists, it does nothing. If any parent directories don't exist, they are created, too.

    `Install-CDirectory` was added in Carbon 2.1.0.

    .EXAMPLE
    Install-CDirectory -Path 'C:\Projects\Carbon'

    Demonstrates how to use create a directory. In this case, the directories `C:\Projects` and `C:\Projects\Carbon` will be created if they don't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the directory to create.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        New-Item -Path $Path -ItemType 'Directory' | Out-String | Write-Verbose
    }
}
