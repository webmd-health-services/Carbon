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

function Test-ProcessIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current process is 32-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return ($env:PROCESSOR_ARCHITECTURE -eq 'x86')
}

function Test-ProcessIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current process is 64-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
}
