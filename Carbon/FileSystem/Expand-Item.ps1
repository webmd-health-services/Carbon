# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Expand-Item
{
    <#
    .SYNOPSIS
    Decompresses a ZIP file to a directory using the `DotNetZip` library.

    .DESCRIPTION
    The contents of the ZIP file are extracted to a temporary directory, and that directory is returned as a `System.IO.DirectoryInfo` object. You are responsible for deleting that directory when you're finished.
    
    You can extract to a specific directory with the `OutDirectory` parameter. If the directory doesn't exist, it is created. If the directory exists, and is empty, the file is decompressed into that directory. If the directory isn't empty, use the `-Force` parameter to overwrite any files/directories which may be present.

    The directory where the files were decompressed is returned.

    .LINK
    https://www.nuget.org/packages/DotNetZip

    .LINK
    Compress-Item

    .LINK
    Test-ZipFile

    .EXAMPLE
    $unzipRoot = Expand-Item -Path 'C:\Carbon.zip' 

    Demonstrates how to unzip a file into a temporary directory. You are responsible for deleting that directory.

    .EXAMPLE
    Expand-Item -Path 'C:\Carbon.zip' -OutDirectory 'C:\Modules\Carbon'

    Demonstrates how to unzip a file into a specific directory.

    .EXAMPLE
    Expand-Item -Path 'C:\Carbon.zip' -OutDirectory 'C:\Modules\Carbon' -Force

    Demonstrates how to decompress to an existing, non-empty directory with the `-Force` parameter. Existing files are overwritten.
    #>
    [OutputType([IO.DirectoryInfo])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the files/directories to compress.
        $Path,

        [string]
        # Path to a directory where the file should be extracted.
        $OutDirectory,

        [Switch]
        # Overwrite any existing files/directories in `OutDirectory`.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty 'ProviderPath'
    if( -not $Path )
    {
        return
    }

    if( -not (Test-ZipFile -Path $Path) )
    {
        Write-Error ('File ''{0}'' is not a ZIP file.' -f $Path)
        return
    }

    if( $OutDirectory )
    {
        $OutDirectory = Resolve-FullPath -Path $OutDirectory
        if( (Test-Path -Path $OutDirectory -PathType Container) )
        {
            if( -not $Force -and (Get-ChildItem -LiteralPath $OutDirectory | Measure-Object | Select-Object -ExpandProperty Count) )
            {
                Write-Error ('Output directory ''{0}'' is not empty. Use the `-Force` switch to overwrite existing files/directories.' -f $OutDirectory)
                return
            }
        }
    }
    else
    {
        $OutDirectory = 'Carbon+Expand-Item+{0}+{1}' -f (Split-Path -Leaf -Path $Path),([IO.Path]::GetRandomFileName())
        $OutDirectory = Join-Path -Path $env:TEMP -ChildPath $OutDirectory
        $null = New-Item -Path $OutDirectory -ItemType 'Directory'
    }

    $zipFile = [Ionic.Zip.ZipFile]::Read($Path)
    try
    {
        $zipFile.ExtractAll($OutDirectory, [Ionic.Zip.ExtractExistingFileAction]::OverwriteSilently)
    }
    finally
    {
        $zipFile.Dispose()
    }

    Get-Item -Path $OutDirectory
}