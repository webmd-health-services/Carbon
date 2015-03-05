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

function Assert-NotEqual
{
    <#
    .SYNOPSIS
    Asserts that two objects aren't equal.

    .DESCRIPTION
    Uses PowerShell's `-eq` operator to determine if the two objects are equal or not.

    .LINK
    Assert-Equal

    .LINK
    Assert-CEqual

    .EXAMPLE
    Assert-NotEqual 'Foo' 'Foo'

    Demonstrates how to assert that `'Foo' -eq 'Foo'`, which they are.

    .EXAMPLE
    Assert-NotEqual 'Foo' 'Bar' 'Didn''t get ''Bar'' result.'

    Demonstrates how to show a reason why a test might have failed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        # The expected value.
        $Expected, 
        
        [Parameter(Position=1)]
        # The actual value.
        $Actual, 
        
        [Parameter(Position=2)]
        # A descriptive error about why the assertion might fail.
        $Message
    )

    if( $Expected -eq $Actual )
    {
        Fail ('{0} is equal to {1}. {2}' -f $Expected,$Actual,$Message)
    }
}

