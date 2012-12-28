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

function Assert-Service
{
    <#
    .SYNOPSIS
    Checks if a service exists, and writes an error if it doesn't.
    
    .DESCRIPTION
    Also returns `True` if the service exists, `False` if it doesn't.
    
    .OUTPUTS
    System.Boolean.
    
    .LINK
    Test-Service
    
    .EXAMPLE
    Assert-Service -Name 'Drivetrain'
    
    Writes an error if the `Drivetrain` service doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $Name
    )
    
    if( -not (Test-Service $Name) )
    {
        Write-Error ('Service {0} not found.' -f $Name)
        return $false
    }
    
    return $true
}
