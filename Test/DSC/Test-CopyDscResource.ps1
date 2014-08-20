# Copyright 2012 Aaron Jensen
# 
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

$sourceRoot = $null;
$destinationRoot = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
    $sourceRoot = New-TempDirectoryTree -Prefix $PSCommandPath -Tree @'
+ Dir1
  + Dir3
    * zip.zip
  * zip.zip
+ Dir2
* zip.zip
* mov.mof
* msi.msi
'@
}

function Start-Test
{
    $destinationRoot = New-TempDir -Prefix $PSCommandPath
}

function Test-ShouldCopyFiles
{
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot
    Assert-Null $result
    Assert-Copy $sourceRoot $destinationRoot
}

function Test-ShouldPassThruCopiedFiles
{
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
    Assert-NotNull $result
    Assert-Copy $sourceRoot $destinationRoot -Recurse
    Assert-Equal 10 $result.Count
    foreach( $item in $result )
    {
        Assert-Like $item.FullName ('{0}*' -f $destinationRoot)
    }
}

function Test-ShouldOnlyCopyChangedFiles
{
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
    Assert-NotNull $result
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
    Assert-Null $result
    [Guid]::NewGuid().ToString() | Set-Content -Path (Join-path -Path $sourceRoot -ChildPath 'mov.mof')
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
    Assert-NotNull $result
    Assert-Equal 2 $result.Count
    Assert-Equal 'mov.mof' $result[0].Name
    Assert-Equal 'mov.mof.checksum' $result[1].Name
}

function Test-ShouldAlwaysRegenerateChecksums
{
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
    Assert-NotNull $result
    'E4F0D22EE1A26200BA320E18023A56B36FF29AA1D64913C60B46CE7D71E940C6' | Set-Content -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip.checksum')
    try
    {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        Assert-Null $result
        [Guid]::NewGuid().ToString() | Set-Content -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip')

        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        Assert-NotNull $result
        Assert-Equal 'zip.zip' $result[0].Name
        Assert-Equal 'zip.zip.checksum' $result[1].Name
    }
    finally
    {
        Get-ChildItem -Path $sourceRoot -Filter '*.checksum' | Remove-Item
        Clear-Content -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip')
    }
}

function Test-ShouldCopyRecursively
{
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -Recurse
    Assert-Null $result
    Assert-Copy -SourceRoot $sourceRoot -Destination $destinationRoot -Recurse
}

function Test-ShouldForceCopy
{
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
    Assert-NotNull $result
    Assert-Copy $sourceRoot $destinationRoot -Recurse
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
    Assert-Null $result
    $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Force -Recurse
    Assert-NotNull $result
    Assert-Copy $sourceRoot $destinationRoot -Recurse
}

function Assert-Copy
{
    param(
        $SourceRoot,

        $DestinationRoot,

        [Switch]
        $Recurse
    )

    Get-ChildItem -Path $SourceRoot | ForEach-Object {

        $destinationPath = Join-Path -Path $DestinationRoot -ChildPath $_.Name

        if( $_.PSIsContainer )
        {
            if( $Recurse )
            {
                Assert-DirectoryExists -Path $destinationPath
                Assert-Copy -SourceRoot $_.FullName -DestinationRoot $destinationPath -Recurse
            }
            else
            {
                Assert-DirectoryDoesNotExist -Path $destinationPath
            }
            return
        }
        else
        {
            Assert-FileExists $destinationPath
        }

        $sourceHash = Get-FileHash -Path $_.FullName | Select-Object -ExpandProperty 'Hash'
        $destinationHashPath = '{0}.checksum' -f $destinationPath
        Assert-FileExists $destinationHashPath
        $destinationHash = Get-Content -Path $destinationHashPath -ReadCount 1
        Assert-Equal $sourceHash $destinationHash
    }
}