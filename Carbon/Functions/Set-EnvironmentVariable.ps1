
function Set-CEnvironmentVariable
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
    Remove-CEnvironmentVariable

    .LINK
    http://msdn.microsoft.com/en-us/library/z8te35sa

    .EXAMPLE
    Set-CEnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForProcess
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the process scope, i.e. the variable is only accessible in the current process.
    
    .EXAMPLE
    Set-CEnvironmentVariable -Name 'MyEnvironmentVariable' -Value 'Value1' -ForComputer
    
    Creates the `MyEnvironmentVariable` with an initial value of `Value1` in the machine scope, i.e. the variable is accessible in all newly launched processes.
    
    .EXAMPLE
    Set-CEnvironmentVariable -Name 'SomeUsersEnvironmentVariable' -Value 'SomeValue' -ForUser -Credential $userCreds

    Demonstrates that you can set a user-level environment variable for another user by passing its credentials to the `Credential` parameter. Runs a separate PowerShell process as that user to set the environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The name of environment variable to add/set.
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        # The environment variable's value.
        [string]$Value,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        # Sets the environment variable for the current computer.
        [Switch]$ForComputer,

        [Parameter(ParameterSetName='ForCurrentUser')]
        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Sets the environment variable for the current user.
        [Switch]$ForUser,
        
        [Parameter(ParameterSetName='ForCurrentUser')]
        # Sets the environment variable for the current process.
        [Switch]$ForProcess,

        [Parameter(ParameterSetName='ForCurrentUser')]
        # Set the variable in the current PowerShell session's `env:` drive, too. Normally, you have to restart your session to see the variable in the `env:` drive.
        #
        # This parameter was added in Carbon 2.3.0.
        [Switch]$Force,

        [Parameter(Mandatory=$true,ParameterSetName='ForSpecificUser')]
        # Set an environment variable for a specific user.
        [pscredential]$Credential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ForSpecificUser' )
    {
        $parameters = $PSBoundParameters
        $parameters.Remove('Credential')
        $job = Start-Job -ScriptBlock {
            Import-Module -Name (Join-Path -path $using:carbonRoot -ChildPath 'Carbon.psd1' -Resolve)
            $VerbosePreference = $using:VerbosePreference
            $ErrorActionPreference = $using:ErrorActionPreference
            $DebugPreference = $using:DebugPreference
            $WhatIfPreference = $using:WhatIfPreference
            Set-CEnvironmentVariable @using:parameters
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
            
            if( $Force -or $ForProcess )
            {
                [EnvironmentVariableTarget]::Process
            }
        } | 
        Where-Object { $PSCmdlet.ShouldProcess( "$_-level environment variable '$Name'", "set") } |
        ForEach-Object { [Environment]::SetEnvironmentVariable( $Name, $Value, $_ ) }    
}

