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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Carbon.Shell.Command.Split' {
    
    It 'simple split' {
        $path,$args = [Carbon.Shell.Command]::Split('test.exe arg1 arg2')
        $expectedPath = 'test.exe'
        $expectedArgs = @('arg1', 'arg2')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'exe only' {
        $path,$args = [Carbon.Shell.Command]::Split('test.exe')
        $expectedPath = 'test.exe'
        $expectedArgs = $null
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'null exe' {
        $path,$args = [Carbon.Shell.Command]::Split('')
        $expectedPath = ''
        $expectedArgs = $null
        
        $path | Should BeNullOrEmpty
        $args | Should BeNullOrEmpty
    }
    
    It 'empty exe' {
        $path,$args = [Carbon.Shell.Command]::Split($null)
        $expectedPath = ''
        $expectedArgs = $null
        
        $path | Should BeNullOrEmpty
        $args | Should BeNullOrEmpty
    }
    
    It 'exe only with spaces' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe"')
        $expectedPath = 'c:\Program Files\test.exe'
        $expectedArgs = $null
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'exe with spaces and args' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe" arg1 arg2')
        $expectedPath = 'c:\Program Files\test.exe' 
        $expectedArgs = @('arg1', 'arg2')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'exe with spaces and args with spaces' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe" "arg1 arg1" "arg2 arg2"')
        $expectedPath = 'c:\Program Files\test.exe'
        $expectedArgs = @('arg1 arg1', 'arg2 arg2')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'exe with spaces and args with quotes' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe" "arg1""arg1" "arg2""arg2"')
        $expectedPath = 'c:\Program Files\test.exe'
        $expectedArgs = @('arg1"arg1 arg2arg2')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'exe with spaces and args with quotes at beginng or end' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe" """arg1" "arg2"""')
        $expectedPath = 'c:\Program Files\test.exe'
        $expectedArgs = @('"arg1 arg2"')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'exe with spaces and args with quotes and spaces' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe" """arg1 ""arg1" "arg2 ""arg2"""')
        $expectedPath = 'c:\Program Files\test.exe'
        $expectedArgs = @('"arg1', 'arg1 arg2', 'arg2"')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
    
    It 'random separator spaces' {
        $path,$args = [Carbon.Shell.Command]::Split('"c:\Program Files\test.exe"   arg1   arg2')
        $expectedPath = 'c:\Program Files\test.exe'
        $expectedArgs = @('arg1', 'arg2')
        
        $path | Should Be $expectedPath
        $args | Should Be $expectedArgs
    }
}
