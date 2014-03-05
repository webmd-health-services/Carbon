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

function Test-NtfsCompression
{
    <#
    .SYNOPSIS
    Tests if NTFS compression is turned on.

    .DESCRIPTION
    Returns `$true` if compression is enabled, `$false` otherwise.

    .LINK
    Disable-NtfsCompression

    .LINK
    Enable-NtfsCompression

    .EXAMPLE
    Test-NtfsCompression -Path C:\Projects\Carbon

    Returns `$true` if NTFS compression is enabled on `C:\Projects\CArbon`.  If it is disabled, returns `$false`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path where compression should be enabled.
        $Path
    )

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