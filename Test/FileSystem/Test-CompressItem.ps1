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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $PSCommandName = Split-Path -Leaf -Path $PSCommandPath
    $tempDir = New-TempDir -Prefix $PSCommandName
    $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
}

function Test-ShouldCompressFile
{
    $file = Compress-Item -Path $PSCommandPath

    try
    {
        $outRoot = Expand-Item -Path $file
        Assert-NotNull $outRoot
        $expandedFilePath = Join-Path -Path $outRoot -ChildPath (Split-Path -Leaf -Path $PSCommandPath)
        Assert-FileExists $expandedFilePath

        try
        {
            $originalFile = Get-Content -Raw -Path $PSCommandPath
            $expandedFileContent = Get-Content -Raw -Path $expandedFilePath
            Assert-Equal $originalFile $expandedFileContent
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

function Test-ShouldCompressDirectory
{
    $sourceRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    $file = Compress-Item -Path $sourceRoot
    Assert-ZipFileExists $file
    Assert-ZipFileExpands $file $sourceRoot
}

function Test-ShouldCompressWithCOMShellAPI
{
    $sourceRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    $file = Compress-Item -Path $sourceRoot -UseShell
    Assert-ZipFileExists $file
    Assert-ZipFileExpands $file $sourceRoot
}

function Test-ShouldCompressLargeDirectorySynchronouslyWithCOMShellAPI
{
    $sourceRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    $file = Compress-Item -Path $SourceRoot -UseShell
    Assert-ZipFileExists $file
    Assert-ZipFileExpands $file $sourceRoot
}

function Assert-ZipFileExpands
{
    param(
        $file,
        $sourceRoot
    )

    try
    {
        $outRoot = Expand-Item -Path $file
        Assert-NotNull $outRoot
        Assert-DirectoryExists $outRoot

        try
        {
            [object[]]$sourceItems = Get-ChildItem -Path $sourceRoot -Recurse
            Assert-NotNull $sourceItems
            [object[]]$outItems = Get-ChildItem -Path $outRoot -Recurse
            Assert-NotNull $outItems
            Assert-Equal $sourceItems.Count ($outItems.Count - 1)
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

function Test-ShouldCompressWithRelativePath
{
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

function Test-ShouldCreateCustomZipFile
{
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

function Test-ShouldAcceptPipelineInput
{
    $file = Get-ChildItem -Path $PSScriptRoot | Compress-Item -OutFile $zipPath
    Assert-ZipFileExists $file

    $extractRoot = Expand-Item -Path $file
    try
    {
        $sourceFiles = Get-ChildItem -Path $PSScriptRoot -Recurse
        $extractedFiles = Get-ChildItem -Path $extractRoot -Recurse
        Assert-Equal $sourceFiles.Count $extractedFiles.Count
    }
    finally
    {
        Remove-Item -Path $extractRoot -Recurse
    }
}

function Test-ShouldNotOverwriteFile
{
    $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath
    Assert-ZipFileExists $file
    $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'exists'
}

function Test-ShouldOverwriteFile
{
    $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath
    Assert-ZipFileExists $file
    $file = Compress-Item -OutFile $zipPath -Path $PSCommandPath -Force
    Assert-ZipFileExists $file
}

function Test-ShouldHandleZippingZipFile
{
    $file = Compress-Item -OutFile $zipPath -Path $tempDir
    Assert-ZipFileExists $file
    $file = Compress-Item -OutFile $zipPath -Path $tempDir -Force
    Assert-ZipFileExists $file
}

function Assert-ZipFileExists
{
    param(
        $Path
    )

    Assert-NoError

    foreach( $item in $Path )
    {
        Assert-NotNull $item
        Assert-Is $item ([IO.FileInfo])
        Assert-FileExists $item
        Assert-True (Test-ZipFile -Path $item) ('zip file ''{0}'' not found' -f $item)
    }
}

