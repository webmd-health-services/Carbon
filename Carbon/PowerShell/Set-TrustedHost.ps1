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

function Set-TrustedHost
{
    <#
    .SYNOPSIS
    Sets the current computer's trusted hosts list.

    .DESCRIPTION
    Clears the current trusted hosts list, and sets it to contain only the entries given by the `Entries` parameter.
    
    To clear the trusted hosts list, use `Clear-TrustedHost`.
    
    .LINK
    Clear-TrustedHost

    .EXAMPLE
    Set-TrustedHost -Entry example.com,api.example.com,docs.example.com

    Sets the trusted hosts list to contain just the values `example.com`, `api.example.com`, and `docs.example.com`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # An array of trusted host entries.
		[Alias("Entries")]
        $Entry
    )
    
    $value = $Entry -join ','
    if( $pscmdlet.ShouldProcess( 'trusted hosts', 'set' ) )
    {
        Set-Item $TrustedHostsPath -Value $Value -Force
    }
}

Set-Alias -Name 'Set-TrustedHosts' -Value 'Set-TrustedHost'
