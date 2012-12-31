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

function Test-PerformanceCounter
{
    <#
    .SYNOPSIS
    Tests if a performance counter exists.

    .DESCRIPTION
    Returns `True` if counter `Name` exists in category `CategoryName`.  `False` if it does not exist or the category doesn't exist.

    .EXAMPLE
    Test-PerformanceCounter -CategoryName 'ToyotaCamry' -Name 'MilesPerGallon'

    Returns `True` if the `ToyotaCamry` performance counter category has a `MilesPerGallon` counter.  `False` if the counter doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name where the performance counter exists.  Or might exist.  As the case may be.
        $CategoryName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's name.
        $Name
    )
    
    if( (Test-PerformanceCounterCategory -CategoryName $CategoryName) )
    {
        return [Diagnostics.PerformanceCounterCategory]::CounterExists( $Name, $CategoryName )
    }
    
    return $false
}
