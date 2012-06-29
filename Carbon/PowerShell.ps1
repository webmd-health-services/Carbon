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

function Complete-Jobs
{
    <#
    .SYNOPSIS
    Waits for a set of PowerShell jobs to complete, receives each job as it finishes, and returns the number of jobs that didn't complete successfully.

    .DESCRIPTION
    Job management in PowerShell is a pain.  At a minimum, you have to wait for each job to complete, then receive its output.  This function manages all that for you.  It iterates over a list/array of jobs, as each job finishes, it receives its output and removes it.  If a job is blocked or stopped it receives and removes those jobs.  When its all done, it returns the number of jobs that failed, were blocked, or stopped.

    By default, it sleeps for one second between status checks.  You can increase this interval using the `IntervalSeconds` parameter.

    This function never times out.

    .OUTPUTS
    System.Int32.

    .EXAMPLE
    Complete-Jobs -Jobs $jobs

    Sits and waits for all the jobs in `$jobs` to finish, block, or stop and returns the number that didn't succeed.  It waits one second between status checks.

    .EXAMPLE
    Complete-Jobs -Jobs $jobs -IntervalSeconds 60

    Waits for all the jobs in `$jobs` to finish, waiting 60 seconds between status checks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Management.Automation.Job[]]
        # The jobs to complete.
        $Jobs,
        
        [Parameter()]
        [int]
        # The number of seconds to sleep between job status checks.  Default is 1 second.
        $IntervalSeconds = 1
    )
    
    trap { Write-Warning "Unhandled error found: $_" }
    $numFailed = 0
    do
    {
        Start-Sleep -Seconds $IntervalSeconds
        
        $jobsStillRunning = $false
        foreach( $pendingJob in $Jobs )
        {
            $job = Get-Job $pendingJob.Id -ErrorAction SilentlyContinue
            if( -not $job )
            {
                Write-Verbose "Job with ID $($pendingJob.Id) doesn't exist."
                continue
            }
            
            try
            {
                Write-Verbose "Job $($job.Name) is in the $($job.State) state."
                
                $jobHeader = "# $($job.Name): $($job.State)"
                if( $job.State -eq 'Blocked' -or $job.State -eq 'Stopped')
                {
                    Write-Host $jobHeader

                    Write-Verbose "Stopping job $($job.Name)."
                    Stop-Job -Job $job

                    Write-Verbose "Receiving job $($job.Name)."
                    Receive-Job -Job $job -ErrorAction Continue | Write-Host

                    Write-Verbose "Removing job $($job.Name)."
                    Remove-Job -Job $job
                    $numFailed += 1
                }
                elseif( $job.State -eq 'Completed' -or $job.State -eq 'Failed' )
                {
                    Write-Host $jobHeader

                    Write-Verbose "Receiving job $($job.Name)."
                    Receive-Job -Job $job -ErrorAction Continue | Write-Host

                    Write-Verbose "Removing job $($job.Name)."
                    Remove-Job -Job $job
                    if( $job.State -eq 'Failed' )
                    {
                        $numFailed += 1
                    }
                }
                elseif( $job.State -eq 'NotStarted' -or $job.State -eq 'Running' )
                {
                    $jobsStillRunning = $true
                }
                else
                {
                    throw "Found unknown job state $($job.State)."
                }
            }
            catch
            {
                Write-Warning "Encountered error handling job $($job.Name)."
                Write-Warning $_
            }
        }
        
     } while( $jobsStillRunning )
     
     return $numFailed
}

function Get-PowershellPath
{
    <#
    .SYNOPSIS
    Gets the path to powershell.exe.

    .DESCRIPTION
    Returns the path to the powershell.exe binary for the machine's default architecture (i.e. x86 or x64).  If you're on a x64 machine and want to get the path to x86 PowerShell, set the `x86` switch.

    .EXAMPLE
    Get-PowerShellPath

    Returns the path to the version of PowerShell that matches the computer's architecture (i.e. x86 or x64).

    .EXAMPLE
    Get-PowerShellPath -x86

    Returns the path to the x86 version of PowerShell.
    #>
    [CmdletBinding()]
    param(
        [Switch]
        # Gets the path to 32-bit PowerShell.
        $x86
    )
    
    $powershellPath = Join-Path $PSHome powershell.exe
    if( $x86 -and (Test-OSIs64Bit))
    {
        return $powerShellPath -replace 'System32','SysWOW64'
    }
    return $powerShellPath
}

function Invoke-PowerShell
{
    <#
    .SYNOPSIS
    Invokes a script block in a separate powershell.exe process.
    
    .DESCRIPTION
    The invoked PowerShell process can run under the .NET 4.0 CLR (using `v4.0` as the value to the Runtime parameter) and under 32-bit PowerShell (using the `x86` switch).
    
    .EXAMPLE
    Invoke-PowerShell -Command { $PSVersionTable }
    
    Runs a separate PowerShell process, returning the $PSVersionTable from that process.
    
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
        # The CLR to use.  Must be one of v2.0 or v4.0.  Default is v2.0.
        $Runtime = 'v2.0'
    )
    
    $comPlusAppConfigEnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
    $activationConfigDir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
    $activationConfigPath = Join-Path $activationConfigDir powershell.exe.activation_config
    $originalCOMAppConfigEnvVar = [Environment]::GetEnvironmentVariable( $comPlusAppConfigEnvVarName )
    if( $Runtime -eq 'v4.0' )
    {
        $null = New-Item -Path $activationConfigDir -ItemType Directory
        @"
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <startup useLegacyV2RuntimeActivationPolicy="true">
    <supportedRuntime version="v4.0"/>
  </startup>
</configuration>
"@ | Out-File -FilePath $activationConfigPath -Encoding OEM
        Set-EnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $activationConfigDir -Scope Process
    }
    
    $params = @{ }
    if( $x86 )
    {
        $params.x86 = $true
    }
    
    try
    {
        & (Get-PowerShellPath @params) -NoProfile -NoLogo -Command $command -Args $Args
    }
    finally
    {
        if( $Runtime -eq 'v4.0' )
        {
            Remove-Item -Path $activationConfigDir -Recurse -Force
            if( $originalCOMAppConfigEnvVar )
            {
                Set-EnvironmentVariable -Name $comPlusAppConfigEnvVarName -Value $originalCOMAppConfigEnvVar -Scope Process
            }
            else
            {
                Remove-EnvironmentVariable -Name $comPlusAppConfigEnvVarName -Scope Process
            }
        }
    }
}

function Test-PowerShellIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current PowerShell process is 32-bit.

    .DESCRIPTION
    Returns `True` if the currently executing PowerShell process is 32-bit/x86, `False` if it is 64-bit/x64.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-PowerShellIs32Bit

    Returns `True` if PowerShell is 32-bit/x86, `False` if it is 64-bit/x64.
    #>
    [CmdletBinding()]
    param(
    )
    
    return ($env:PROCESSOR_ARCHITECTURE -eq 'x86')
}

function Test-PowerShellIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current powershell process is 64-bit.
    #>
    [CmdletBinding()]
    param(
    )
    
    return ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
}
