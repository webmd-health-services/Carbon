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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function TearDown
{
    Get-Job | Stop-Job -PassThru | Remove-Job
}

function Test-ShouldCompleteJobs
{
    $numJobsAtStart = Get-Job | Measure-Object | Select-Object -ExpandProperty 'Count'
    $job = Start-Job { Start-Sleep -Milliseconds 1 } -Name "Sleep1Millisecond"
    $numFailed = Complete-Job -Job $job
    Assert-Equal 0 $numFailed
    $numJobsNow = Get-Job | Measure-Object | Select-Object -ExpandProperty 'Count'
    Assert-Equal $numJobsAtStart $numJobsNow 'completed job not removed'
}

function Test-ShouldWaitToCompleteJobs
{
    $job = Start-Job { Start-Sleep -Seconds 5 } -Name "Sleep5Seconds"
    $start = Get-Date
    $numFailed = Complete-Job -Job $job
    $end = Get-DAte
    $duration = ($end - $start).TotalSeconds
    Assert-True  (0 -lt $duration -and $duration -lt 10)
    Assert-Equal 0 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldDetectFailedJobs
{
    $job = Start-Job { throw "Blarg!" } -Name "Fails"
    $numFailed = Complete-Job -Job $job -ErrorAction SilentlyContinue
    Assert-Equal 1 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldDetectStoppedJobs
{
    $job = Start-Job { Start-Sleep -Seconds 5 } -Name "Sleeps5Seconds"
    $job | Stop-Job
    $numFailed = Complete-Job -Job $job
    Assert-Equal 1 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldStopMultipleJobs
{
    $job1 = Start-Job { Start-Sleep -Seconds 2 } -Name "Sleeps2Seconds"
    $job2 = Start-Job { Start-Sleep -Seconds 1 } -Name "Sleeps1Second"
    $numFailed = Complete-Job -Job $job1,$job2
    Assert-Equal 0 $numFailed
    Assert-Null (Get-Job)
}

function Test-ShouldOnlyCompletePassedJobs
{
    $job1 = Start-Job { Start-Sleep -Seconds 1 } -Name "Sleeps1Second"
    $job2 = Start-Job { Start-Sleep -Seconds 1 } -Name "Sleeps1Second2"
    $numFailed = Complete-Job -Job $job1
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
        $numFailed = Complete-Job -Job $job1,$job2 -ErrorAction SilentlyContinue 
    }
    catch
    {
        Fail "Complete-Job failed."
    }
    Assert-Equal 1 $numFailed
    $job = Get-Job
    Assert-Null $job
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
    
    $numFailed = Complete-Job -Job $job1,$job2 -ErrorAction SilentlyContinue
    Assert-Equal 2 $numFailed 
}
