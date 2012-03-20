
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Get-Job | Stop-Job -PassThru | Remove-Job
}

function Test-ShouldCompleteJobs
{
    $job = Start-Job { Start-Sleep -Milliseconds 1 } -Name "Sleep1Millisecond"
    $numFailed = Complete-Jobs -Jobs $job
    Assert-Equal 0 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldWaitToCompleteJobs
{
    $job = Start-Job { Start-Sleep -Seconds 5 } -Name "Sleep5Seconds"
    $start = Get-Date
    $numFailed = Complete-Jobs -Jobs $job
    $end = Get-DAte
    $duration = ($end - $start).TotalSeconds
    Assert-True  (0 -lt $duration -and $duration -lt 10)
    Assert-Equal 0 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldDetectFailedJobs
{
    $job = Start-Job { throw "Blarg!" } -Name "Fails"
    $numFailed = Complete-Jobs -Jobs $job 
    Assert-Equal 1 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldDetectStoppedJobs
{
    $job = Start-Job { Start-Sleep -Seconds 5 } -Name "Sleeps5Seconds"
    $job | Stop-Job
    $numFailed = Complete-Jobs -Jobs $job
    Assert-Equal 1 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldStopMultipleJobs
{
    $job1 = Start-Job { Start-Sleep -Seconds 2 } -Name "Sleeps2Seconds"
    $job2 = Start-Job { Start-Sleep -Seconds 1 } -Name "Sleeps1Second"
    $numFailed = Complete-Jobs -Jobs $job1,$job2
    Assert-Equal 0 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldOnlyCompletePassedJobs
{
    $job1 = Start-Job { Start-Sleep -Seconds 1 } -Name "Sleeps1Second"
    $job2 = Start-Job { Start-Sleep -Seconds 1 } -Name "Sleeps1Second2"
    $numFailed = Complete-Jobs -Jobs $job1
    Assert-NotNull (Get-Job)
    Assert-Equal $job2.ID (Get-Job).ID
}

function Test-ShouldContinueIfJobFails
{
    $job1 = Start-Job { throw "Fail!" } -Name "Fails"
    $job2 = Start-Job { Start-Sleep -Seconds 3 } -Name "Sleeps3Seconds"
    $numFailed = 0
    try
    {
        $numFailed = Complete-Jobs -Jobs $job1,$job2 
    }
    catch
    {
        Fail "Complete-Jobs failed."
    }
    Assert-Equal 1 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldPipeOutputToWriteHost
{
    $job1 = Start-Job { 
        Write-Output "I'm about to fail!"
        throw "Fail!"
    }
    
    $job2 = Start-Job {
        Write-Output "Me, too!  I hate succeeding."
        throw  "Fail!"
    }
    
    $numFailed = Complete-Jobs -Jobs $job1,$job2
    Assert-Equal 2 $numFailed 
}