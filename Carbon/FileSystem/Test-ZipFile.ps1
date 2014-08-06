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

function Test-ZipFile
{
    <#
    .SYNOPSIS
    Tests if a file is a ZIP file.

    .DESCRIPTION
    Opens and reads the first few bytes of a `Path` with .NET's `System.IO.Compression.DeflateStream`. If the read is successful, the file is a ZIP file and `$true` is returned, otherwise `$false` is returned.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [Alias('FullName')]
        [string]
        # The path to the file to test.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    return [Ionic.Zip.ZipFile]::IsZipFile( $Path )
}