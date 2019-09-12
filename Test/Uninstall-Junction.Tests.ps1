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

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Uninstall-Junction' {
    $JunctionPath = $null
    $tempDir = Get-Item -Path 'TestDrive:'

    BeforeEach {
        $Global:Error.Clear()
        $JunctionPath = Join-Path $tempDir ([IO.Path]::GetRandomFileName())
        New-Junction $JunctionPath $PSScriptRoot
    }
    
    AfterEach {
        if( Test-Path $JunctionPath -PathType Container )
        {
            cmd /c rmdir $JunctionPath
        }
    }
    
    function Invoke-UninstallJunction($junction)
    {
        Uninstall-Junction $junction
    }
    
    It 'should uninstall junction' {
        Invoke-UninstallJunction $JunctionPath
        $Global:Error.Count | Should Be 0
        $JunctionPath | Should Not Exist
        $PSScriptRoot | Should Exist
    }
    
    It 'should fail if junction actually a directory' {
        $realDir = Join-Path $tempDir ([IO.Path]::GetRandomFileName())
        New-Item $realDir -ItemType 'Directory'
        $error.Clear()
        Invoke-UninstallJunction $realDir 2> $null
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'is a directory'
        $realDir | Should Exist
        Remove-Item $realDir
    }
    
    It 'should fail if junction actually a file' {
        $path = [IO.Path]::GetTempFileName()
        $error.Clear()
        Invoke-UninstallJunction $path 2> $null
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'is a file'
        $path | Should Exist
        Remove-Item $path
    }
    
    It 'should support what if' {
        Uninstall-Junction -Path $JunctionPath -WhatIf
        $JunctionPath | Should Exist
        (Join-Path $JunctionPath (Split-Path $PSCommandPath -Leaf)) | Should Exist
        $PSScriptRoot | Should Exist
    }
    
    It 'should remove junction with relative path' {
        $parentDir = Split-Path -Parent -Path $JunctionPath
        $junctionName = Split-Path -Leaf -Path $JunctionPath
        Push-Location $parentDir
        try
        {
            Uninstall-Junction -Path ".\$junctionName"
            $JunctionPath | Should Not Exist
            $PSScriptRoot | Should Exist
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should silently not remove a non-existent junction with wildcards' {
        $path = Join-Path -Path $tempDir -ChildPath 'withwildcards[]'
        Uninstall-Junction -Path $path
        $Global:Error.Count | Should Be 0
    }

    It 'should remove a junction with wildcards' {
        $path = Join-Path -Path $tempDir -ChildPath 'withwildcards[]'
        Install-Junction -Link $path -Target $PSScriptRoot
        Uninstall-Junction -LiteralPath $path
        $Global:Error.Count | Should Be 0
        Test-Path -LiteralPath $path | Should Be $false
    }

    It 'should only delete junctions when using wildcards' {
        $filePath = Join-Path -Path $tempDir -ChildPath 'file'
        New-Item -Path $filePath -ItemType 'file'
        $dirPath = Join-Path -Path $tempDir -ChildPath 'dir'
        New-Item -Path $dirPath -ItemType 'Directory'
        $secondJunction = Join-Path -Path $tempDir -ChildPath 'junction2'
        Install-Junction -Link $secondJunction -Target $PSScriptRoot

        Uninstall-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        $Global:Error.Count | Should Be 0
        $filePath | Should Exist
        $dirPath | Should Exist
        $JunctionPath | Should Not Exist
        $secondJunction | Should not Exist
    }
    
}
