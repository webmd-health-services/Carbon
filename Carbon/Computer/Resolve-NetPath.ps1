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

function Resolve-NetPath
{
    <#
    .SYNOPSIS
    Returns the path to Windows' `net.exe` command.
    
    .DESCRIPTION
    You can't always assume that `net.exe` is in your path.  Use this function to return the path to `net.exe` regardless of paths in your path environment variable.
    
    .EXAMPLE
    Resolve-NetPath
    
    Returns `C:\Windows\system32\net.exe`.  Usually.
    #>
    [CmdletBinding()]
    param(
    )
    
    $netCmd = Get-Command -CommandType Application -Name net.exe* |
                Where-Object { $_.Name -eq 'net.exe' }
    if( $netCmd )
    {
        return $netCmd.Definition
    }
    
    $netPath = Join-Path $env:WINDIR system32\net.exe
    if( (Test-Path -Path $netPath -PathType Leaf) )
    {
        return $netPath
    }
    
    Write-Error 'net.exe command not found.'
    return $null
}