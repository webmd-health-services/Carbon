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

Describe 'Remove-Junction' {
    
    $JunctionPath = $null
    $tempDir = Get-Item -Path 'TestDrive:'
    
    function Invoke-RemoveJunction($junction)
    {
        Remove-Junction $junction
    }
    
    BeforeEach {
        $JunctionPath = Join-Path $tempDir ([IO.Path]::GetRandomFileName())
        New-Junction $JunctionPath $PSScriptRoot
    }
    
    AfterEach {
        if( Test-Path $JunctionPath -PathType Container )
        {
            cmd /c rmdir $JunctionPath
        }
    }
    
    It 'should remove junction' {
        Invoke-RemoveJunction $JunctionPath
        $JunctionPath | Should Not Exist
        $PSScriptRoot | Should Exist
    }
    
    It 'should fail if junction actually a directory' {
        $realDir = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
        New-Item $realDir -ItemType 'Directory'
        $error.Clear()
        Invoke-RemoveJunction $realDir 2> $null
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'is a directory'
        $realDir | Should Exist
        Remove-Item $realDir
    }
    
    It 'should do nothing if junction actually a file' {
        $path = [IO.Path]::GetTempFileName()
        $error.Clear()
        Invoke-RemoveJunction $path 2> $null
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'is a file'
        $path | Should Exist
        Remove-Item $path
    }
    
    It 'should support what if' {
        Remove-Junction -Path $JunctionPath -WhatIf
        $JunctionPath | Should Exist
        (Join-Path $JunctionPath (Split-Path -Path $PSCommandPath -Leaf)) | Should Exist
        $PSScriptRoot | Should Exist
    }
    
    It 'should remove junction with relative path' {
        $parentDir = Split-Path -Parent -Path $JunctionPath
        $junctionName = Split-Path -Leaf -Path $JunctionPath
        Push-Location $parentDir
        try
        {
            Remove-Junction -Path ".\$junctionName"
            $JunctionPath | Should Not Exist
            $PSScriptRoot | Should Exist
        }
        finally
        {
            Pop-Location
        }
    }
    
}
