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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
$tempDir = $null

Describe 'Get-DscError' {
    
    BeforeEach {
        $tempDir = New-TempDirectory -Prefix $PSCommandPath
        [Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog('Microsoft-Windows-DSC/Operational')
    }
    
    AfterEach {
        Remove-Item $tempDir.FullName -Recurse
    }
    
    configuration IAmBroken
    {
        Set-StrictMode -Off

        Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
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
    
    It 'should get dsc errors' {
        [Diagnostics.Eventing.Reader.EventLogRecord[]]$errorsAtStart = Get-DscError
        $errorsAtStart | Should BeNullOrEmpty
    
        $startTime = Get-Date
    
        & IAmBroken -OutputPath $tempDir.FullName
    
        Start-Sleep -Milliseconds 400
    
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $tempDir.FullName -ErrorAction SilentlyContinue -Force
    
        $dscError = Get-DscError -StartTime $startTime -Wait
        $dscError | Should Not BeNullOrEmpty
        $dscError | Should BeOfType ([Diagnostics.Eventing.Reader.EventLogRecord])
    
        [Diagnostics.Eventing.Reader.EventLogRecord[]]$dscErrors = Get-DscError
        $dscErrors | Should Not BeNullOrEmpty
        $dscErrors.Count | Should BeGreaterThan 0
    
        [Diagnostics.Eventing.Reader.EventLogRecord[]]$dscErrorsBefore = Get-DscError -EndTime $startTime
        $dscErrorsBefore | Should BeNullOrEmpty
    
        Start-Sleep -Milliseconds 800
        $Error.Clear()
        $dscErrors = Get-DscError -StartTime (Get-Date)
        $Global:Error.Count | Should Be 0
        $dscErrors | Should BeNullOrEmpty
    
        # Now, make sure the timeout is customizable.
        $startedAt = Get-Date
        $dscErrors = Get-DscError -StartTime (Get-Date) -Wait -WaitTimeoutSeconds 1
        $Global:Error.Count | Should Be 0
        ((Get-Date) -gt $startedAt.AddSeconds(1)) | Should Be $true
    
        $result = Get-DscError -ComputerName 'fubar' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
        $result | Should BeNullOrEmpty
    
        # Now, make sure you can get stuff from multiple computers
        $dscError = Get-DscError -ComputerName 'localhost',$env:COMPUTERNAME
        $dscError | Should Not BeNullOrEmpty
    }
    
    
}
