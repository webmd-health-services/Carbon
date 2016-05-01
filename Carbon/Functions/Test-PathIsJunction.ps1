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
    The `Test-PathIsJunction` function tests if path is a junction (i.e. reparse point). If the path doesn't exist, returns `$false`.
    
    Carbon adds an `IsJunction` extension method on `DirectoryInfo` objects, which you can use instead e.g.
    
        Get-ChildItem -Path $env:Temp | 
            Where-Object { $_.PsIsContainer -and $_.IsJunction }

    would return all the junctions under the current user's temporary directory.

    The `LiteralPath` parameter was added in Carbon 2.2.0. Use it to check paths that contain wildcard characters.
    
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
        # The path to check. Wildcards allowed. If using wildcards, returns `$true` if all paths that match the wildcard are junctions. Otherwise, return `$false`.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        # The literal path to check. Use this parameter to test a path that contains wildcard characters.
        #
        # This parameter was added in Carbon 2.2.0.
        $LiteralPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'Path' )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Path) )
        {
            $junctions = Get-Item -Path $Path -Force |
                            Where-Object { $_.PsIsContainer -and $_.IsJunction }
            
            return ($junctions -ne $null)        
        }

        return Test-PathIsJunction -LiteralPath $Path
    }

    if( Test-Path -LiteralPath $LiteralPath -PathType Container )
    {
        return (Get-Item -LiteralPath $LiteralPath -Force).IsJunction
    }

    return $false
}

