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

# To convert C:\Users\schedu~1 to C:\Users\scheduleuser

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Install-Junction' {

    $tempDir = Get-Item -Path 'TestDrive:' 
    $junctionPath = $null
    
    function Assert-Junction
    {
        param(
            $ExpectedTarget = $PSScriptRoot
        )
    
        $Error.Count | Should Be 0
        Test-Path -LiteralPath $junctionPath -PathType Container | Should Be $true
    
        $junction = Get-Item -LiteralPath $junctionPath
        $junction.IsJunction | Should Be $true
        $junction.TargetPath | Should Be $ExpectedTarget
    }

    BeforeEach {
        $Global:Error.Clear()
        $junctionPath = Join-Path $tempDir ('Carbon_Test-InstallJunction_{0}' -f ([IO.Path]::GetRandomFileName()))
    }
    
    AfterEach {
        if( Test-Path -Path $junctionPath -PathType Container )
        {
            Remove-Junction -Path $junctionPath
        }
        Get-ChildItem -Path $tempDir |
            Where-Object { $_.IsJunction } |
            ForEach-Object { Remove-Junction -LiteralPath $_.FullName }
        Get-ChildItem -Path $tempDir | Remove-Item -Recurse
    }
    
    It 'should create junction' {
        $junctionPath | Should Not Exist
    
        $result = Install-Junction -Link $junctionPath -Target $PSScriptRoot -PassThru
        $result | Should Not BeNullOrEmpty
        $result | Should BeOfType ([IO.DirectoryInfo])
        $result.FullName | Should Be $junctionPath
        $result.TargetPath | Should Be $PSScriptRoot
        Assert-Junction
    }
    
    It 'should update existing junction' {
        $junctionPath | Should Not Exist
    
        $result = Install-Junction -Link $junctionPath -Target $env:windir -PassThru
        $result | Should Not BeNullOrEmpty
        $result.TargetPath | Should Be $env:windir
        Assert-Junction -ExpectedTarget $env:windir
    
        $result = Install-Junction -LInk $junctionPath -Target $PSScriptRoot -PassThru
        $result | Should Not BeNullOrEmpty
        $result.TargetPath | Should Be $PSScriptRoot
        Assert-Junction
    }
    
    It 'should give an error if link exists and is a directory' {
        New-Item -Path $junctionPath -ItemType Directory
        $Error.Clear()
        try
        {
            $result = Install-Junction -Link $junctionPath -Target $PSScriptRoot -PassThru -ErrorAction SilentlyContinue
            $result | Should BeNullOrEmpty
            $Global:Error.Count | Should BeGreaterThan 0
            $Global:Error[0] | Should Match 'exists'
        }
        finally
        {
            Remove-Item $junctionPath -Recurse
        }
    }
    
    It 'should support what if' {
        $result = Install-Junction -Link $junctionPath -Target $PSScriptRoot -WhatIf -PassThru
        $result | Should BeNullOrEmpty
        $junctionPath | Should Not Exist
    
        $result = Install-Junction -Link $junctionPath -Target $env:windir -PassThru
        $result | Should BeOfType ([IO.DirectoryInfo])
        $junctionPath | Should Be $result.FullName
        $result = Install-Junction -Link $junctionPath -Target $PSScriptRoot -WhatIf -PassThru
        $result | Should BeNullOrEmpty
        Assert-Junction -ExpectedTarget $env:windir
    }
    
    It 'should fail if target does not exist' {
        $target = 'C:\Hello\World\Foo\Bar'
        $target | Should Not Exist
        $Error.Clear()
        $result = Install-Junction -Link $junctionPath -Target $target -ErrorAction SilentlyContinue -PassThru
        $result | Should BeNullOrEmpty
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
        $target | Should Not Exist
        $junctionPath | Should Not Exist
    }
    
    It 'should fail if target is a file' {
        $target = Get-ChildItem -Path $PSScriptRoot -File | Select-Object -First 1
        $target | Should Not BeNullOrEmpty
        $Error.Clear()
        $result = Install-Junction -Link $junctionPath -Target $target.FullName -PassThru -ErrorAction SilentlyContinue
        $result | Should BeNullOrEmpty
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'file'
        $junctionPath | Should Not Exist
    }
    
    It 'should create target if it does not exist' {
        $target = 'Carbon_Test-InstallJunction_{0}' -f [IO.Path]::GetRandomFileName()
        $target = Join-Path -Path $tempDir -ChildPath $target
        $target | Should Not Exist
        $result = Install-Junction -Link $junctionPath -Target $target -Force -PassThru
        $result | Should BeOfType ([IO.DirectoryInfo])
        $result.TargetPath | Should Be $target
        $result.FullName | Should Be $junctionPath
        $Global:Error.Count | Should Be 0
        Assert-Junction -ExpectedTarget $target
    }
    
    It 'should create junction with relative paths' {
        Push-Location $tempDir
        try
        {
            $target = ('..\{0}' -f (Split-Path -Leaf $tempDir))
            $link = '.\{0}' -f (Split-Path -Leaf -Path $junctionPath)
    
            $result = Install-Junction -Link $link -Target $target -PassThru
            $result | Should Not BeNullOrEmpty
            $result.FullName | Should Be $junctionPath
            $result.TargetPath.TrimEnd('\') | Should Be $tempDir.FullName.TrimEnd('\')
    
            Assert-Junction -ExpectedTarget $tempDir.FullName.TrimEnd('\')
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should handle hidden file' {
        $result = Install-Junction -Link $junctionPath -Target $PSScriptRoot -PassThru
        $result | Should BeOfType ([IO.DirectoryInfo])
        $junction = Get-Item -Path $junctionPath
        $junction.Attributes = $junction.Attributes -bor [IO.FileAttributes]::Hidden
        Install-Junction -Link $junctionPath -Target $PSScriptRoot
        $Global:Error.Count | Should Be 0
    }
    
    It 'should return nothing' {
        $result = Install-Junction -Link $junctionPath -Target $PSScriptRoot
        $result | Should BeNullOrEmpty
        Assert-Junction
    }

    It 'should handle special characters in paths' {
        $targetPath = Join-Path -Path $tempDir -ChildPath 'hasspecialchars[]'
        New-Item -Path $targetPath -ItemType 'Directory'
        $junctionPath = Join-Path -Path $tempDir -ChildPath 'linkhasspecialchars[]'
        $result = Install-Junction -Link $junctionPath -Target $targetPath
        $result | Should BeNullOrEmpty
        Assert-Junction -ExpectedTarget $targetPath
    }

    It 'should handle special characters in existing directory' {
        $targetPath = Join-Path -Path $tempDir -ChildPath 'hasspecialchars[]'
        New-Item -Path $targetPath -ItemType 'Directory'
        $junctionPath = Join-Path -Path $tempDir -ChildPath 'linkhasspecialchars[]'
        New-Item -Path $junctionPath -ItemType 'Directory'
        $result = Install-Junction -Link $junctionPath -Target $targetPath -ErrorAction SilentlyContinue
        $result | Should BeNullOrEmpty
        $Global:Error.Count | Should Be 1
        $Global:Error | Where-Object { $_ -like '*is not a junction*' } | Should Not BeNullOrEmpty
    }
    

    It 'should handle special characters in existing junction' {
        $targetPath = Join-Path -Path $tempDir -ChildPath 'originaltarget[]'
        New-Item -Path $targetPath -ItemType 'Directory'

        $secondTarget = Join-Path -Path $tempDir -ChildPath 'secondtarget[]'
        New-Item -Path $secondTarget -ItemType 'Directory'

        $junctionPath = Join-Path -Path $tempDir -ChildPath 'linkhasspecialchars[]'

        $result = Install-Junction -Link $junctionPath -Target $targetPath
        $result | Should BeNullOrEmpty
        $Global:Error.Count | Should Be 0
        Assert-Junction -ExpectedTarget $targetPath

        $result = Install-Junction -Link $junctionPath -Target $secondTarget
        $result | Should BeNullOrEmpty
        $Global:Error.Count | Should Be 0
        Assert-Junction -ExpectedTarget $secondTarget
    }
}
