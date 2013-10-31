
function Get-PathProvider
{
    <#
    .SYNOPSIS
    Returns a path's PowerShell provider.

    .DESCRIPTION
    When you want to do something with a path that depends on its provider, use this function.  The path doesn't have to exist.

    If you pass in a relative path, it is resolved relative to the current directory.  So make sure you're in the right place.

    .OUTPUTS
    System.Management.Automation.ProviderInfo.

    .EXAMPLE
    Get-PathProvider -Path 'C:\Windows'

    Demonstrates how to get the path provider for an NTFS path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path whose provider to get.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    $pathQualifier = Split-Path -Qualifier $Path -ErrorAction SilentlyContinue
    if( -not $pathQualifier )
    {
        $Path = Join-Path -Path (Get-Location) -ChildPath $Path
        $pathQualifier = Split-Path -Qualifier $Path -ErrorAction SilentlyContinue
        if( -not $pathQualifier )
        {
            Write-Error "Qualifier for path '$Path' not found."
            return
        }
    }
    Get-PSDrive $pathQualifier.Trim(':') |
        Select-Object -ExpandProperty 'Provider'

}