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

function Assert-True
{
    <#
    .SYNOPSIS
    Asserts a condition is true.

    .DESCRIPTION
    Uses PowerShell's rules for determinig truthiness.  All values are true except:

     * `0`
     * `$false`
     * '' (i.e. `[String]::Empty`)
     * `$null`
     * `@()` (i.e. empty arrays)

    All other values are true.

    .EXAMPLE
    Assert-True $false

    Demonstrates how to fail a test.

    .EXAMPLE
    Assert-True (Invoke-SomethingThatShouldReturnSomething)

    Demonstrates how to check that a function returns a true object/value.

    .EXAMPLE
    Assert-False $true 'The fladoozle didn't dooflaple.'

    Demonstrates how to use the `Message` parameter to describe why the assertion might have failed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The object/value to test for truthiness.
        $Condition, 

        [Parameter(Position=1)]
        [string]
        # A message to show if `Condition` isn't `$true`.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( -not $condition )
    {
        Fail -Message  "Expected true but was false: $message"
    }
}

