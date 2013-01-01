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

function Get-PowershellPath
{
    <#
    .SYNOPSIS
    Gets the path to powershell.exe.

    .DESCRIPTION
    Returns the path to the powershell.exe binary for the machine's default architecture (i.e. x86 or x64).  If you're on a x64 machine and want to get the path to x86 PowerShell, set the `x86` switch.

    .EXAMPLE
    Get-PowerShellPath

    Returns the path to the version of PowerShell that matches the computer's architecture (i.e. x86 or x64).

    .EXAMPLE
    Get-PowerShellPath -x86

    Returns the path to the x86 version of PowerShell.
    #>
    [CmdletBinding()]
    param(
        [Switch]
        # Gets the path to 32-bit PowerShell.
        $x86
    )
    
    $powershellPath = Join-Path ($PSHome -replace 'SysWOW64','System32') powershell.exe
    if( $x86 -and (Test-OsIs64Bit) )
    {
        $powerShellPath = $powerShellPath -replace 'System32','SysWow64'
    }
    
    return $powerShellPath
}
