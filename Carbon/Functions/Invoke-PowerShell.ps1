
function Invoke-CPowerShell
{
    <#
    .SYNOPSIS
    Invokes a script block, script, command, or encoded command under a new `powershell.exe` process.
    
    .DESCRIPTION

    The `Invoke-CPowerShell` scripts executes `powershell.exe`. All processes are started with powershell.exe's `-NoProfile` paramter. You can specify values for powershell.exe's `OutputFormat`, `ExecutionPolicy`, and `NonInteractive` paramters via parameters of the same name on the `Invoke-CPowerShell` function. Use the `Runtime` parameter to run `powershell.exe` version 2.
    
    To run a script, pass the path to the script with the `-FilePath` paramter. Pass any script arguments with the `ArgumentList` parameter. You must escape any parameters. They are passed to `powershell.exe` as-is.
    
    To run a script block, pass the script block with the `-ScriptBlock` parameter. Pass any script block arguments with the `ArgumentList` parameter. You must escape any parameters. They are passed to `powershell.exe` as-is.
    
    To run a command (Carbon 2.3.0 and later only), pass the command (i.e. string of PowerShell code) with the `Command` parameter. Any arguments to your command must be in the command itself. You must do any escaping.
    
    To run an encoded command (Carbon 2.3.0 and later only), pass the command (i.e. string of PowerShell code) with the `Command` parameter and the `-Encode` switch. `Invoke-CPowerShell` will base-64 encode your command for you and pass it to `powershell.exe` with its `-EncodedCommand` parameter.
    
    Beginning in Carbon 2.3.0, you can run scripts, commands, and encoded commands as another user. Pass that user's credentials with the `Credential` parameter.
    
    On 64-bit operating systems, use the `-x86` switch to run the new `powershell.exe` process under 32-bit PowerShell. If this switch is ommitted, `powershell.exe` will be run under a 64-bit PowerShell process (even if called from a 32-bit process). On 32-bit operating systems, this switch is ignored.
    
    The `Runtime` paramter controls what version of the .NET framework `powershell.exe` should use. Pass `v2.0` and `v4.0` to run under .NET versions 2.0 or 4.0, respectivey. Those frameworks must be installed. When running under PowerShell 2, `Invoke-CPowerShell` uses a temporary [activation configuration file](https://msdn.microsoft.com/en-us/library/ff361644(v=vs.100).aspx) to force PowerShell 2 to use .NET 4. When run under PowerShell 3 and later, `powershell.exe` is run with the `-Version` switch set to `2.0` to run `powershell.exe` under .NET 2.

    If using PowerShell v3.0 or later with a version of Carbon before 2.0, you can *only* run script blocks under a `v4.0` CLR.  PowerShell converts script blocks to an encoded command, and when running encoded commands, PowerShell doesn't allow the `-Version` parameter for running PowerShell under a different version.  To run code under a .NET 2.0 CLR from PowerShell 3, use the `FilePath` parameter to run a specfic script.
    
    .EXAMPLE
    Invoke-CPowerShell -ScriptBlock { $PSVersionTable }
    
    Runs a separate PowerShell process which matches the architecture of the operating system, returning the $PSVersionTable from that process.  This will fail under 32-bit PowerShell on a 64-bit operating system.
    
    .EXAMPLE
    Invoke-CPowerShell -ScriptBlock { $PSVersionTable } -x86
    
    Runs a 32-bit PowerShell process, return the $PSVersionTable from that process.
    
    .EXAMPLE
    Invoke-CPowerShell -ScriptBlock { $PSVersionTable } -Runtime v4.0
    
    Runs a separate PowerShell process under the v4.0 .NET CLR, returning the $PSVersionTable from that process.  Should return a CLRVersion of `4.0`.
    
    .EXAMPLE
    Invoke-CPowerShell -FilePath C:\Projects\Carbon\bin\Set-CDotNetConnectionString.ps1 -ArgumentList '-Name','myConn','-Value',"'data source=.\DevDB;Integrated Security=SSPI;'"
    
    Runs the `Set-CDotNetConnectionString.ps1` script with `ArgumentList` as arguments/parameters.
    
    Note that you have to double-quote any arguments with spaces.  Otherwise, the argument gets interpreted as multiple arguments.

    .EXAMPLE
    Invoke-CPowerShell -FilePath Get-PsVersionTable.ps1 -x86 -ExecutionPolicy RemoteSigned

    Shows how to run powershell.exe with a custom executin policy, in case the running of scripts is disabled.

    .EXAMPLE
    Invoke-CPowerShell -FilePath Get-PsVersionTable.ps1 -Credential $cred

    Demonstrates that you can run PowerShell scripts as a specific user with the `Credential` parameter.

    .EXAMPLE
    Invoke-CPowerShell -FilePath Get-PsVersionTable.ps1 -Credential $cred

    Demonstrates that you can run PowerShell scripts as a specific user with the `Credential` parameter.

    .EXAMPLE 
    Invoke-CPowerShell -Command '$PSVersionTable'
    
    Demonstrates how to run a PowerShell command contained in a string. You are responsible for quoting things correctly.

    .EXAMPLE
    Invoke-CPowerShell -Command '$PSVersionTable' -Encode

    Demonstrates how to run a base-64 encode then run PowerShell command contained in a string. This runs the command using PowerShell's `-EncodedCommand` parameter. `Invoke-CPowerShell` does the base-64 encoding for you.

    .EXAMPLE
    Invoke-CPowerShell -Command '$env:USERNAME' -Credential $credential

    Demonstrates how to run a PowerShell command as another user. Uses `Start-Process` to launch `powershell.exe` as the user. 
    #>
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock')]
        [ScriptBlock]
        # The script block to pass to `powershell.exe`.
        $ScriptBlock,
        
        [Parameter(Mandatory=$true,ParameterSetName='Command')]
        [object]
        # The command to run, as a string. Passed to PowerShell.exe as the value to the `-Command` parameter. 
        #
        # Use the `-Encode` switch to avoid complicated quoting, and have `Invoke-CPowerShell` encode this command for you and pass it to powershell.exe's `-EncodedCommand parameter.
        #
        # This parameter was introduced in Carbon 2.3.0. In previous versions, this parameter was an alias to the `ScriptBlock` parameter. To maintain backwards-compatibility, if you pass a `ScriptBlock` to this parameter, `Invoke-CPowerShell` will run the script block as a script block. In the next major version of Carbon, this parameter will stop accepting `ScriptBlock` objects.
        $Command,

        [Parameter(Mandatory=$true,ParameterSetName='FilePath')]
        [string]
        # The script to run.
        $FilePath,

        [Parameter(ParameterSetName='Command')]
        [Parameter(ParameterSetName='ScriptBlock')]
        [Parameter(ParameterSetName='FilePath')]
        [object[]]
        [Alias('Args')]
        # Any arguments to pass to the script or command. These *are not* powershell.exe arguments. They are passed to powershell.exe as-is, so you'll need to escape them.
        $ArgumentList,

        [Parameter(ParameterSetName='Command')]
        [Switch]
        # Base-64 encode the command in `Command` and run it with powershell.exe's `-EncodedCommand` switch.
        #
        # This parameter was added in Carbon 2.3.0.
        $Encode,
        
        [string]
        # Determines how output from the PowerShel command is formatted. The value of this parameter is passed as-is to `powershell.exe` with its `-OutputFormat` paramter.
        $OutputFormat,

        [Microsoft.PowerShell.ExecutionPolicy]
        # The execution policy to use when running `powershell.exe`. Passed to `powershell.exe` with its `-ExecutionPolicy` parameter.
        $ExecutionPolicy,

        [Switch]
        # Run `powershell.exe` non-interactively. This passes the `-NonInteractive` switch to powershell.exe.
        $NonInteractive,

        [Switch]
        # Run the x86 (32-bit) version of PowerShell. if not provided, the version which matches the OS architecture is used, *regardless of the architecture of the currently running process*. I.e. this command is run under a 32-bit PowerShell on a 64-bit operating system, without this switch, `Invoke-Command` will start a 64-bit `powershell.exe`.
        $x86,
        
        [string]
        [ValidateSet('v2.0','v4.0')]
        # The CLR to use.  Must be one of `v2.0` or `v4.0`.  Default is the current PowerShell runtime.
        #
        # Beginning with Carbon 2.3.0, this parameter is ignored, since Carbon 2.0 and later only supports PowerShell 4 and you can't run PowerShell 4 under .NET 2.0. 
        #
        # This parameter is OBSOLETE and will be removed in a future major version of Carbon.
        $Runtime,

        [Parameter(ParameterSetName='FilePath')]
        [Parameter(ParameterSetName='Command')]
        [pscredential]
        # Run `powershell.exe` as a specific user. Pass that user's credentials with this parameter.
        #
        # This parameter is new in Carbon 2.3.0.
        $Credential,

        [switch]$NoWarn
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Core'
    }

    $powerShellv3Installed = Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3
    $currentRuntime = 'v{0}.0' -f [Environment]::Version.Major
    if( $powerShellv3Installed )
    {
        $currentRuntime = 'v4.0'
    }

    # Check that the selected runtime is installed.
    if( $PSBoundParameters.ContainsKey('Runtime') )
    {
        $runtimeInstalled = switch( $Runtime )
        {
            'v2.0' { Test-CDotNet -V2 }
            'v4.0' { Test-CDotNet -V4 -Full }
            default { Write-Error ('Unknown runtime value ''{0}''.' -f $Runtime) }
        }

        if( -not $runtimeInstalled )
        {
            Write-Error ('.NET {0} not found.' -f $Runtime)
            return
        }
    }


    if( -not $Runtime )
    {
        $Runtime = $currentRuntime
    }

    if(  $PSCmdlet.ParameterSetName -eq 'ScriptBlock' -and `
         $Host.Name -eq 'Windows PowerShell ISE Host' -and `
         $Runtime -eq 'v2.0' -and `
         $powerShellv3Installed )
    {
        Write-Error ('The PowerShell ISE v{0} can''t run script blocks under .NET {1}. Please run from the PowerShell console, or save your script block into a file and re-run Invoke-CPowerShell using the `FilePath` parameter.' -f `
                        $PSVersionTable.PSVersion,$Runtime)
        return
    }

    $comPlusAppConfigEnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
    $activationConfigDir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
    $activationConfigPath = Join-Path $activationConfigDir powershell.exe.activation_config
    $originalCOMAppConfigEnvVar = [Environment]::GetEnvironmentVariable( $comPlusAppConfigEnvVarName )
    if( -not $powerShellv3Installed -and $currentRuntime -ne $Runtime )
    {
        $null = New-Item -Path $activationConfigDir -ItemType Directory
        @"
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <startup useLegacyV2RuntimeActivationPolicy="true">
    <supportedRuntime version="{0}" />
  </startup>
</configuration>
"@ -f $Runtime | Out-File -FilePath $activationConfigPath -Encoding OEM
        Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $activationConfigDir -ForProcess
    }
    
    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }
    
    try
    {
        $psPath = Get-CPowerShellPath @params -NoWarn
        if( $ArgumentList -eq $null )
        {
            $ArgumentList = @()
        }

        $runningAScriptBlock = $PSCmdlet.ParameterSetName -eq 'ScriptBlock' 
        if( $PSCmdlet.ParameterSetName -eq 'Command' -and $Command -is [scriptblock] )
        {
            Write-CWarningOnce -Message ('Passing a script block to the Command parameter is OBSOLETE and will be removed in a future major version of Carbon. Use the `ScriptBlock` parameter instead.')
            $ScriptBlock = $Command
            $runningAScriptBlock = $true
            if( $Credential )
            {
                Write-Error -Message ('It looks like you''re trying to run a script block as another user. `Start-Process` is used to start powershell.exe as that user. Start-Process requires all arguments to be strings. Converting a script block to a string automatically is unreliable. Please convert the script block to a command string or omit the Credential parameter.')
                return
            }
        }

        $powerShellArgs = Invoke-Command -ScriptBlock {
            if( $powerShellv3Installed -and $Runtime -eq 'v2.0' )
            {
                '-Version'
                '2.0'
            }

            # Can't run a script block in non-interactive mode. Because reasons.
            if( $NonInteractive -and -not $runningAScriptBlock )
            {
                '-NonInteractive'
            }

            '-NoProfile'

            if( $OutputFormat )
            {
                '-OutputFormat'
                $OutputFormat
            }

            if( $ExecutionPolicy -and $PSCmdlet.ParameterSetName -ne 'ScriptBlock' )
            {
                '-ExecutionPolicy'
                $ExecutionPolicy
            }
        }

        if( $runningAScriptBlock )
        {
            Write-Debug -Message ('& {0} {1} -Command {2} -Args {3}' -f $psPath,($powerShellArgs -join ' '),$ScriptBlock,($ArgumentList -join ' '))
            & $psPath $powerShellArgs -Command $ScriptBlock -Args $ArgumentList
            Write-Debug -Message ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'FilePath' )
        {
            if( $Credential )
            {
                Start-PowerShellProcess -CommandLine ('{0} -File "{1}" {2}' -f ($powerShellArgs -join " "),$FilePath,($ArgumentList -join " ")) -Credential $Credential
            }
            else
            {
                Write-Debug ('{0} {1} -File {2} {3}' -f $psPath,($powerShellArgs -join " "),$FilePath,($ArgumentList -join ' '))
                & $psPath $powerShellArgs -File $FilePath $ArgumentList
                Write-Debug ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
            }
        }
        else
        {
            if( $ArgumentList )
            {
                Write-Error -Message ('Can''t use ArgumentList parameter with Command parameter because powershell.exe''s -Command parameter doesn''t support it. Please embed the argument list in your command string, or convert your command to a script block and use the `ScriptBlock` parameter.')
                return
            }

            $argName = '-Command'
            if( $Encode )
            {
                $Command = ConvertTo-CBase64 -Value $Command -NoWarn
                $argName = '-EncodedCommand'
            }
            if( $Credential )
            {
                Start-PowerShellProcess -CommandLine ('{0} {1} {2}' -f ($powerShellArgs -join " "),$argName,$Command) -Credential $Credential
            }
            else
            {
                Write-Debug ('{0} {1} {2} {3}' -f $psPath,($powerShellArgs -join " "),$argName,$Command)
                & $psPath $powerShellArgs $argName $Command
                Write-Debug ('LASTEXITCODE: {0}' -f $LASTEXITCODE)
            }
        }
    }
    finally
    {
        if( Test-Path -Path $activationConfigDir -PathType Leaf )
        {
            Remove-Item -Path $activationConfigDir -Recurse -Force
        }

        if( Test-Path -Path env:$comPlusAppConfigEnvVarName )
        {
            if( $originalCOMAppConfigEnvVar )
            {
                Set-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $originalCOMAppConfigEnvVar -ForProcess
            }
            else
            {
                Remove-CEnvironmentVariable -Name $comPlusAppConfigEnvVarName -ForProcess
            }
        }
    }
}

