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

function Clear-TrustedHost
{
    <#
    .SYNOPSIS
    Removes all entries from PowerShell trusted hosts list.
    
    .DESCRIPTION
    The `Add-TrustedHost` function adds new entries to the trusted hosts list.  `Set-TrustedHost` sets it to a new list.  This function clears out the trusted hosts list completely.  After you run it, you won't be able to connect to any computers until you add them to the trusted hosts list.
    
    .LINK
    Add-TrustedHost
    
    .LINK
    Set-TrustedHost

    .EXAMPLE
    Clear-TrustedHost
    
    Clears everything from the trusted hosts list.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    if( $pscmdlet.ShouldProcess( 'trusted hosts', 'clear' ) )
    {
        Write-Verbose "Clearing the trusted hosts list."
        Set-Item $TrustedHostsPath -Value '' -Force
    }

}

Set-Alias -Name 'Clear-TrustedHosts' -Value 'Clear-TrustedHost'