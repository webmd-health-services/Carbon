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

function Test-FirewallStatefulFtp
{
    <#
    .SYNOPSIS
    Tests if the firewall's `StatefulFtp` setting is enabled.

    .DESCRIPTION
    Returns `True` if the firewall's `StatefulFtp` setting is enabled, `False` otherwise.

    If the firewall isn't configurable, writes an error and returns nothing, which will probably be interpreted by your script as `False`.  Can't help you there.  At least you'll get an error message.

    .OUTPUTS
    System.Boolean.

    .LINK
    Assert-FirewallConfigurable

    .EXAMPLE
    Test-FirewallStatefulFtp
    
    Returns `True` if the firewall's `StatefulFtp` setting is enabled, `False` otherwise.
    #>
    [CmdletBinding()]
    param()
    
    if( -not (Assert-FirewallConfigurable) )
    {
        return
    }
    
    $output = netsh advfirewall show global StatefulFtp
    $line = $output[3]
    return $line -match 'Enable'
}
