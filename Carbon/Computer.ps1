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

function Remove-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Removes an environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The environment variable to remove
        $Name,
        [Parameter(Mandatory=$true)]
        # The target where the variable should be removed.
        [EnvironmentVariableTarget]
        $Scope
    )
    
    if( $pscmdlet.ShouldProcess( "$Scope-level environment variable '$Name'", "remove" ) )
    {
        [Environment]::SetEnvironmentVariable( $Name, $null, $Scope )
    }
}

function Set-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Creates or sets an environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The name of environment variable to add/set.
        $Name,
        
        [Parameter(Mandatory=$true)]
        # The environment variable's value.
        $Value,
        
        [Parameter(Mandatory=$true)]
        # The target where the variable should be added/set.
        [EnvironmentVariableTarget]
        $Scope
    )
    
    if( $pscmdlet.ShouldProcess( "$Scope-level environment variable '$Name'", "set") )
    {
        [Environment]::SetEnvironmentVariable( $Name, $Value, $Scope )
    }
    
}


function Test-OSIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 32-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return -not (Test-OSIs64Bit)
}

function Test-OSIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 64-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return (Test-Path env:"ProgramFiles(x86)")
}
