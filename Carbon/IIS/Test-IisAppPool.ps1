# Copyright 2012 Aaron Jensen
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

function Test-IisAppPool
{
    <# 
    .SYNOPSIS
    Checks if an app pool exists.

    .DESCRIPTION 
    Returns `True` if an app pool with `Name` exists.  `False` if it doesn't exist.

    .EXAMPLE
    Test-IisAppPool -Name Peanuts

    Returns `True` if the Peanuts app pool exists, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app pool.
        $Name
    )
    
    $appPool = Get-IisAppPool -Name $Name
    if( $appPool )
    {
        return $true
    }
    
    return $false
}

Set-Alias -Name 'Test-IisAppPoolExists' -Value 'Test-IisAppPool'