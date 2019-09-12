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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1')

describe 'Get-PowerShellModuleInstallPath' {
    $programFilesModulePath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
    if( (Test-Path -Path 'Env:\ProgramW6432') )
    {
        $programFilesModulePath = Join-Path -Path $env:ProgramW6432 -ChildPath 'WindowsPowerShell\Modules'
    }
    $psHomeModulePath = Join-Path -Path $env:SystemRoot -ChildPath 'system32\WindowsPowerShell\v1.0\Modules'

    BeforeEach {
        $Global:Error.Clear()
    }

    it "should get preferred module install path" {
        if( (Test-Path -Path $programFilesModulePath -PathType Container) )
        {
            Get-PowerShellModuleInstallPath | should be $programFilesModulePath
        }
        else
        {
            Get-PowerShellModuleInstallPath | should be $psHomeModulePath
        }
    }

    It 'should use PSHOME if Program Files not in PSModulePath' {
        $originalPsModulePath = $env:PSModulePath
        $env:PSModulePath = $psHomeModulePath
        try
        {
            $path = Get-PowerShellModuleInstallPath 
            $Global:Error.Count | Should Be 0
            ,$path | Should BeOfType ([string])
            ,$path | Should Be $psHomeModulePath
        }
        finally
        {
            $env:PSModulePath = $originalPsModulePath
        }
    }

    It 'should fail if modules paths aren''t in PSModulePath' {
        $originalPsModulePath = $env:PSModulePath
        try
        {
            $env:PSModulePath = (Get-Location).Path
            $path = Get-PowerShellModuleInstallPath -ErrorAction SilentlyContinue 
            $Global:Error.Count | Should Be 1
            $Global:Error | Should Match 'not found'
            ,$path | Should BeNullOrEmpty
        }
        finally
        {
            $env:PSModulePath = $originalPsModulePath
        }
    }
}