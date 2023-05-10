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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
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

    Start-Sleep -Milliseconds 100

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $tempDir.FullName -ErrorAction SilentlyContinue -Force

    $dscError = Get-DscError -StartTime $startTime -Wait
    Assert-NotNull $dscError

    $Error.Clear()

    Write-DscError -EventLogRecord $dscError -ErrorAction SilentlyContinue
    Assert-DscError $dscError

    $Error.Clear()
    # Test that you can pipeline errors
    Get-DscError | Write-DscError -PassThru -ErrorAction SilentlyContinue | ForEach-Object { Assert-DscError $_ }

    # Test that it supports an array for the error record
    $Error.Clear()
    Write-DscError @( $dscError, $dscError ) -ErrorAction SilentlyContinue
    Assert-DscError $dscError -Index 0
    Assert-DscError $dscError -Index 1
}

function Assert-DscError
{
    param(
        $DscError,

        $Index = 0
    )

    Set-StrictMode -Version 'Latest'

    Assert-Error
    $msg = $Error[$Index].Exception.Message
    Assert-Like $msg ('`[{0}`]*' -f $DscError.TimeCreated)
    Assert-Like $msg ('* `[{0}`] *' -f $DscError.MachineName)
    for( $idx = 0; $idx -lt $DscError.Properties.Count - 1; ++$idx )
    {
        Assert-Like $msg ('* `[{0}`] *' -f $DscError.Properties[$idx].Value)
    }
    Assert-Like $msg ('* {0}' -f $DscError.Properties[-1].Value)
}
