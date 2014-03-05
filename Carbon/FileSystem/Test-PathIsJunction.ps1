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

function Test-PathIsJunction
{
    <#
    .SYNOPSIS
    Tests if a path is a junction.
    
    .DESCRIPTION
    Tests if path is the path to a junction.  If `Path` doesn't exist, returns false.
    
    The alternate way of doing this is to use the `IsJunction` extension method on `DirectoryInfo` objects, which are returned by the `Get-Item` and `Get-ChildItem` cmdlets.
    
    .EXAMPLE
    Test-PathIsJunction -Path C:\I\Am\A\Junction
    
    Returns `True`.
    
    .EXAMPLE
    Test-PathIsJunction -Path C:\I\Am\Not\A\Junction
    
    Returns `False`.
    
    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer -and $_.IsJunction }
    
    Demonstrates an alternative way of testing for junctions.  Uses Carbon's `IsJunction` extension method on the `DirectoryInfo` type to check if any directories under the current directory are junctions.
    #>
    param(
        [string]
        # The path to check
        $Path
    )
    
    if( Test-Path $Path -PathType Container )
    {
        return (Get-Item $Path -Force).IsJunction
    }
    return $false
}
