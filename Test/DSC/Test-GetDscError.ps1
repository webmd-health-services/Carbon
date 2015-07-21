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

$tempDir = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
}

function Stop-Test
{
    Remove-Item $tempDir.FullName -Recurse
}

configuration IAmBroken
{
    Set-StrictMode -Off

    node 'localhost' 
    {
        Script Fails
        {
             GetScript = { Write-Error 'GetScript' }
             SetScript = { Write-Error 'SetScript' }
             TestScript = { Write-Error 'TestScript' ; return $false }
        }
    }
}

function Test-ShouldGetDscError
{
    $startTime = Get-Date

    & IAmBroken -OutputPath $tempDir.FullName

    Start-Sleep -Milliseconds 200

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $tempDir.FullName -ErrorAction SilentlyContinue -Force

    $dscError = Get-DscError -StartTime $startTime -Wait
    Assert-NotNull $dscError
    Assert-Is $dscError ([Diagnostics.Eventing.Reader.EventLogRecord])

    [Diagnostics.Eventing.Reader.EventLogRecord[]]$dscErrors = Get-DscError
    Assert-NotNull $dscErrors
    Assert-GreaterThan $dscErrors.Count 0

    $endTime = Get-Date

    [Diagnostics.Eventing.Reader.EventLogRecord[]]$dscErrorsBefore = Get-DscError -EndTime $startTime
    Assert-NotNull $dscErrorsBefore
    Assert-Equal ($dscErrors.Count - 1) $dscErrorsBefore.Count

    Start-Sleep -Milliseconds 800
    $Error.Clear()
    $dscErrors = Get-DscError -StartTime (Get-Date)
    Assert-NoError
    Assert-Null $dscErrors

    # Now, make sure the timeout is customizable.
    $startedAt = Get-Date
    $dscErrors = Get-DscError -StartTime (Get-Date) -Wait -WaitTimeoutSeconds 1
    Assert-NoError 
    Assert-True ((Get-Date) -gt $startedAt.AddSeconds(1))

    $result = Get-DscError -ComputerName 'fubar' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $result

    # Now, make sure you can get stuff from multiple computers
    $dscError = Get-DscError -ComputerName 'localhost',$env:COMPUTERNAME
    Assert-NotNull $dscError
}

