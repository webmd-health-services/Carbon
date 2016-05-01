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
    The `Test-PathIsJunction` function tests if path is a junction (i.e. reparse point). If `Path` or `LiteralPath` doesn't exist, returns `$false`.
    
    Carbon adds an `IsJunction` extension method on `DirectoryInfo` objects, which you can use instead e.g.
    
        Get-ChildItem -Path $env:Temp | 
            Where-Object { $_.PsIsContainer -and $_.IsJunction }

    would return all the junctions under the current user's temporary directory.
    
    .EXAMPLE
    Test-PathIsJunction -Path C:\I\Am\A\Junction
    
    Returns `$true`.
    
    .EXAMPLE
    Test-PathIsJunction -Path C:\I\Am\Not\A\Junction
    
    Returns `$false`.
    
    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer -and $_.IsJunction }
    
    Demonstrates an alternative way of testing for junctions.  Uses Carbon's `IsJunction` extension method on the `DirectoryInfo` type to check if any directories under the current directory are junctions.

    .EXAMPLE
    Test-PathIsJunction -LiteralPath 'C:\PathWithWildcards[]'

    Demonstrates how to test if a path with wildcards is a junction.
    #>
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Path',Position=0)]
        [string]
        # The path to check. Wildcards allowed.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        # The literal path to check. Wildcards not supported.
        $LiteralPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $pathParam = @{}
    if( $PSCmdlet.ParameterSetName -eq 'Path' )
    {
        $pathParam['Path'] = $Path
    }
    else
    {
        $pathParam['LiteralPath'] = $LiteralPath
    }

    if( Test-Path @pathParam -PathType Container )
    {
        return (Get-Item @pathParam -Force).IsJunction
    }
    return $false
}

