
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

function GivenANormalFile
{
    $file = Join-Path -Path $TestDrive.FullName -ChildPath 'file'
    '' | Set-Content -Path $file
    Get-Item -Path $file
}

Describe 'Carbon.when getting normal files' {
    $file = GivenANormalFile

    It 'should not be a symbolic link' {
        $file.IsSymbolicLink | Should Be $false
    }
    It 'should not have a target path' {
        $file.TargetPath | Should Be $null
    }
}

Describe 'Carbon.when getting symoblic link files' {
    $file = GivenANormalFile
    $symFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'destination'
    $symFile = [Carbon.IO.SymbolicLink]::Create($symFilePath, $File.FullName, $false)

    $fileInfo = Get-Item -Path $symFilePath

    It 'should be a symbolic link' {
        $fileInfo.IsSymbolicLink | Should Be $true
    }
    It 'should have a target path' {
        $fileInfo.TargetPath | Should Be $file.FullName
    }
}