
function Copy-CDscResource
{
    <#
    .SYNOPSIS
    Copies DSC resources.

    .DESCRIPTION
    This function copies a DSC resource or a directory of DSC resources to a DSC pull server share/website. All files under `$Path` are copied.
    
    DSC requires all files have a checksum file (e.g. `localhost.mof.checksum`), which this function generates for you (in a temporary location).
    
    Only new files, or files whose checksums have changed, are copied. You can force all files to be copied with the `Force` switch.

    `Copy-CDscResource` is new in Carbon 2.0.

    .EXAMPLE
    Copy-CDscResource -Path 'localhost.mof' -Destination '\\dscserver\DscResources'

    Demonstrates how to copy a single resource to a resources SMB share. `localhost.mof` will only be copied if its checksum is different than what is in `\\dscserver\DscResources`.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources'

    Demonstrates how to copy a directory of resources. Only files in the directory are copied. Every file in the source must have a `.checksum` file. Only files whose checksums are different between source and destination will be copied.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources' -Recurse

    Demonstrates how to recursively copy files.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources' -Force

    Demonstrates how to copy all files, even if their `.checksum` files are the  same.

    .EXAMPLE
    Copy-CDscResource -Path 'C:\Projects\DscResources' -Destination '\\dscserver\DscResources' -PassThru

    Demonstrates how to get `System.IO.FileInfo` objects for all resources copied to the destination. If all files are up-to-date, nothing is copied, and no objects are returned.
    #>
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the DSC resource to copy. If a directory is given, all files in that directory are copied. Wildcards supported.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The directory where the resources should be copied.
        $Destination,

        [Switch]
        # Recursively copy files from the source directory.
        $Recurse,

        [Switch]
        # Returns `IO.FileInfo` objects for each item copied to `Destination`.
        $PassThru,

        [Switch]
        # Copy resources, even if they are the same on the destination server.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $tempDir = New-CTempDirectory -Prefix 'Carbon+Copy-CDscResource+'

    try
    {
        foreach( $item in (Get-ChildItem -Path $Path -Exclude '*.checksum') )
        {
            $destinationPath = Join-Path -Path $Destination -ChildPath $item.Name
            if( $item.PSIsContainer )
            {
                if( $Recurse )
                {
                    if( -not (Test-Path -Path $destinationPath -PathType Container) )
                    {
                        New-Item -Path $destinationPath -ItemType 'Directory' | Out-Null
                    }
                    Copy-CDscResource -Path $item.FullName -Destination $destinationPath -Recurse -Force:$Force -PassThru:$PassThru
                }
                continue
            }

            $sourceChecksumPath = '{0}.checksum' -f $item.Name
            $sourceChecksumPath = Join-Path -Path $tempDir -ChildPath $sourceChecksumPath
            $sourceChecksum = Get-FileHash -Path $item.FullName | Select-Object -ExpandProperty 'Hash'
            # hash files can't have any newline characters, so we can't use Set-Content
            [IO.File]::WriteAllText($sourceChecksumPath, $sourceChecksum)

            $destinationChecksum = ''

            $destinationChecksumPath = '{0}.checksum' -f $destinationPath
            if( (Test-Path -Path $destinationChecksumPath -PathType Leaf) )
            {
                $destinationChecksum = Get-Content -TotalCount 1 -Path $destinationChecksumPath
            }

            if( $Force -or -not (Test-Path -Path $destinationPath -PathType Leaf) -or ($sourceChecksum -ne $destinationChecksum) )
            {
                Copy-Item -Path $item -Destination $Destination -PassThru:$PassThru
                Copy-Item -Path $sourceChecksumPath -Destination $Destination -PassThru:$PassThru
            }
            else
            {
                Write-Verbose ('File ''{0}'' already up-to-date.' -f $destinationPath)
            }
        }
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Ignore
    }
}
