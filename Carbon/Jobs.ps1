
function Complete-Jobs
{
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

