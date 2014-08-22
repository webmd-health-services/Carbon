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

function Set-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Creates or sets an environment variable.
    
    .DESCRIPTION
    Uses the .NET [Environment class](http://msdn.microsoft.com/en-us/library/z8te35sa) to create or set an environment variable in the Process, User, or Machine scopes.
    
    Changes to environment variables in the User and Machine scope are not picked up by running processes.  Any running processes that use this environment variable should be restarted.
    
    .LINK
    Remove-EnvironmentVariable

    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Set-EnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForProcess
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the process scope, i.e. the variable is only accessible in the current process.
    
    .EXAMPLE
    Set-EnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForComputer
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the machine scope, i.e. the variable is accessible in all newly launched processes.
    
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
