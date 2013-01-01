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

function Remove-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Removes a value from a registry key, if it exists.
    
    .DESCRIPTION
    If the given key doesn't exist, nothing happens.
    
    .EXAMPLE
    Remove-RegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'InstallPath'
    
    Removes the `InstallPath` value from the `hklm:\Software\Carbon\Test` registry key.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be removed.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value to remove.
        $Name
    )
    
    if( (Test-RegistryKeyValue -Path $Path -Name $Name) )
    {
        if( $pscmdlet.ShouldProcess( ('Item: {0} Property: {1}' -f $Path,$Name), 'Remove Property' ) )
        {
            Remove-ItemProperty -Path $Path -Name $Name
        }
    }
}
