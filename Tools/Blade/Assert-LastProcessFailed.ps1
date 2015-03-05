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

function Assert-LastProcessFailed
{
    <#
    .SYNOPSIS
    Asserts that the last process failed by checking PowerShell's `$LastExitCode` automatic variable.

    .DESCRIPTION
    A process fails if `$LastExitCode` is non-zero.

    .EXAMPLE
    Assert-LastProcessFailed

    Demonstrates how to assert that the last process failed.

    .EXAMPLE
    Assert-LastProcessFailed 'cmd.exe'

    Demonstrates how to show a custom message when the assertion fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        # The message to show if the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $LastExitCode -eq 0 )
    {
        Fail "Expected process to fail, but it succeeded (exit code: $LastExitCode).  $Message" 
    }
}

