
function Test-CNtfsCompression
{
    <#
    .SYNOPSIS
    Tests if NTFS compression is turned on.

    .DESCRIPTION
    Returns `$true` if compression is enabled, `$false` otherwise.

    .LINK
    Disable-CNtfsCompression

    .LINK
    Enable-CNtfsCompression

    .EXAMPLE
    Test-CNtfsCompression -Path C:\Projects\Carbon

    Returns `$true` if NTFS compression is enabled on `C:\Projects\CArbon`.  If it is disabled, returns `$false`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path where compression should be enabled.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path {0} not found.' -f $Path)
        return
    }

    $attributes = Get-Item -Path $Path -Force | Select-Object -ExpandProperty Attributes
    if( $attributes )
    {
        return (($attributes -band [IO.FileAttributes]::Compressed) -eq [IO.FileAttributes]::Compressed)
    }
    return $false
}
