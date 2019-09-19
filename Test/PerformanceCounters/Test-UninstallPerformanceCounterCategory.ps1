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

$CategoryName = 'Carbon-PerformanceCounters-UninstallCategory'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, '', (New-Object Diagnostics.CounterCreationDataCollection) )
    Assert-True (Test-PerformanceCounterCategory -CAtegoryName $CAtegoryName) 
}

function Stop-Test
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
    Assert-False (Test-PerformanceCounterCategory -CAtegoryName $CAtegoryName) 
}

function Test-ShouldSupportWhatIf
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName -WhatIf
    Assert-True (Test-PerformanceCounterCategory -CategoryName $CategoryName)
}



