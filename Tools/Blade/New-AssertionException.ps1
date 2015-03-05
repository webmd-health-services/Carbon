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

function New-AssertionException
{
    <#
    .SYNOPSIS
    Creates and throws a `Blade.AssertionException`, which fails a test.

    .DESCRIPTION
    All failed assertions call this function to report the failure.  This is Blade's `Fail` function.

    ALIASES
       
     * Fail
    #>
    param(
        [Parameter(Position=0)]
        [string]
        # The failure message.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    $scopeNum = 0
    $stackTrace = @()
    
    foreach( $item in (Get-PSCallStack) )
    {
        $invocationInfo = $item.InvocationInfo
        $stackTrace +=  "$($item.ScriptName):$($item.ScriptLineNumber) $($invocationInfo.MyCommand)"
    }

    $ex = New-Object 'Blade.AssertionException' $message,$stackTrace
    throw $ex
}

Set-Alias -Name 'Fail' -Value 'New-AssertionException'
