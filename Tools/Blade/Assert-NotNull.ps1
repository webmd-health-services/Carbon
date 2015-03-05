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

function Assert-NotNull
{
    <#
    .SYNOPSIS
    Asserts that an object isn't `$null`.

    .DESCRIPTION

    .EXAMPLE
    Assert-NotNull $null

    Demonstrates how to fail a test by asserting that `$null` isn't `$null`.

    .EXAMPLE
    Assert-NotNull $object 'The foo didn''t bar!'

    Demonstrates how to give a descriptive error about why the assertion might be failing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The object to check.
        $InputObject,
        
        [Parameter(Position=1)]
        [string]
        # A reason why the assertion fails. 
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $InputObject -eq $null )
    {
        Fail ("Value is null. {0}" -f $message)
    }
}

Set-Alias -Name 'Assert-IsNotNull' -Value 'Assert-NotNull'
