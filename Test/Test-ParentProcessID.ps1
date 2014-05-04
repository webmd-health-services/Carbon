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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Test-ProcessesHaveParentProcessID
{
    $parents = @{}
    Get-WmiObject Win32_Process |
        ForEach-Object { $parents[$_.ProcessID] = $_.ParentProcessID }

    $foundSome = $false
    Get-Process | 
        Where-Object { $parents.ContainsKey( [UInt32]$_.Id ) -and $_.ParentProcessID } |
        ForEach-Object {
            $foundSome = $true
            $expectedID = $parents[ [UInt32]$_.Id ]  
            Assert-Equal $expectedID $_.ParentProcessID "Process $($_.Name) [$($_.ID)] does not have expected parent process ID'."
        }
    Assert-True $foundSome 'Didn''t find any processes with parent IDs.'
}
