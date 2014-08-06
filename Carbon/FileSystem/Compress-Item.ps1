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

function Compress-Item
{
    <#
    .SYNOPSIS
    Compresses a file/directory using the `DotNetZip` library.

    .DESCRIPTION
    You can supply a destination file path, via the `OutFile` parameter. If the file doesn't exist, it is created. If it exists, use the `-Force` parameter to overwrite it.

    Each item added to the ZIP file will be added to the root of the file, with a name matching the original file's/directory's name. For example, if adding the file `C:\Projects\Carbon\RELEASE NOTE.txt`, it would get added to the ZIP file as `RELEASE NOTES.txt`.

    If you don't supply an output file path, one will be created in the current user's TEMP directory.

    A `System.IO.FileInfo` object is returned representing the ZIP file.

    .LINK
    https://www.nuget.org/packages/DotNetZip

    .LINK
    Expand-Item

    .EXAMPLE
    Compress-Item -Path 'C:\Projects\Carbon' -OutFile 'C:\Carbon.zip'

    Demonstrates how to create a ZIP file of the `C:\Projects\Carbon` directory.

    .EXAMPLE
    Get-ChildItem -Path 'C:\Projects\Carbon' | Where-Object { $_.PsIsContainer} | Compress-Item -OutFile 'C:\Projects\Carbon.zip'

    Demonstrates how you can pipe items to `Compress-Item` for compressing.
    #>
    [OutputType([IO.FileInfo])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [string[]]
        # The path to the files/directories to compress.
        $Path,

        [string]
        # Path to destination ZIP file. If not provided, a ZIP file will be created in the current user's TEMP directory.
        $OutFile,

        [Switch]
        # Overwrites an existing ZIP file.
        $Force
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        if( $OutFile )
        {
            $OutFile = Resolve-FullPath -Path $OutFile
            if( (Test-Path -Path $OutFile -PathType Leaf) )
            {
                if( -not $Force )
                {
                    Write-Error ('File ''{0}'' already exists. Use the `-Force` switch to overwrite.' -f $OutFile)
                    return
                }
            }
        }
        else
        {
            $OutFile = 'Carbon+Compress-Item-{0}.zip' -f ([IO.Path]::GetRandomFileName())
            $OutFile = Join-Path -Path $env:TEMP -ChildPath $OutFile
        }

        $zipFile = New-Object 'Ionic.Zip.ZipFile'

    }

    process
    {
        if( -not $zipFile )
        {
            return
        }

        $Path | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath' | ForEach-Object { 
            $zipEntryName = Split-Path -Leaf -Path $_
            if( $PSCmdlet.ShouldProcess( $_, ('compress to {0} as {1}' -f $OutFile,$zipEntryName)) )
            {
                if( Test-Path -Path $_ -PathType Container )
                {
                    [void]$zipFile.AddDirectory( $_, $zipEntryName )
                }
                else
                {
                    [void]$zipFile.AddFile( $_, '.' )
                }
            }
        }

    }

    end
    {
        if( -not $zipFile )
        {
            return
        }

        if( $PSCmdlet.ShouldProcess( $OutFile, 'saving' ) )
        {
            $zipFile.Save( $OutFile )
        }
        $zipFile.Dispose()

        Get-Item -Path $OutFile
    }
}