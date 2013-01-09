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
    
    if( -not (Test-Path $Path) )
    {
        Write-Error "Path '$Path' doesn't exist."
        return
    }
    
    $shortBuffer = New-Object Text.StringBuilder ($Path.Length * 2)
    [void] [Carbon.Win32]::GetShortPathName( $Path, $shortBuffer, $shortBuffer.Capacity )
    
    $longBuffer = New-Object Text.StringBuilder ($Path.Length * 2)
    [void] [Carbon.Win32]::GetLongPathName( $shortBuffer.ToString(), $longBuffer, $longBuffer.Capacity )
    
    return $longBuffer.ToString()
}

Set-Alias -Name 'Get-PathCanonicalCase' -Value 'Resolve-PathCase'
