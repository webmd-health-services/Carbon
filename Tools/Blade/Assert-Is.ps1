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

function Assert-Is
{
    <#
    .SYNOPSIS
    Asserts that an object is a specific type.

    .DESCRIPTION
    Uses PowerShell's `-is` operator to check that `InputObject` is the `ExpectedType` type.

    .EXAMPLE
    Assert-Is 'foobar' ([string])

    Demonstrates how to assert an object is of a specific type.

    .EXAMPLE
    Assert-Is 1 'double' 'Not enough decimals!'

    Demonstrates how to show a message describing why the test might fail.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The object whose type to check.
        $InputObject,

        [Parameter(Position=1)]
        [Type]
        # The expected type of the object.
        $ExpectedType,

        [Parameter(Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $InputObject -isnot $ExpectedType ) 
    {
        Fail ("Expected object to be of type '{0}' but was '{1}'. {2}" -f $ExpectedType,$InputObject.GetType(),$Message)
    }
}

