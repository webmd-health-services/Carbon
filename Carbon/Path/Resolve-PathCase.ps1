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

function Resolve-PathCase
{
    <#
    .SYNOPSIS
    Returns the real, canonical case of a path.
    
    .DESCRIPTION
    The .NET and Windows path/file system APIs respect and preserve the case of paths passed to them.  This function will return the actual case of a path on the file system, regardless of the case of the string passed in.
    
    If the path doesn't an exist, an error is written and nothing is returned.

    .EXAMPLE
    Resolve-PathCase -Path "C:\WINDOWS\SYSTEM32"
    
    Returns `C:\Windows\system32`.
    
    .EXAMPLE
    Resolve-PathCase -Path 'c:\projects\carbon' 
    
    Returns `C:\Projects\Carbon`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]
        # The path whose real, canonical case should be returned.
        [Alias('FullName')]
        $Path
    )
    
    if( -not (Test-Path -Path $Path) )
    {
        Write-Error "Path '$Path' not found."
        return
    }

    $uri = [uri]$Path
    if( $uri.IsUnc )
    {
        Write-Error ('Path ''{0}'' is a UNC path, which is not supported.' -f $Path)
        return
    }

    if( -not ([IO.Path]::IsPathRooted($Path)) )
    {
        $Path = (Resolve-Path -Path $Path).Path
    }
    
    $qualifier = '{0}\' -f (Split-Path -Qualifier -Path $Path)
    $qualifier = Get-Item -Path $qualifier | Select-Object -ExpandProperty 'Name'
    $canonicalPath = ''
    do
    {
        $parent = Split-Path -Parent -Path $Path
        $leaf = Split-Path -Leaf -Path $Path
        $canonicalLeaf = Get-ChildItem -Path $parent -Filter $leaf
        if( $canonicalPath )
        {
            $canonicalPath = Join-Path -Path $canonicalLeaf -ChildPath $canonicalPath
        }
        else
        {
            $canonicalPath = $canonicalLeaf
        }
    }
    while( $parent -ne $qualifier -and ($Path = Split-Path -Parent -Path $Path) )

    return Join-Path -Path $qualifier -ChildPath $canonicalPath
}

Set-Alias -Name 'Get-PathCanonicalCase' -Value 'Resolve-PathCase'
