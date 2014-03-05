# Copyright 2012 - 2014 Aaron Jensen
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

function Assert-NoError
{
    <#
    .SYNOPSIS
    Tests that the `$Error` stack is empty.

    .DESCRIPTION
    I guess you could just do `Assert-Equal 0 $Error.Count`, but `Assert-NoError` is simpler.

    .EXAMPLE
    Assert-NoError

    Demonstrates how to assert that there are no errors in the `$Error` stack.

    .EXAMPLE
    Assert-NoError -Message 'cmd.exe failed to install junction!'

    Demonstrates how to show a descriptive message when there are errors in the `$Error` stack.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        # The message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $Global:Error.Count -gt 0 )
    {
        Fail "Found $($Global:Error.Count) errors, expected none. $Message" 
    }
}

Set-Alias -Name 'Assert-NoErrors' -Value 'Assert-NoError'
