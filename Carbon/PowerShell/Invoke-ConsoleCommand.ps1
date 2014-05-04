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

function Invoke-ConsoleCommand
{
    <#
    .SYNOPSIS
    INTERNAL.

    .DESCRIPTION
    INTERNAL.

    .EXAMPLE
    INTERNAL.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the action.
        $Target,

        [Parameter(Mandatory=$true)]
        [string]
        # The action/command being performed.
        $Action,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        # The command to run.
        $ScriptBlock
    )

    Set-StrictMode -Version 'Latest'

    if( -not $PSCmdlet.ShouldProcess( $Target, $Action ) )
    {
        return
    }

    $output = Invoke-Command -ScriptBlock $ScriptBlock
    if( $LASTEXITCODE )
    {
        $output = $output -join [Environment]::NewLine
        Write-Error ('Failed action ''{0}'' on target ''{1}'' (exit code {2}): {3}' -f $Action,$Target,$LASTEXITCODE,$output)
    }
    else
    {
        $output | Where-Object { $_ -ne $null } | Write-Verbose
    }
}