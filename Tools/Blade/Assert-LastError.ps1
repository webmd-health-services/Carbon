# Copyright 2012 - 2015 Aaron Jensen
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

function Assert-LastError
{
    <#
    .SYNOPSIS
    OBSOLETE.  Use `Assert-Error` instead.

    .DESCRIPTION
    OBSOLETE.  Use `Assert-Error` instead.

    .EXAMPLE
    Assert-Error -Last 'not found'

    Demonstrates how to use `Assert-Error` instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The expected error message for the last error.
        $ExpectedError, 

        [Parameter(Position=1)]
        [string]
        # A custom message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Warning 'OBSOLETE.  Use `Assert-Error -Last` instead.'

    Assert-Error -Last -Regex $ExpectedError
}
Set-Alias -Name 'Assert-LastPipelineError' -Value 'Assert-LastError'
