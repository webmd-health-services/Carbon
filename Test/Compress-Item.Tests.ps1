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

$tempDir = $null
$zipPath = $null

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-ZipFileExpands
{
    param(
        $file,
        $sourceRoot
    )
    
    try
    {
        $outRoot = Expand-Item -Path $file
        $outRoot | Should Not BeNullOrEmpty
        $outRoot | Should Exist
    
        try
        {
            [object[]]$sourceItems = Get-ChildItem -Path $sourceRoot -Recurse
            $sourceItems | Should Not BeNullOrEmpty
            [object[]]$outItems = Get-ChildItem -Path $outRoot -Recurse
            $outItems | Should Not BeNullOrEmpty
            ($outItems.Count - 1) | Should Be $sourceItems.Count
        }
        finally
        {
            Remove-Item $outRoot -Recurse -ErrorAction Ignore
        }
    }
    finally
    {
        Remove-Item -Path $file -ErrorAction Ignore
    }    
}

function Assert-ZipFileExists
{
    param(
        $Path
    )
    
    $Global:Error.Count | Should Be 0
    
    foreach( $item in $Path )
    {
        $item | Should Not BeNullOrEmpty
        $item | Should Exist
        (Test-ZipFile -Path $item) | Should Be $true
    }
}

Describe 'Compress-Item.when using WhatIf switch' {
    $Global:Error.Clear()
    $item = Compress-Item -Path $PSScriptRoot -WhatIf
    It 'should return nothing' {
        $item | Should BeNullOrEmpty
    }
    It 'should write no errors' {
        $Global:Error | Should BeNullorEmpty
    }
}
    
Describe 'Compress-Item' {
    
    BeforeEach {
        $Global:Error.Clear()
        $PSCommandName = Split-Path -Leaf -Path $PSCommandPath
        $tempDir = New-TempDir -Prefix $PSCommandName
        $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
    }
    
    AfterEach {
        Remove-Item -Path $tempDir -Recurse
    }
    
    It 'should compress file' {
        $file = Compress-Item -Path $PSCommandPath
    
        try
        {
            $outRoot = Expand-Item -Path $file
            $outRoot | Should Not BeNullOrEmpty
            $expandedFilePath = Join-Path -Path $outRoot -ChildPath (Split-Path -Leaf -Path $PSCommandPath)
            $expandedFilePath | Should Exist
    
            try
            {
                $originalFile = Get-Content -Raw -Path $PSCommandPath
                $expandedFileContent = Get-Content -Raw -Path $expandedFilePath
                $expandedFileContent | Should Be $originalFile
            }
            finally
            {
                Remove-Item $outRoot -Recurse
            }
        }
        finally
        {
            Remove-Item $file -Recurse
        }
    }
    
    It 'should compress directory' {
        $file = Compress-Item -Path $PSScriptRoot
        Assert-ZipFileExists $file
        Assert-ZipFileExpands $file $PSScriptRoot
    }
    
    It 'should compress with COM shell API' {
        $file = Compress-Item -Path $PSScriptRoot -UseShell
        Assert-ZipFileExists $file
        Assert-ZipFileExpands $file $PSScriptRoot
    }
    
    It 'should compress large directory synchronously with COM shell API' {
        $file = Compress-Item -Path $PSScriptRoot -UseShell
        Assert-ZipFileExists $file
        Assert-ZipFileExpands $file $PSScriptRoot
    }
    
    It 'should compress with relative path' {
        Push-Location -Path $PSScriptRoot
        try
        {
            $file = Compress-Item -Path ('.\{0}' -f (Split-Path -Leaf -Path $PSCommandPath))
            Assert-ZipFileExists $file
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should create custom zip file' {
        Push-Location -Path $tempDir
        try
        {
            $file = Compress-Item -Path $PSCommandPath -OutFile '.\test.zip'
            Assert-ZipFileExists -Path (Get-Item -Path (Join-Path -Path $tempDir -ChildPath 'test.zip'))
            Assert-ZipFileExists $file
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should accept pipeline input' {
        $file = Get-ChildItem -Path $PSScriptRoot | Compress-Item -OutFile $zipPath
        Assert-ZipFileExists $file
    
        $extractRoot = Expand-Item -Path $file
        try
        {
            $sourceFiles = Get-ChildItem -Path $PSScriptRoot -Recurse
            $extractedFiles = Get-ChildItem -Path $extractRoot -Recurse
            $extractedFiles.Count | Should Be $sourceFiles.Count
        }
        finally
        {
            Remove-Item -Path $extractRoot -Recurse
        }
    }
    
    It 'should not overwrite file' {
        $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath
        Assert-ZipFileExists $file
        $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'exists'
    }
    
    It 'should overwrite file' {
        $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath
        Assert-ZipFileExists $file
        $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath -Force
        Assert-ZipFileExists $file
    }
    
    It 'should handle zipping zip file' {
        $file = Compress-Item -OutFile $zipPath -Path $tempDir
        Assert-ZipFileExists $file
        $file = Compress-Item -OutFile $zipPath -Path $tempDir -Force
        Assert-ZipFileExists $file
    }
    
}
