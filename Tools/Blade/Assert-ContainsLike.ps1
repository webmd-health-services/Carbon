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

function Assert-ContainsLike
{
    <#
    .SYNOPSIS
    Asserts that a collections contains an item, using wildcards to check.

    .DESCRIPTION
    Compares each item in a collection for a value using PowerShell's `-like` operator.

    .EXAMPLE
    Assert-ContainsLike @( 'foo', 'bar', 'baz' ) 'b*'

    Demonstrates how to check if a collection contains an item, using wildcards when doing the comparison.

    .EXAMPLE
    Assert-ContainsLike @( 'foo', 'bar' ) '*z' 'No Z!'

    Demonstrates how to supply your own message when the assertion fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The collection to check.
        $Haystack, 

        [Parameter(Position=1)]
        [object]
        # The object to check the collection for. Wildcards supported.
        $Needle, 

        [Parameter(Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    foreach( $item in $Haystack )
    {
        if( $item -like "*$Needle*" )
        {
            return
        }
    }
    Fail "Unable to find '$Needle'. $Message" 
}

