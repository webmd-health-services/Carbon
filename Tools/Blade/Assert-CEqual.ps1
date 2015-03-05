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

function Assert-CEqual
{
    <#
    .SYNOPSIS
    OBSOLETE.  Use `Assert-Equal -CaseSenstive` instead.

    .DESCRIPTION
    OBSOLETE.  Use `Assert-Equal -CaseSenstive` instead.

    .EXAMPLE
    Assert-Equal 'foo' 'FOO' -CaseSensitive

    Demonstrates how to use `Assert-Equal` instead of `Assert-CEqual`.
    #>
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The expected string.
        $Expected,

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        # The actual string.
        $Actual,

        [Parameter(Mandatory=$true,Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message
    )

    Write-Warning ('Assert-CEqual is obsolete.  Use Assert-Equal with the -CaseSensitive switch instead.')
    Assert-Equal -Expected $Expected -Actual $Actual -Message $Message -CaseSensitive
}

