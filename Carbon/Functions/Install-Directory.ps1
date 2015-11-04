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

function Install-Directory
{
    <#
    .SYNOPSIS
    Creates a directory, if it doesn't exist.

    .DESCRIPTION
    The `Install-Directory` function creates a directory. If the directory already exists, it does nothing. If any parent directories don't exist, they are created, too.

    `Install-Directory` was added in Carbon 2.1.0.

    .EXAMPLE
    Install-Directory -Path 'C:\Projects\Carbon'

    Demonstrates how to use create a directory. In this case, the directories `C:\Projects` and `C:\Projects\Carbon` will be created if they don't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the directory to create.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        New-Item -Path $Path -ItemType 'Directory' | Out-String | Write-Verbose
    }
}