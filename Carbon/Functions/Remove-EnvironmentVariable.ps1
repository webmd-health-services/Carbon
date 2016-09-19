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

    Normally, you have to restart your PowerShell session/process to no longer see the variable in the `env:` drive. Use the `-Force` switch to also remove the variable from the `env:` drive. This functionality was added in Carbon 2.3.0.

    Beginning with Carbon 2.3.0, you can set an environment variable for a specific user by specifying the `-ForUser` switch and passing the user's credentials with the `-Credential` parameter. This runs a separate PowerShell process as that user to remove the variable.

    Beginning in Carbon 2.3.0, you can specify multiple scopes from which to remove an environment variable. In previous versions, you could only remove from one scope.
    
    .LINK
    Carbon_EnvironmentVariable

    .LINK
    Set-EnvironmentVariable
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Remove-EnvironmentVariable -Name 'MyEnvironmentVariable' -ForProcess
    
    Removes the `MyEnvironmentVariable` from the process scope.

    .EXAMPLE
    Remove-EnvironmentVariable -Name 'SomeUsersVariable' -ForUser -Credential $credential

    Demonstrates that you can remove another user's user-level environment variable by passing its credentials to the `Credential` parameter. This runs a separate PowerShell process as that user to remove the variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The environment variable to remove.
        $Name,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        [Switch]
        # Removes the environment variable for the current computer.
        $ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        [Switch]
        # Removes the environment variable for the current user.
        $ForUser,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        [Switch]
        # Removes the environment variable for the current process.
        $ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Switch]
        # Remove the variable from the current PowerShell session's `env:` drive, too. Normally, you have to restart your session to no longer see the variable in the `env:` drive.
        #
        # This parameter was added in Carbon 2.3.0.
        $Force,

        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        [pscredential]
        # Remove an environment variable for a specific user.
        $Credential
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ForSpecificUser' )
    {
        Invoke-PowerShell -FilePath (Join-Path -Path $PSScriptRoot -ChildPath '..\bin\Remove-EnvironmentVariable.ps1' -Resolve) `
                          -Credential $credential `
                          -ArgumentList ('-Name {0}' -f (ConvertTo-Base64 $Name)) `
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

                                    if( $ForProcess )
                                    {
                                        [EnvironmentVariableTarget]::Process
                                    }
                                } |
        Where-Object { $PSCmdlet.ShouldProcess( "$_-level environment variable '$Name'", "remove" ) } |
        ForEach-Object { 
                            $scope = $_
                            [Environment]::SetEnvironmentVariable( $Name, $null, $scope )
                            if( $Force -and $scope -ne [EnvironmentVariableTarget]::Process )
                            {
                                [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
                            }
            }
}

