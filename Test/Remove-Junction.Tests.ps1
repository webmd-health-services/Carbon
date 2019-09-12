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

Describe 'Remove-Junction' {
    
    $JunctionPath = $null
    $tempDir = Get-Item -Path 'TestDrive:'
    
    function Invoke-RemoveJunction($junction)
    {
        Remove-Junction $junction
    }
    
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
        Get-ChildItem -Path $tempDir -Directory |
            Where-Object { $_.IsJunction } |
            ForEach-Object { Remove-Junction -LiteralPath $_.FullName }
        Remove-Item -Path $tempDir -Recurse
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

    It 'should remove junction with wildcard characters' {
        Remove-Junction -Path $junctionPath
        $junctionPath = Join-Path -Path $tempDir -ChildPath 'withspecialchars[]'
        Install-Junction -Link $junctionPath -Target $PSScriptRoot
        Remove-Junction -Path $junctionPath
    }
    
    It 'should remove multiple junctions with wildcards' {
        $filePath = Join-Path -Path $tempDir -ChildPath 'file'
        New-Item -Path $filePath -ItemType 'file'
        $dirPath = Join-Path -Path $tempDir -ChildPath 'dir'
        New-Item -Path $dirPath -ItemType 'directory'
        $secondJunction = Join-Path -Path $tempDir -ChildPath 'junction2' 
        Install-Junction -Link $secondJunction -Target $PSScriptRoot

        Remove-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        Get-ChildItem -Path $tempDir | Measure-Object | Select-Object -ExpandProperty 'Count' | Should Be 2
        $filePath | Should Exist
        $dirPath | Should Exist
        $JunctionPath | Should Not Exist
        $secondJunction | Should not Exist
    }

    It 'should not give an error if no junctions and using a wildcard' {
        Remove-Junction -Path $JunctionPath

        $filePath = Join-Path -Path $tempDir -ChildPath 'file'
        New-Item -Path $filePath -ItemType 'file'
        $dirPath = Join-Path -Path $tempDir -ChildPath 'dir'
        New-Item -Path $dirPath -ItemType 'directory'

        Remove-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        $Global:Error.Count | Should Be 0
        $filePath | Should Exist
        $dirPath | Should Exist
    }

    It 'should not give an error if nothing at all to delete' {
        Remove-Junction -Path $JunctionPath
        Get-ChildItem -Path $tempDir | Measure-Object | Select-Object -ExpandProperty 'Count' | Should Be 0
        Remove-Junction -Path (Join-Path -Path $tempDir -ChildPath '*')
        $Global:Error.Count | Should Be 0
    }
}
