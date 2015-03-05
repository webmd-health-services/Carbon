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

function Assert-DoesNotContain
{
    <#
    .SYNOPSIS
    Asserts that a collection doesn't contain an object/item.

    .DESCRIPTION
    Use's PowerShell's `-contains` operator to check that a collection is missing an object/item.

    .EXAMPLE
    Assert-DoesNotContains @( 1, 2, 3 ) 4

    Demonstrates how to assert a collection doesn't contain an item.

    .EXAMPLE
    Assert-DoesNotContain @( 1, 2, 3 ) 3 'Three is the loneliest number.'

    Demonstrates how to show your own message if the assertion fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The collection to check.
        $Haystack, 

        [Parameter(Position=1)]
        [object]
        # The object the collection shouldn't have.
        $Needle, 

        [Parameter(Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $Haystack -contains $Needle )
    {
        Fail "Found '$Needle'. $Message"
    }
}

