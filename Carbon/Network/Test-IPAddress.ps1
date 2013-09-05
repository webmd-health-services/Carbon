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

function Test-IPAddress
{
    <#
    .SYNOPSIS
    Tests that an IP address is in use on the local computer.

    .DESCRIPTION
    Sometimes its useful to know if an IP address is being used on the local computer.  This function does just that.

    .LINK
    Test-IPAddress

    .EXAMPLE
    Test-IPAddress -IPAddress '10.1.2.3'

    Returns `true` if the IP address `10.1.2.3` is being used on the local computer.

    .EXAMPLE
    Test-IPAddress -IPAddress '::1'

    Demonstrates that you can use IPv6 addresses.

    .EXAMPLE
    Test-IPAddress -IPAddress ([Net.IPAddress]::Parse('10.5.6.7'))

    Demonstrates that you can use real `System.Net.IPAddress` objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        # The IP address to check.
        $IPAddress
    )

    $ip = Get-IPAddress | Where-Object { $_ -eq $IPAddress }
    if( $ip )
    {
        return $true
    }
    else
    {
        return $false
    }
}