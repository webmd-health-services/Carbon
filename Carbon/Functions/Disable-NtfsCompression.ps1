
function Disable-CNtfsCompression
{
    <#
    .SYNOPSIS
    Turns off NTFS compression on a file/directory.

    .DESCRIPTION
    The `Disable-CNtfsCompression` function uses `compact.exe` to disable compression on a file or directory. When decompressing a directory, any compressed files/directories in that directory will remain compressed. To decompress everything under a directory, use the `-Recurse` switch.  This could take awhile.

    Beginning in Carbon 2.9.0, if compression is already disabled, nothing happens. To always disable compression, use the `-Force` switch.

    Uses Windows' `compact.exe` command line utility to compress the file/directory.  To see the output from `compact.exe`, set the `Verbose` switch.

    .LINK
    Enable-CNtfsCompression

    .LINK
    Test-CNtfsCompression

    .EXAMPLE
    Disable-CNtfsCompression -Path C:\Projects\Carbon

    Turns off NTFS compression and decompresses the `C:\Projects\Carbon` directory (if compression is enabled), but not its sub-directories/files.

    .EXAMPLE
    Disable-CNtfsCompression -Path C:\Projects\Carbon -Recurse

    Turns off NTFS compression and decompresses the `C:\Projects\Carbon` directory (if compression is enabled) and all its sub-directories/sub-files.

    .EXAMPLE
    Disable-CNtfsCompression -Path C:\Projects\Carbon -Recurse -Force

    Turns off NTFS compression and decompresses the `C:\Projects\Carbon` directory (even if compression is disabled) and all its sub-directories/sub-files.

    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer } | Disable-CNtfsCompression

    Demonstrates that you can pipe the path to compress into `Disable-CNtfsCompression`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        # The path where compression should be disabled.
        [string[]]$Path,

        # Disables compression on all sub-directories.
        [Switch]$Recurse,

        # Disable compression even it it's already disabled.
        [switch]$Force
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $compactPath = Join-Path $env:SystemRoot 'system32\compact.exe'
        if( -not (Test-Path -Path $compactPath -PathType Leaf) )
        {
            if( (Get-Command -Name 'compact.exe' -ErrorAction SilentlyContinue) )
            {
                $compactPath = 'compact.exe'
            }
            else
            {
                Write-Error ("Compact command '{0}' not found." -f $compactPath)
                return
            }
        }
    }

    process
    {
        foreach( $item in $Path )
        {
            if( -not (Test-Path -Path $item) )
            {
                Write-Error -Message ('Path {0} not found.' -f $item) -Category ObjectNotFound
                return
            }

            $recurseArg = ''
            $pathArg = $item
            if( (Test-Path -Path $item -PathType Container) )
            {
                if( $Recurse )
                {
                    $recurseArg = ('/S:{0}' -f $item)
                    $pathArg = ''
                }
            }

            if( -not $Force -and -not (Test-CNtfsCompression -Path $item) )
            {
                continue
            }

            Invoke-ConsoleCommand -Target $item -Action 'disable NTFS compression' -ScriptBlock {
                & $compactPath /U $recurseArg $pathArg
            }
        }
    }
}
