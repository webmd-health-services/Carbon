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
    Carbon_EnvironmentVariable

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
        
        # Sets the environment variable for the current process.
        [Switch]
        $ForProcess,

        # Sets the environment variable for the current user.
        [Switch]
        $ForUser,
        
        # Sets the environment variable for the current computer.
        [Switch]
        $ForComputer
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $ForProcess -and -not $ForUser -and -not $ForComputer )
    {
        Write-Error -Message ('Environment variable target not specified. You must supply one of the ForComputer, ForUser, or ForProcess switches.')
        return
    }

    Invoke-Command -ScriptBlock {
            if( $ForComputer )
            {
                [EnvironmentVariableTarget]::Machine
            }

            if( $ForUser )
            {
                [EnvironmentVariableTarget]::User
            }
            
            if( $ForProcess )
            {
                [EnvironmentVariableTarget]::Process
            }    
        } | 
        ForEach-Object {
            $target = $_
            if( $PSCmdlet.ShouldProcess( "$target-level environment variable '$Name'", "set") )
            {
                [Environment]::SetEnvironmentVariable( $Name, $Value, $target )
            }
        }    
}
