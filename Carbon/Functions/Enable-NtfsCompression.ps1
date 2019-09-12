
function Enable-CNtfsCompression
{
    <#
    .SYNOPSIS
    Turns on NTFS compression on a file/directory.

    .DESCRIPTION
    The `Enable-CNtfsCompression` function uses the `compact.exe` command to enable compression on a directory. By default, when enabling compression on a directory, only new files/directories created *after* enabling compression will be compressed.  To compress everything, use the `-Recurse` switch.

    Uses Windows' `compact.exe` command line utility to compress the file/directory.  To see the output from `compact.exe`, set the `Verbose` switch.

    Beginning in Carbon 2.9.0, `Enable-CNtfsCompression` only sets compression if it isn't already set. To *always* compress, use the `-Force` switch.

    .LINK
    Disable-CNtfsCompression

    .LINK
    Test-CNtfsCompression

    .EXAMPLE
    Enable-CNtfsCompression -Path C:\Projects\Carbon

    Turns on NTFS compression (if it isn't already turned on) and compresses the `C:\Projects\Carbon` directory, but not its sub-directories.

    .EXAMPLE
    Enable-CNtfsCompression -Path C:\Projects\Carbon -Recurse

    Turns on NTFS compression (if it isn't already turned on) and compresses the `C:\Projects\Carbon` directory and all its sub-directories.

    .EXAMPLE
    Enable-CNtfsCompression -Path C:\Projects\Carbon -Recurse -Force

    Turns on NTFS compression even if it is already on and and compresses the `C:\Projects\Carbon` directory and all its sub-directories.

    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer } | Enable-CNtfsCompression

    Demonstrates that you can pipe the path to compress into `Enable-CNtfsCompression`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        # The path where compression should be enabled.
        [string[]]$Path,

        # Enables compression on all sub-directories.
        [Switch]$Recurse,

        # Enable compression even if it is already enabled.
        [Switch]$Force
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
        
            if( -not $Force -and (Test-CNtfsCompression -Path $item) )
            {
                continue
            }

            Invoke-ConsoleCommand -Target $item -Action 'enable NTFS compression' -ScriptBlock { 
                & $compactPath /C $recurseArg $pathArg
            }
        }
    }
}
