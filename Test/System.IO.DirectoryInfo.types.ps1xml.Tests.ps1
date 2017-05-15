
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

function GivenANormalDirectory
{
    $path = Join-Path -Path $TestDrive.FullName -ChildPath 'dir'
    New-Item -Path $path -ItemType 'Directory'
}

Describe 'Carbon.when getting normal directoryes' {
    $Global:Error.Clear()

    $dir = GivenANormalDirectory

    It 'should not be a junction' {
        $dir.IsJunction | Should Be $false
    }

    It 'should not be a symbolic link' {
        $dir.IsSymbolicLink | Should Be $false
    }

    It 'should not have a target path' {
        $dir.TargetPath | Should Be $null
    }

    It 'should write no errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

Describe 'Carbon.when getting symoblic link directories' {
    $Global:Error.Clear()
    $sourceDir = GivenANormalDirectory
    $symDirPath = Join-Path -Path $TestDrive.FullName -ChildPath 'destination'
    [Carbon.IO.SymbolicLink]::Create($symDirPath, $sourceDir.FullName, $true)

    $dirInfo = Get-Item -Path $symDirPath

    It 'should be a junction' {
        $dirInfo.IsJunction | Should Be $true
    }

    It 'should be a symbolic link' {
        $dirInfo.IsSymbolicLink | Should Be $true
    }

    It 'should have a target path' {
        $dirInfo.TargetPath | Should Be $sourceDir.FullName
    }

    It 'should write no errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}