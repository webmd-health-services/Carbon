
function Remove-CEnvironmentVariable
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
    Set-CEnvironmentVariable
    
    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Remove-CEnvironmentVariable -Name 'MyEnvironmentVariable' -ForProcess
    
    Removes the `MyEnvironmentVariable` from the process scope.

    .EXAMPLE
    Remove-CEnvironmentVariable -Name 'SomeUsersVariable' -ForUser -Credential $credential

    Demonstrates that you can remove another user's user-level environment variable by passing its credentials to the `Credential` parameter. This runs a separate PowerShell process as that user to remove the variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The environment variable to remove.
        [string]$Name,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        # Removes the environment variable for the current computer.
        [Switch]$ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Removes the environment variable for the current user.
        [Switch]$ForUser,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        # Removes the environment variable for the current process.
        [Switch]$ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Remove the variable from the current PowerShell session's `env:` drive, too. Normally, you have to restart your session to no longer see the variable in the `env:` drive.
        #
        # This parameter was added in Carbon 2.3.0.
        [Switch]$Force,

        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Remove an environment variable for a specific user.
        [pscredential]$Credential
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ForSpecificUser' )
    {
        $parameters = $PSBoundParameters
        $parameters.Remove('Credential')
        $job = Start-Job -ScriptBlock {
            Import-Module -Name (Join-Path -Path $using:carbonRoot -ChildPath 'Carbon.psd1')
            $VerbosePreference = $using:VerbosePreference
            $ErrorActionPreference = $using:ErrorActionPreference
            $DebugPreference = $using:DebugPreference
            $WhatIfPreference = $using:WhatIfPreference
            Remove-CEnvironmentVariable @using:parameters
        } -Credential $Credential
        $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force -ErrorAction Ignore
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

