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

function Invoke-WindowsInstaller
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The installer to run.
        $Path,
        
        [Switch]
        # Runs the installer in quiet mode.
        $Quiet
    )
    
    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error "Installer '$Path' doesn't exist."
        return
    }
    
    # There is an MSI service that is continually running.  We need to wait for the installer to finish before continuing,
    # so we find the msiexec process that *isn't* the service.
    $msiServerPid = -1
    $msiServer = (Get-WmiObject Win32_Service -Filter "Name='msiserver'")
    if( $msiServer )
    {
        $msiServerPid = $msiServer.ProcessId
    }
    
    if( $pscmdlet.ShouldProcess( $Path, "install" ) )
    {
        Write-Host "Installing '$Path'."
        msiexec.exe /i $Path /quiet
        $msiProcess = Get-Process -Name msiexec -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $msiServerPid }
        if( $msiProcess )
        {
            $msiProcess.WaitForExit()
            if( $msiProcess.ExitCode -ne $null -and $msiProcess.ExitCode -ne 0 )
            {
                Write-Error "Installation failed (msiexec returned '$LastExitCode')."
            }
        }
    }
}

function Remove-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Removes an environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The environment variable to remove
        $Name,
        [Parameter(Mandatory=$true)]
        # The target where the variable should be removed.
        [EnvironmentVariableTarget]
        $Scope
    )
    
    if( $pscmdlet.ShouldProcess( "$Scope-level environment variable '$Name'", "remove" ) )
    {
        [Environment]::SetEnvironmentVariable( $Name, $null, $Scope )
    }
}

function Set-EnvironmentVariable
{
    <#
    .SYNOPSIS
    Creates or sets an environment variable.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        # The name of environment variable to add/set.
        $Name,
        
        [Parameter(Mandatory=$true)]
        # The environment variable's value.
        $Value,
        
        [Parameter(Mandatory=$true)]
        # The target where the variable should be added/set.
        [EnvironmentVariableTarget]
        $Scope
    )
    
    if( $pscmdlet.ShouldProcess( "$Scope-level environment variable '$Name'", "set") )
    {
        [Environment]::SetEnvironmentVariable( $Name, $Value, $Scope )
    }
    
}


function Test-OSIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 32-bit.
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
    #>
    [CmdletBinding()]
    param(
    )
    
    return (Test-Path env:"ProgramFiles(x86)")
}
