
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:rootDir = $null
    $script:childDir = $null
    $script:grandchildFile = $null
    $script:childFile = $null
    $script:testNum = 0

    function Assert-EverythingCompressed
    {
        Assert-Compressed -Path $script:rootDir
        Assert-Compressed -Path $script:childDir
        Assert-Compressed -Path $script:grandchildFile
        Assert-Compressed -Path $script:childFile
    }

    function Assert-NothingCompressed
    {
        Assert-NotCompressed -Path $script:rootDir
        Assert-NotCompressed -Path $script:childDir
        Assert-NotCompressed -Path $script:grandchildFile
        Assert-NotCompressed -Path $script:childFile
    }

    function Assert-Compressed
    {
        param(
            $Path
        )

        Test-CNtfsCompression -Path $Path | Should -BeTrue
    }

    function Assert-NotCompressed
    {
        param(
            $Path
        )

        Test-CNtfsCompression -Path $Path | Should -BeFalse
    }
}

Describe 'Enable-CNtfsCompression' {
    BeforeEach {
        $Global:Error.Clear()
        $script:rootDir = Join-Path -Path $TestDrive -ChildPath $script:testNum
        $script:childDir = Join-Path $script:rootDir -ChildPath 'ChildDir'
        $script:grandchildFile = Join-Path $script:rootDir -ChildPath 'ChildDir\GrandchildFile'
        $script:childFile = Join-Path $script:rootDir -ChildPath 'ChildFile'

        New-Item -Path $script:grandchildFile -ItemType 'File' -Force
        New-Item -Path $script:childFile -ItemType 'File' -Force
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'should enable compression on directory only' {
        Assert-NothingCompressed

        Enable-CNtfsCompression -Path $script:rootDir

        Assert-Compressed -Path $script:rootDir
        Assert-NotCompressed -Path $script:childDir
        Assert-NotCompressed -path $script:grandchildFile
        Assert-NotCompressed -Path $script:childFile

        $newFile = Join-Path $script:rootDir 'newfile'
        '' > $newFile
        Assert-Compressed -Path $newFile

        $newDir = Join-Path $script:rootDir 'newDir'
        $null = New-Item -Path $newDir -ItemType Directory
        Assert-Compressed -Path $newDir
    }

    It 'should fail if path does not exist' {

        Assert-NothingCompressed

        Enable-CNtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        ($Global:Error[0].Exception.Message -like '*not found*') | Should -BeTrue

        Assert-NothingCompressed
    }

    It 'should enable compression recursively' {
        Assert-NothingCompressed

        Enable-CNtfsCompression -Path $script:rootDir -Recurse

        Assert-EverythingCompressed
    }

    It 'should support piping items' {
        Assert-NothingCompressed

        Get-ChildItem $script:rootDir | Enable-CNtfsCompression

        Assert-NotCompressed $script:rootDir
        Assert-Compressed $script:childDir
        Assert-NotCompressed $script:grandchildFile
        Assert-Compressed $script:childFile
    }

    It 'should support piping strings' {
        ($script:childFile,$script:grandchildFile) | Enable-CNtfsCompression

        Assert-NotCompressed $script:rootDir
        Assert-NotCompressed $script:childDir
        Assert-Compressed $script:grandchildFile
        Assert-Compressed $script:childFile
    }

    It 'should compress array of items' {
        Enable-CNtfsCompression -Path $script:childFile,$script:grandchildFile
        Assert-NotCompressed $script:rootDir
        Assert-NotCompressed $script:childDir
        Assert-Compressed $script:grandchildFile
        Assert-Compressed $script:childFile
    }

    It 'should compress already compressed item' {
        Enable-CNtfsCompression $script:rootDir -Recurse
        Assert-EverythingCompressed

        Enable-CNtfsCompression $script:rootDir -Recurse
        $LASTEXITCODE | Should -Be 0
        Assert-EverythingCompressed
    }

    It 'should support what if' {
        Enable-CNtfsCompression -Path $script:childFile -WhatIf
        Assert-NotCompressed $script:childFile
    }

    It 'should not compress if already compressed' {
        Enable-CNtfsCompression -Path $script:rootDir
        Assert-Compressed $script:rootDir
        Mock -CommandName 'Invoke-ConsoleCommand' -ModuleName 'Carbon'
        Enable-CNtfsCompression -Path $script:rootDir
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 0
        Enable-CNtfsCompression -Path $script:rootDir -Force
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 1
    }
}
