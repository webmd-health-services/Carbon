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

function Uninstall-PerformanceCounterCategory
{
    <#
    .SYNOPSIS
    Removes an entire performance counter category.

    .DESCRIPTION
    Removes, with extreme prejudice, the performance counter category `CategoryName`.  All its performance counters are also deleted.  If the performance counter category doesn't exist, nothing happens.  I hope you have good backups!  

    .EXAMPLE
    Uninstall-PerformanceCounterCategory -CategoryName 'ToyotaCamry'

    Removes the `ToyotaCamry` performance counter category and all its performance counters.  So sad!
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The performance counter's category name that should be deleted.
        $CategoryName
    )
    
    if( (Test-PerformanceCounterCategory -CategoryName $CategoryName) )
    {
        if( $pscmdlet.ShouldProcess( $CategoryName, 'uninstall performance counter category' ) )
        {
            [Diagnostics.PerformanceCounterCategory]::Delete( $CategoryName )
        }
    }
}
