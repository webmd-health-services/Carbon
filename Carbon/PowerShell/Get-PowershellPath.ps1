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
    
    Here are the possible combinations of operating system, PowerShell, and desired path architectures, and the path they map to.
    
        +-----+-----+------+--------------------------------------------------------------+
        | OS  | PS  | Path | Result                                                       |
        +-----+-----+------+--------------------------------------------------------------+
        | x64 | x64 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x64 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x86 | x64  | $env:windir\sysnative\Windows PowerShell\v1.0\powershell.exe |
        | x64 | x86 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x86  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        +-----+-----+------+--------------------------------------------------------------+
    
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
    
    $psPath = $PSHOME
    if( Test-OSIs64Bit )
    {
        if( Test-PowerShellIs64Bit )
        {
            if( $x86 )
            {
                # x64 OS, x64 PS, want x86 path
                $psPath = $PSHOME -replace 'System32','SysWOW64'
            }
        }
        else
        {
            if( -not $x86 )
            {
                # x64 OS, x32 PS, want x64 path
                $psPath = $PSHome -replace 'SysWOW64','sysnative'
            }
        }
    }
    else
    {
        # x86 OS, no SysWOW64, everything is in $PSHOME
        $psPath = $PSHOME
    }
    
    Join-Path $psPath powershell.exe
}
