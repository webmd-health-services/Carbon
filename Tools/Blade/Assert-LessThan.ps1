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

function Assert-LessThan
{
    <#
    .SYNOPSIS
    Asserts that an expected value is less than a given value.

    .DESCRIPTION
    Uses PowerShell's `-lt` operator to perform the check.

    .EXAMPLE
    Assert-LessThan 1 5 

    Demonstrates how check that 1 is less than 5, ie. `1 -lt 5`.

    .EXAMPLE
    Assert-LessThan 5 1 'Uh-oh. Five is less than 1!'

    Demonstrates how to include a custom message when the assertion fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The value to check.
        $ExpectedValue,

        [Parameter(Position=1)]
        [object]
        # The value to check against, i.e. the value `ExpectedValue` should be less than.
        $UpperBound, 

        [Parameter(Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( -not ($ExpectedValue -lt $UpperBound) )
    {
        Fail "$ExpectedValue is not less than $UpperBound : $Message" 
    }
}

