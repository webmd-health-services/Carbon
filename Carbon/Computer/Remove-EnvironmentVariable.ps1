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
    
    .LINK
    Set-EnvironmentVariable
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Remove-EnvironmentVariable -Name 'MyEnvironmentVariable' -ForProcess
    
    Removes the `MyEnvironmentVariable` from the process scope.
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
