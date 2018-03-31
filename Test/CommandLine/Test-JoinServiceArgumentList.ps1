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


Describe 'Test-JoinServiceArgumentList' {
    BeforeAll {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Functions\Join-ServiceArgumentList.ps1' -Resolve)
    }
    
    It 'simple join' {
        $commandLine = Join-ServiceArgumentList 'test.exe' @('arg1', 'arg2')
        $expectedCommandLine = 'test.exe arg1 arg2'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe only' {
        $commandLine = Join-ServiceArgumentList 'test.exe'
        $expectedCommandLine = 'test.exe'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'null exe' {
        $commandLine = Join-ServiceArgumentList -Path $null
        $expectedCommandLine = ''
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'empty exe' {
        $commandLine = Join-ServiceArgumentList -Path ''
        $expectedCommandLine = ''
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'empty exe with args' {
        $commandLine = Join-ServiceArgumentList '' @('arg1', 'arg2')
        $expectedCommandLine = 'arg1 arg2'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe only with spaces' {
        $commandLine = Join-ServiceArgumentList 'c:\Program Files\test.exe'
        $expectedCommandLine = '"c:\Program Files\test.exe"'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe with spaces and args' {
        $commandLine = Join-ServiceArgumentList 'c:\Program Files\test.exe' @('arg1', 'arg2')
        $expectedCommandLine = '"c:\Program Files\test.exe" arg1 arg2'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe with spaces and args with spaces' {
        $commandLine = Join-ServiceArgumentList 'c:\Program Files\test.exe' @('arg1 arg1', 'arg2 arg2')
        $expectedCommandLine = '"c:\Program Files\test.exe" "arg1 arg1" "arg2 arg2"'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe with spaces and args with quotes' {
        $commandLine = Join-ServiceArgumentList 'c:\Program Files\test.exe' @('arg1"arg1', 'arg2"arg2')
        $expectedCommandLine = '"c:\Program Files\test.exe" "arg1""arg1" "arg2""arg2"'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe with spaces and args with quotes at beginng or end' {
        $commandLine = Join-ServiceArgumentList 'c:\Program Files\test.exe' @('"arg1', 'arg2"')
        $expectedCommandLine = '"c:\Program Files\test.exe" """arg1" "arg2"""'
        $commandLine | Should Be $expectedCommandLine
    }
    
    It 'exe with spaces and args with quotes and spaces' {
        $commandLine = Join-ServiceArgumentList 'c:\Program Files\test.exe' @('"arg1 "arg1', 'arg2 "arg2"')
        $expectedCommandLine = '"c:\Program Files\test.exe" """arg1 ""arg1" "arg2 ""arg2"""'
        $commandLine | Should Be $expectedCommandLine
    }
}
