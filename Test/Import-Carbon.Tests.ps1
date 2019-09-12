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

$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

Describe 'Import-Carbon' {

    BeforeEach {
        $Global:Error.Clear()
        if( (Get-Module 'Carbon') )
        {
            Remove-Module 'Carbon' -Force
        }
    }
    
    AfterEach {
        if( (Get-Module 'Carbon') )
        {
            Remove-Module 'Carbon' -Force
        }
    }
    
    It 'should import' {
        & $importCarbonPath
        (Get-Command -Module 'Carbon') | Should Not BeNullOrEmpty
    }
    
    It 'should import with prefix' {
        & $importCarbonPath -Prefix 'C'
        $carbonCmds = Get-Command -Module 'Carbon'
        $carbonCmds | Should Not BeNullOrEmpty
        foreach( $cmd in $carbonCmds )
        {
            $cmd.Name | Should -Match '^.+-C.+$'
        }
    }
    
    It 'should handle drives in env path that do not exist' {
        $drive = $null
        for( $idx = [byte][char]'Z'; $idx -ge [byte][char]'A'; --$idx )
        {
            $driveLetter = [char][byte]$idx
            $drive = '{0}:\' -f $driveLetter
            if( -not (Test-Path -Path $drive) )
            {
                break
            }
        }
    
        $badPath = '{0}fubar' -f $drive
        $originalPath = $env:Path
        $env:Path = '{0};{1}' -f $env:Path,$badPath
        try
        {
            & $importCarbonPath
            $Global:Error.Count | Should Be 0
        }
        finally
        {
            $env:Path = $originalPath
        }
    
    }
    
}
