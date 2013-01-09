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

function Resolve-FullPath
{
    <#
    .SYNOPSIS
    Converts a relative path to an absolute path.
    
    .DESCRIPTION
    Unlike `Resolve-Path`, this function does not check whether the path exists.  It just converts relative paths to absolute paths.
    
    Unrooted paths (e.g. `..\..\See\I\Do\Not\Have\A\Root`) are first joined with the current directory (as returned by `Get-Location`).
    
    .EXAMPLE
    Resolve-FullPath -Path 'C:\Projects\Carbon\Test\..\Carbon\FileSystem.ps1'
    
    Returns `C:\Projects\Carbon\Carbon\FileSystem.ps1`.
    
    .EXAMPLE
    Resolve-FullPath -Path 'C:\Projects\Carbon\..\I\Do\Not\Exist'
    
    Returns `C:\Projects\I\Do\Not\Exist`.
    
    .EXAMPLE
    Resolve-FullPath -Path ..\..\Foo\..\Bar
    
    Because the `Path` isn't rooted, joins `Path` with the current directory (as returned by `Get-Location`), and returns the full path.  If the current directory is `C:\Projects\Carbon`, returns `C:\Bar`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to resolve.  Must be rooted, i.e. have a drive at the beginning.
        $Path
    )
    
    if( -not ( [System.IO.Path]::IsPathRooted($Path) ) )
    {
        $Path = Join-Path (Get-Location) $Path
    }
    return [IO.Path]::GetFullPath($Path)
}

Set-Alias -Name 'ConvertTo-FullPath' -Value 'Resolve-FullPath'
