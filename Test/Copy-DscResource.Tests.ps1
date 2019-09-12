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

$sourceRoot = $null;
$destinationRoot = $null

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
                Test-Path -PathType Container -Path $destinationPath | Should -BeTrue
                Assert-Copy -SourceRoot $_.FullName -DestinationRoot $destinationPath -Recurse
            }
            else
            {
                $destinationPath | Should -Not -Exist
            }
            return
        }
        else
        {
            Test-Path -Path $destinationPath -PathType Leaf | Should -BeTrue -Because ($_.FullName)
        }

        $sourceHash = Get-FileHash -Path $_.FullName | Select-Object -ExpandProperty 'Hash'
        $destinationHashPath = '{0}.checksum' -f $destinationPath
        Test-Path -Path $destinationHashPath -PathType Leaf | Should -BeTrue
        # hash files can't have newlines, so we can't use Get-Content.
        $destinationHash = [IO.File]::ReadAllText($destinationHashPath)
        $destinationHash | Should -Be $sourceHash
    }
}

Describe 'Copy-DscResource' {
    
    BeforeEach {
        $Global:Error.Clear()
        $script:destinationRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('D.{0}' -f [IO.Path]::GetRandomFileName())
        New-Item -Path $destinationRoot -ItemType 'Directory'
        $script:sourceRoot = Join-Path -Path $TestDrive.FullName -ChildPath ('S.{0}' -f [IO.Path]::GetRandomFileName())
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'Dir1\Dir3\zip.zip') -Force
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'Dir1\zip.zip') 
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'Dir2') -ItemType 'Directory'
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip')
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'mov.mof')
        New-Item -Path (Join-Path -Path $sourceRoot -ChildPath 'msi.msi')
    }
    
    It 'should copy files' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot
        $result | Should -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot
    }
    
    It 'should pass thru copied files' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
        $result | Should -Not -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot -Recurse
        $result.Count | Should -Be 10
        foreach( $item in $result )
        {
            $item.FullName | Should -BeLike ('{0}*' -f $destinationRoot)
        }
    }
    
    It 'should only copy changed files' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -BeNullOrEmpty
        [IO.File]::WriteAllText((Join-path -Path $sourceRoot -ChildPath 'mov.mof'), ([Guid]::NewGuid().ToString()))
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 2
        $result[0].Name | Should -Be 'mov.mof'
        $result[1].Name | Should -Be 'mov.mof.checksum'
    }
    
    It 'should always regenerate checksums' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
        $result | Should -Not -BeNullOrEmpty
        [IO.File]::WriteAllText((Join-Path -Path $sourceRoot -ChildPath 'zip.zip.checksum'), 'E4F0D22EE1A26200BA320E18023A56B36FF29AA1D64913C60B46CE7D71E940C6')
        try
        {
            $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
            $result | Should -BeNullOrEmpty
            [IO.File]::WriteAllText((Join-Path -Path $sourceRoot -ChildPath 'zip.zip'), ([Guid]::NewGuid().ToString()))
    
            $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result[0].Name | Should -Be 'zip.zip'
            $result[1].Name | Should -Be 'zip.zip.checksum'
        }
        finally
        {
            Get-ChildItem -Path $sourceRoot -Filter '*.checksum' | Remove-Item
            Clear-Content -Path (Join-Path -Path $sourceRoot -ChildPath 'zip.zip')
        }
    }
    
    It 'should copy recursively' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -Recurse
        $result | Should -BeNullOrEmpty
        Assert-Copy -SourceRoot $sourceRoot -Destination $destinationRoot -Recurse
    }
    
    It 'should force copy' {
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
        $result | Should -Not -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot -Recurse
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Recurse
        $result | Should -BeNullOrEmpty
        $result = Copy-DscResource -Path $sourceRoot -Destination $destinationRoot -PassThru -Force -Recurse
        $result | Should -Not -BeNullOrEmpty
        Assert-Copy $sourceRoot $destinationRoot -Recurse
    }
}
