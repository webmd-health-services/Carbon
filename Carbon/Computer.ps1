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
    
    .DESCRIPTION
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to remove an environment variable from the Process, User, or Machine scopes.
    
    The `-Scope` parameter should be a value from the [EnvironmentVariableTarget enumeration](http://msdn.microsoft.com/en-us/library/system.environmentvariabletarget.aspx), which is currently:
    
     * `Process`
     * `User`
     * `Machine`
     
    You can see the values by running:
    
         [Enum]::GetValues([EnvironmentVariableTarget])
         
    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running processes that use this environment variable should be restarted.
    
    .EXAMPLE
    Remove-EnvironmentVariable -Name 'MyEnvironmentVariable' -Scope Process
    
    Removes the `MyEnvironmentVariable` from the process scope.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.environmentvariabletarget.aspx
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The environment variable to remove.
        $Name,
        
        [Parameter(Mandatory=$true)]
        # The scope where the variable should be removed.  Should be one of Process, User, or Machine.
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
    
    .DESCRIPTION
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to create or set an environment variable in the Process, User, or Machine scopes.
    
    The `-Scope` parameter should be a value from the [EnvironmentVariableTarget enumeration](http://msdn.microsoft.com/en-us/library/system.environmentvariabletarget.aspx), which is currently:
    
     * `Process`
     * `User`
     * `Machine`
     
    You can see the values by running:
    
         [Enum]::GetValues([EnvironmentVariableTarget])
    
    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running processes that use this environment variable should be restarted.
    
    .EXAMPLE
    Set-EnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -Scope Process
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the process scope, i.e. the variable is only accessible in the current process.
    
    .EXAMPLE
    Set-EnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -Scope Machine
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the machine scope, i.e. the variable is accessible in all newly launched processes.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.environmentvariabletarget.aspx
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of environment variable to add/set.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
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
    
    .DESCRIPTION
    Regardless of the bitness of the currently running process, returns `True` if the current OS is a 32-bit OS.
    
    .EXAMPLE
    Test-OSIs32Bit
    
    Returns `True` if the current operating system is 32-bit, and `False` otherwise.
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

    .DESCRIPTION
    Regardless of the bitness of the currently running process, returns `True` if the current OS is a 64-bit OS.
    
    .EXAMPLE
    Test-OSIs64Bit
    
    Returns `True` if the current operating system is 64-bit, and `False` otherwise.
    #>
    [CmdletBinding()]
    param(
    )
    
    return (Test-Path env:"ProgramFiles(x86)")
}
