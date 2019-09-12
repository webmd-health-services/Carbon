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

    (Test-NtfsCompression -Path $Path) | Should Be $true
}

function Assert-NotCompressed
{
    param(
        $Path
    )
    (Test-NtfsCompression -Path $Path) | Should Be $false
}

Describe 'Disable-NtfsCompression' {
    BeforeEach {
        $script:rootDir = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        $script:childDir = Join-Path $rootDir 'ChildDir' 
        $script:grandchildFile = Join-Path $rootDir 'ChildDir\GrandchildFile'
        $script:childFile = Join-Path $rootDir 'ChildFile'

        New-Item -Path $grandchildFile -ItemType 'File' -Force
        New-Item -Path $childFile -ItemType 'File' -Force
    
        Enable-NtfsCompression $rootDir -Recurse
    
        Assert-EverythingCompressed
    }
    
    It 'should disable compression on directory only' {
        Disable-NtfsCompression -Path $rootDir
    
        Assert-NotCompressed -Path $rootDir
        Assert-Compressed -Path $childDir
        Assert-Compressed -path $grandchildFile
        Assert-Compressed -Path $childFile
    
        $newFile = Join-Path $rootDir 'newfile'
        '' > $newFile
        Assert-NotCompressed -Path $newFile
    
        $newDir = Join-Path $rootDir 'newDir'
        $null = New-Item -Path $newDir -ItemType Directory
        Assert-NotCompressed -Path $newDir
    }
    
    It 'should fail if path does not exist' {
        $Error.Clear()
    
        Disable-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
    
        $Error.Count | Should Be 1
        ($Error[0].Exception.Message -like '*not found*') | Should Be $true
    
        Assert-EverythingCompressed
    }
    
    It 'should disable compression recursively' {
        Disable-NtfsCompression -Path $rootDir -Recurse
    
        Assert-NothingCompressed
    }
    
    It 'should support piping items' {
        Get-ChildItem $rootDir | Disable-NtfsCompression
    
        Assert-Compressed $rootDir
        Assert-NotCompressed $childDir
        Assert-Compressed $grandchildFile
        Assert-NotCompressed $childFile
    }
    
    It 'should support piping strings' {
        ($childFile,$grandchildFile) | Disable-NtfsCompression
    
        Assert-Compressed $rootDir
        Assert-Compressed $childDir
        Assert-NotCompressed $grandchildFile
        Assert-NotCompressed $childFile
    }
    
    It 'should decompress array of items' {
        Disable-NtfsCompression -Path $childFile,$grandchildFile
        Assert-Compressed $rootDir
        Assert-Compressed $childDir
        Assert-NotCompressed $grandchildFile
        Assert-NotCompressed $childFile
    }
    
    It 'should decompress already decompressed item' {
        Disable-NtfsCompression $rootDir -Recurse
        Assert-NothingCompressed
    
        Disable-NtfsCompression $rootDir -Recurse
        $LASTEXITCODE | Should -Be 0
        Assert-NothingCompressed
    }
    
    It 'should support what if' {
        Disable-NtfsCompression -Path $childFile -WhatIf
        Assert-Compressed $childFile
    }
    
    It 'should not decompress if already decompressed' {
        Disable-CNtfsCompression -Path $rootDir  
        Assert-NotCompressed $rootDir
        Mock -CommandName 'Invoke-ConsoleCommand' -ModuleName 'Carbon'
        Disable-CNtfsCompression -Path $rootDir
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 0
        Disable-CNtfsCompression -Path $rootDir -Force
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 1
    }
}
