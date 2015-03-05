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

function Assert-Null
{
    <#
    .SYNOPSIS
    Asserts that an object/value is `$null`.

    .DESCRIPTION
    `Value` is literally compared with `$null`.

    .EXAMPLE
    Assert-Null $null

    Demonstrates how to assert a value is equal to `$null`.

    .EXAMPLE
    Assert-Null '' 'Uh-oh.  Empty string is null.'

    Demonstrates how to assert a value is equal to `$null` and show a custom error message.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The value to check.
        $Value, 

        [Parameter(Position=1)]
        [string]
        # The message to show when `Value` if not null.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $Value -ne $null )
    {
        Fail "Value '$Value' is not null: $Message"
    }
}

Set-Alias -Name 'Assert-IsNull' -Value 'Assert-Null'
