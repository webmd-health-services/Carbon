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

$mof1Path = $null
$mof2Path = $null
$notAMofPath = $null
$mof3Path = $null
$tempDir = $null
$mof = $null
$clearedMof = @'
/*
@TargetNode='********'
*/

/* ...snip... */

        
instance of OMI_ConfigurationDocument
{
    Version="1.0.0";
};
'@

Describe 'Clear-MofAuthoringMetadata' {
    BeforeEach {
        $Global:Error.Clear()
        $script:tempDir = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $tempDir -ItemType 'Directory'
        $script:mof1Path = Join-Path -Path $tempDir -ChildPath 'computer1.mof'
        $script:mof2Path = Join-Path -Path $tempDir -ChildPath 'computer2.mof'
        $script:mof3Path = Join-Path -Path $tempDir -ChildPath 'computer3.txt'
        $script:notAMofPath = Join-Path -Path $tempDir -ChildPath 'computer2.txt'
    
        $script:mof = @'
/*
@TargetNode='********'
@GeneratedBy=********
@GenerationDate=08/19/2014 13:29:15
@GenerationHost=********
*/

/* ...snip... */

        
instance of OMI_ConfigurationDocument
{
    Version="1.0.0";
    Author="********;
    GenerationDate="08/19/2014 13:29:15";
    GenerationHost="********";
};
'@ 
    
        $mof | Set-Content -Path $mof1Path
        $mof | Set-Content -Path $mof2Path
        $mof | Set-Content -Path $mof3Path
        $mof | Set-Content -Path $notAMofPath
    }
    
    It 'should clear authoring metadata from file' {
        Clear-MofAuthoringMetadata -Path $mof1Path
        (Get-Content -Raw $mof1Path).Trim() | Should Be $clearedMof
        (Get-Content -Raw $mof2Path).Trim() | Should Be $mof
        (Get-Content -Raw $mof3Path).Trim() | Should Be $mof
        (Get-Content -Raw $notAMofPath).Trim() | Should Be $mof
    }
    
    It 'should clear authoring metadata from file without mof extension' {
        Clear-MofAuthoringMetadata -Path $mof3Path
        (Get-Content -Raw $mof3Path).Trim() | Should Be $clearedMof
        (Get-Content -Raw $mof2Path).Trim() | Should Be $mof
        (Get-Content -Raw $mof1Path).Trim() | Should Be $mof
        (Get-Content -Raw $notAMofPath).Trim() | Should Be $mof
    }
    
    It 'should clear authoring metadata from directory' {
        Clear-MofAuthoringMetadata -Path $tempDir
        (Get-Content -Raw $mof1Path).Trim() | Should Be $clearedMof
        (Get-Content -Raw $mof2Path).Trim() | Should Be $clearedMof
        (Get-Content -Raw $mof3Path).Trim() | Should Be $mof
        (Get-Content -Raw $notAMofPath).Trim() | Should Be $mof
    }
    
    It 'should check if path exists' {
        Clear-MofAuthoringMetadata -Path ('C:\{0}' -f ([IO.Path]::GetRandomFileName())) -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'does not exist'
        $Error.Count | Should Be 1
    }
    
    It 'should support what if' {
        Clear-MofAuthoringMetadata -Path $mof1Path -WhatIf
        (Get-Content -Raw $mof1Path).Trim() | Should Be $mof
    }
}
