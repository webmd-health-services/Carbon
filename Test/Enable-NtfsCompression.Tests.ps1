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

$rootDir = $null
$childDir = $null
$grandchildFile = $null
$childFile = $null

function Assert-EverythingCompressed
{
    Assert-Compressed -Path $rootDir
    Assert-Compressed -Path $childDir
    Assert-Compressed -Path $grandchildFile
    Assert-Compressed -Path $childFile
}

function Assert-NothingCompressed
{
    Assert-NotCompressed -Path $rootDir
    Assert-NotCompressed -Path $childDir
    Assert-NotCompressed -Path $grandchildFile
    Assert-NotCompressed -Path $childFile
}

function Assert-Compressed
{
    param(
        $Path
    )

    (Test-NtfsCompression -Path $Path) | Should -BeTrue
}

function Assert-NotCompressed
{
    param(
        $Path
    )
    (Test-NtfsCompression -Path $Path) | Should -BeFalse
}


Describe 'Enable-NtfsCompression' {
    BeforeEach {
        $Global:Error.Clear()
        $script:rootDir = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        $script:childDir = Join-Path $rootDir -ChildPath 'ChildDir' 
        $script:grandchildFile = Join-Path $rootDir -ChildPath 'ChildDir\GrandchildFile' 
        $script:childFile = Join-Path $rootDir -ChildPath 'ChildFile' 
        
        New-Item -Path $grandchildFile -ItemType 'File' -Force
        New-Item -Path $childFile -ItemType 'File' -Force
    }
    
    It 'should enable compression on directory only' {
        Assert-NothingCompressed
        
        Enable-NtfsCompression -Path $rootDir
    
        Assert-Compressed -Path $rootDir
        Assert-NotCompressed -Path $childDir
        Assert-NotCompressed -path $grandchildFile
        Assert-NotCompressed -Path $childFile
    
        $newFile = Join-Path $rootDir 'newfile'
        '' > $newFile
        Assert-Compressed -Path $newFile
    
        $newDir = Join-Path $rootDir 'newDir'
        $null = New-Item -Path $newDir -ItemType Directory
        Assert-Compressed -Path $newDir
    }
    
    It 'should fail if path does not exist' {
    
        Assert-NothingCompressed
    
        Enable-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
    
        $Global:Error.Count | Should -Be 1
        ($Global:Error[0].Exception.Message -like '*not found*') | Should -BeTrue
    
        Assert-NothingCompressed
    }
    
    It 'should enable compression recursively' {
        Assert-NothingCompressed
        
        Enable-NtfsCompression -Path $rootDir -Recurse
    
        Assert-EverythingCompressed
    }
    
    It 'should support piping items' {
        Assert-NothingCompressed 
    
        Get-ChildItem $rootDir | Enable-NtfsCompression
    
        Assert-NotCompressed $rootDir
        Assert-Compressed $childDir
        Assert-NotCompressed $grandchildFile
        Assert-Compressed $childFile
    }
    
    It 'should support piping strings' {
        ($childFile,$grandchildFile) | Enable-NtfsCompression
    
        Assert-NotCompressed $rootDir
        Assert-NotCompressed $childDir
        Assert-Compressed $grandchildFile
        Assert-Compressed $childFile
    }
    
    It 'should compress array of items' {
        Enable-NtfsCompression -Path $childFile,$grandchildFile
        Assert-NotCompressed $rootDir
        Assert-NotCompressed $childDir
        Assert-Compressed $grandchildFile
        Assert-Compressed $childFile
    }
    
    It 'should compress already compressed item' {
        Enable-NtfsCompression $rootDir -Recurse
        Assert-EverythingCompressed
    
        Enable-NtfsCompression $rootDir -Recurse
        $LASTEXITCODE | Should -Be 0
        Assert-EverythingCompressed
    }
    
    It 'should support what if' {
        Enable-NtfsCompression -Path $childFile -WhatIf
        Assert-NotCompressed $childFile
    }
    
    It 'should not compress if already compressed' {
        Enable-CNtfsCompression -Path $rootDir  
        Assert-Compressed $rootDir
        Mock -CommandName 'Invoke-ConsoleCommand' -ModuleName 'Carbon'
        Enable-CNtfsCompression -Path $rootDir
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 0
        Enable-CNtfsCompression -Path $rootDir -Force
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 1
    }
}
