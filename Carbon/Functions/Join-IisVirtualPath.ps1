
function Join-CIisVirtualPath
{
    <#
    .SYNOPSIS
    Combines a path and a child path for an IIS website, application, virtual directory into a single path.  

    .DESCRIPTION
    Removes extra slashes.  Converts backward slashes to forward slashes.  Relative portions are not removed.  Sorry.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Join-CIisVirtualPath 'SiteName' 'Virtual/Path'

    Demonstrates how to join two IIS paths together.  REturns `SiteName/Virtual/Path`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The parent path.
        $Path,

        [Parameter(Position=1)]
        [string]
        $ChildPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $ChildPath )
    {
        $Path = Join-Path -Path $Path -ChildPath $ChildPath
    }
    $Path.Replace('\', '/').Trim('/')
}

