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
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to remove an environment variable from the Process, User, or Computer scopes.
    
    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running processes that use this environment variable should be restarted.
    
    .EXAMPLE
    Remove-EnvironmentVariable -Name 'MyEnvironmentVariable' -ForProcess
    
    Removes the `MyEnvironmentVariable` from the process scope.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The environment variable to remove.
        $Name,
        
        [Parameter(Mandatory=$true,ParameterSetName='ForProcess')]
        # Removes the environment variable for the current process.
        [Switch]
        $ForProcess,

        [Parameter(Mandatory=$true,ParameterSetName='ForUser')]
        # Removes the environment variable for the current user.
        [Switch]
        $ForUser,
        
        [Parameter(Mandatory=$true,ParameterSetName='ForMachine')]
        # Removes the environment variable for the current computer.
        [Switch]
        $ForComputer
    )
    
    $scope = $pscmdlet.ParameterSetName -replace '^For',''
    if( $pscmdlet.ShouldProcess( "$scope-level environment variable '$Name'", "remove" ) )
    {
        [Environment]::SetEnvironmentVariable( $Name, $null, $scope )
    }
}

function Set-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Creates or sets an environment variable.
    
    .DESCRIPTION
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to create or set an environment variable in the Process, User, or Machine scopes.
    
    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running processes that use this environment variable should be restarted.
    
    .EXAMPLE
    Set-EnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForProcess
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the process scope, i.e. the variable is only accessible in the current process.
    
    .EXAMPLE
    Set-EnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForComputer
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the machine scope, i.e. the variable is accessible in all newly launched processes.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa
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
        
        [Parameter(Mandatory=$true,ParameterSetName='ForProcess')]
        # Sets the environment variable for the current process.
        [Switch]
        $ForProcess,

        [Parameter(Mandatory=$true,ParameterSetName='ForUser')]
        # Sets the environment variable for the current user.
        [Switch]
        $ForUser,
        
        [Parameter(Mandatory=$true,ParameterSetName='ForMachine')]
        # Sets the environment variable for the current computer.
        [Switch]
        $ForComputer
    )
    
    $scope = $pscmdlet.ParameterSetName -replace '^For',''
    if( $pscmdlet.ShouldProcess( "$scope-level environment variable '$Name'", "set") )
    {
        [Environment]::SetEnvironmentVariable( $Name, $Value, $scope )
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
