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

function Test-Service
{
    <#
    .SYNOPSIS
    Tests if a service exists, without writing anything out to the error stream.
    
    .DESCRIPTION
    `Get-Service` writes an error when a service doesn't exist.  This function tests if a service exists without writing anyting to the output stream.
    
    .OUTPUTS
    System.Boolean.
    
    .LINK
    Install-Service

    .LINK
    Uninstall-Service

    .EXAMPLE
    Test-Service -Name 'Drive'
    
    Returns `true` if the `Drive` service exists.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service to test.
        $Name
    )
    
    $service = Get-Service -Name "$Name*" |
                    Where-Object { $_.Name -eq $Name }
    if( $service )
    {
        return $true
    }
    else
    {
        return $false
    }
}