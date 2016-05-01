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

& (Join-Path -Path $PSScriptRoot 'Import-CarbonForTest.ps1' -Resolve)

Describe 'New-Junction' {

    $JunctionPath = $null
    
    BeforeEach {
        $JunctionPath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    }
    
    AfterEach {
        fsutil reparsepoint delete $JunctionPath
    }
    
    function Invoke-NewJunction($link, $target)
    {
        return New-Junction $link $target
    }
    
    It 'should create junction' {
        $result = Invoke-NewJunction $JunctionPath $PSScriptRoot
        $result | Should Not BeNullOrEmpty
        $JunctionPath | Should Exist
        $result.Attributes -like '*ReparsePoint*' | Should Be $true
    }
    
    It 'should not create junction if link is directory' {
        $error.Clear()
        $result = Invoke-NewJunction $PSScriptRoot $env:Temp 2> $null
        @($error).Length | Should Be 1
        $result | Should BeNullOrEmpty
    }
    
    It 'should not create junction if junction already exists' {
        $error.Clear()
        Invoke-NewJunction $JunctionPath $PSScriptRoot
        @($error).Length | Should Be 0
        
        $result = Invoke-NewJunction $JunctionPath $env:Temp 2> $null
        @($error).Length | Should Be 1
        $result | Should BeNullOrEmpty
    }
    
}
