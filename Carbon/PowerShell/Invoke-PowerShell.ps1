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

function Invoke-PowerShell
{
    <#
    .SYNOPSIS
    Invokes a script block in a separate powershell.exe process.
    
    .DESCRIPTION
    If using PowerShell v2.0, the invoked PowerShell process can run under the .NET 4.0 CLR (using `v4.0` as the value to the Runtime parameter).

    If using PowerShell v4.0, you can *only* run the invoked PowerShell under a `v4.0` CLR.  If you supply a `v2.0` as the value to the `Runtime` parameter, and you're running PowerShell v3.0, you'll get an error.
    
    This function launches a PowerShell process that matches the architecture of the operating system.  On 64-bit operating systems, you can run under 32-bit PowerShell by specifying the `x86` switch).  If this function runs under a 32-bit version of PowerShell without the `x86` switch, you'll get an error.
    
    .EXAMPLE
    Invoke-PowerShell -Command { $PSVersionTable }
    
    Runs a separate PowerShell process which matches the architecture of the operating system, returning the $PSVersionTable from that process.  This will fail under 32-bit PowerShell on a 64-bit operating system.
    
    .EXAMPLE
    Invoke-PowerShell -Command { $PSVersionTable } -x86
    
    Runs a 32-bit PowerShell process, return the $PSVersionTable from that process.
    
    .EXAMPLE
    Invoke-PowerShell -Command { $PSVersionTable } -Runtime v4.0
    
    Runs a separate PowerShell process under the v4.0 .NET CLR, returning the $PSVersionTable from that process.  Should return a CLRVersion of `4.0`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        # The command to run.
        $Command,
        
        [object[]]
        # Any arguments to pass to the command.
        $Args,
        
        [Switch]
        # Run the x86 (32-bit) version of PowerShell.
        $x86,
        
        [string]
        [ValidateSet('v2.0','v4.0')]
        # The CLR to use.  Must be one of v2.0 or v4.0.  Default is the current PowerShell runtime.
        $Runtime
    )
    
    if( -not $x86 -and (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        Write-Error "Can't launch 64-bit PowerShell process.  Current PowerShell process is 32-bit, and 32-bit application's can't launch 64-bit processes."
        return
    }

    $currentRuntime = 'v{0}.0' -f $PSVersionTable.CLRVersion.Major

    if( -not $Runtime )
    {
        $Runtime = $currentRuntime
    }

    if( $Runtime -eq 'v2.0' -and $PSVersionTable.PSVersion -ge '3.0' )
    {
        Write-Error ('PowerShell v{0} requires at least .NET v{1}.{2}.  You can''t run this version of PowerShell with a {3} CLR.' -f `
                        $PSVersionTable.PSVersion,$PSVersionTable.CLRVersion.Major,$PSVersionTable.CLRVersion.Minor,$Runtime)
        return
    }

    $comPlusAppConfigEnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
    $activationConfigDir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
    $activationConfigPath = Join-Path $activationConfigDir powershell.exe.activation_config
    $originalCOMAppConfigEnvVar = [Environment]::GetEnvironmentVariable( $comPlusAppConfigEnvVarName )
    if( $currentRuntime -ne $Runtime )
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
        Set-EnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $activationConfigDir -ForProcess
    }
    
    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }
    
    try
    {
        $psPath = Get-PowerShellPath @params
        if( $Args -eq $null )
        {
            $Args = @()
        }
        & $psPath -NoProfile -NoLogo -Command $command -Args $Args
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
                Set-EnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $originalCOMAppConfigEnvVar -ForProcess
            }
            else
            {
                Remove-EnvironmentVariable -Name $comPlusAppConfigEnvVarName -ForProcess
            }
        }
    }
}
