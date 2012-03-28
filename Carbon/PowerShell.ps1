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
    #>
    [CmdletBinding()]
    param(
        [Switch]
        # Gets the path to 32-bit powershell.
        $x86
    )
    
    $powershellPath = Join-Path $PSHome powershell.exe
    if( $x86 )
    {
        return $powerShellPath -replace 'System32','SysWOW64'
    }
    return $powerShellPath
}

function Invoke-PowerShell
{
    <#
    .SYNOPSIS
    Invokes a script block in a separate powershell.exe process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        # The command to run.
        $Command,
        
        [object[]]
        # Any arguments to pass to the command.
        $Args,
        
        [Switch]
        # Run the x86 (32-bit) version of PowerShell.
        $x86
    )
    
    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }
    
    & (Get-PowerShellPath @params) -NoProfile -NoLogo -Command $command -Args $Args
}
