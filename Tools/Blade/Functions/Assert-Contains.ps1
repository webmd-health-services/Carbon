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

function Assert-Contains
{
    <#
    .SYNOPSIS
    OBSOLETE. Use `Assert-That -Contains` instead.

    .DESCRIPTION
    OBSOLETE. Use `Assert-That -Contains` instead.

    .EXAMPLE
    Assert-That @( 1, 2, 3 ) -Contains 3

    Demonstrates that you should use `Assert-That` instead.

    .EXAMPLE
    Assert-That @( 1, 2 ) -Contains 3 'Three is the loneliest number.'

    Demonstrates that you should use `Assert-That` instead.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The collection to check.
        $Haystack, 

        [Parameter(Position=1)]
        [object]
        # The object to check the collection for.
        $Needle, 

        [Parameter(Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Warning ('Assert-Contains is obsolete and will be removed from a future version of Blade. Please use `Assert-That -Contains` instead.')

    if( $Haystack -notcontains $Needle )
    {
        Fail "Unable to find '$Needle'. $Message"
    }
}

