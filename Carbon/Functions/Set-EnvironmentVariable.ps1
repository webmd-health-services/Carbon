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

    Beginning with Carbon 2.3.0, you can set an environment variable for a specific user by specifying the `-ForUser` switch and passing the user's credentials with the `-Credential` parameter. This will run a PowerShell process as that user in order to set the environment variable.

    Normally, you have to restart your PowerShell session/process to see the variable in the `env:` drive. Use the `-Force` switch to also add the variable to the `env:` drive. This functionality was added in Carbon 2.3.0.
    
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
    
    .EXAMPLE
    Set-EnvironmentVariable -Name 'SomeUsersEnvironmentVariable' -Value 'SomeValue' -ForUser -Credential $userCreds

    Demonstrates that you can set a user-level environment variable for another user by passing its credentials to the `Credential` parameter. Runs a separate PowerShell process as that user to set the environment variable.
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
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        # Sets the environment variable for the current computer.
        [Switch]
        $ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Sets the environment variable for the current user.
        [Switch]
        $ForUser,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        # Sets the environment variable for the current process.
        [Switch]
        $ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Switch]
        # Set the variable in the current PowerShell session's `env:` drive, too. Normally, you have to restart your session to see the variable in the `env:` drive.
        #
        # This parameter was added in Carbon 2.3.0.
        $Force,

        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        [pscredential]
        # Set an environment variable for a specific user.
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ForSpecificUser' )
    {
        Invoke-PowerShell -FilePath (Join-Path -Path $PSScriptRoot -ChildPath '..\bin\Set-EnvironmentVariable.ps1' -Resolve) `
                          -Credential $credential `
                          -ArgumentList ('-Name {0} -Value {1}' -f (ConvertTo-Base64 $Name),(ConvertTo-Base64 $Value)) `
                          -NonInteractive `
                          -OutputFormat 'text'
        return
    }

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
            
            if( $Force -or $ForProcess )
            {
                [EnvironmentVariableTarget]::Process
            }
        } | 
        Where-Object { $PSCmdlet.ShouldProcess( "$_-level environment variable '$Name'", "set") } |
        ForEach-Object { [Environment]::SetEnvironmentVariable( $Name, $Value, $_ ) }    
}

