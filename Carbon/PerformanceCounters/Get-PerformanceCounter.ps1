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

function Get-PerformanceCounter
{
    <#
    .SYNOPSIS
    Gets the performance counters for a category.

    .DESCRIPTION
    Returns `PerformanceCounterCategory` objects for the given category name.  If not counters exist for the category exits, an empty array is returned.

    .OUTPUTS
    System.Diagnostics.PerformanceCounterCategory.

    .EXAMPLE
    Get-PerformanceCounter -CategoryName Processor

    Gets all the `Processor` performance counters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The category's name whose performance counters will be returned.
        $CategoryName
    )
    
    if( (Test-PerformanceCounterCategory -CategoryName $CategoryName) )
    {
        $category = New-Object Diagnostics.PerformanceCounterCategory $CategoryName
        return $category.GetCounters("")
    }
}

Set-Alias -Name 'Get-PerformanceCounters' -Value 'Get-PerformanceCounter'
