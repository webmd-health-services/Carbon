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

function Get-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Gets the value from a registry key.
    
    .DESCRIPTION
    PowerShell's `Get-ItemProperty` cmdlet is a pain to use.  It doesn't actually return an object representing a registry key's value, but some other weird object that requires painful gyrations to get values from. This function returns just the value of a key.
    
    .EXAMPLE
    Get-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'
    
    Returns the value of the 'hklm:\Software\Carbon\Test' key's `Title` value.  
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name
    )
    
    if( -not (Test-RegistryKeyValue -Path $Path -Name $Name) )
    {
        return $null
    }
    
    $itemProperties = Get-ItemProperty -Path $Path -Name *
    return $itemProperties.$Name
}
