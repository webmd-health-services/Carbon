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
                    Write-Error "Found unknown job state $($job.State)."
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
