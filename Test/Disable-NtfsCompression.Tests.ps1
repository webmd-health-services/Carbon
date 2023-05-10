
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0
    $script:rootDir = $null
    $script:childDir = $null
    $script:grandchildFile = $null
    $script:childFile = $null

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

Describe 'Disable-CNtfsCompression' {
    BeforeEach {
        $script:rootDir = Join-Path -Path $TestDrive -ChildPath $script:testNum
        $script:childDir = Join-Path $script:rootDir 'ChildDir'
        $script:grandchildFile = Join-Path $script:rootDir 'ChildDir\GrandchildFile'
        $script:childFile = Join-Path $script:rootDir 'ChildFile'

        New-Item -Path $script:grandchildFile -ItemType 'File' -Force
        New-Item -Path $script:childFile -ItemType 'File' -Force

        Enable-CNtfsCompression $script:rootDir -Recurse

        Assert-EverythingCompressed
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'should disable compression on directory only' {
        Disable-CNtfsCompression -Path $script:rootDir

        Assert-NotCompressed -Path $script:rootDir
        Assert-Compressed -Path $script:childDir
        Assert-Compressed -path $script:grandchildFile
        Assert-Compressed -Path $script:childFile

        $newFile = Join-Path $script:rootDir 'newfile'
        '' > $newFile
        Assert-NotCompressed -Path $newFile

        $newDir = Join-Path $script:rootDir 'newDir'
        $null = New-Item -Path $newDir -ItemType Directory
        Assert-NotCompressed -Path $newDir
    }

    It 'should fail if path does not exist' {
        $Error.Clear()

        Disable-CNtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue

        $Error.Count | Should -Be 1
        ($Error[0].Exception.Message -like '*not found*') | Should -BeTrue

        Assert-EverythingCompressed
    }

    It 'should disable compression recursively' {
        Disable-CNtfsCompression -Path $script:rootDir -Recurse

        Assert-NothingCompressed
    }

    It 'should support piping items' {
        Get-ChildItem $script:rootDir | Disable-CNtfsCompression

        Assert-Compressed $script:rootDir
        Assert-NotCompressed $script:childDir
        Assert-Compressed $script:grandchildFile
        Assert-NotCompressed $script:childFile
    }

    It 'should support piping strings' {
        ($script:childFile,$script:grandchildFile) | Disable-CNtfsCompression

        Assert-Compressed $script:rootDir
        Assert-Compressed $script:childDir
        Assert-NotCompressed $script:grandchildFile
        Assert-NotCompressed $script:childFile
    }

    It 'should decompress array of items' {
        Disable-CNtfsCompression -Path $script:childFile,$script:grandchildFile
        Assert-Compressed $script:rootDir
        Assert-Compressed $script:childDir
        Assert-NotCompressed $script:grandchildFile
        Assert-NotCompressed $script:childFile
    }

    It 'should decompress already decompressed item' {
        Disable-CNtfsCompression $script:rootDir -Recurse
        Assert-NothingCompressed

        Disable-CNtfsCompression $script:rootDir -Recurse
        $LASTEXITCODE | Should -Be 0
        Assert-NothingCompressed
    }

    It 'should support what if' {
        Disable-CNtfsCompression -Path $script:childFile -WhatIf
        Assert-Compressed $script:childFile
    }

    It 'should not decompress if already decompressed' {
        Disable-CNtfsCompression -Path $script:rootDir
        Assert-NotCompressed $script:rootDir
        Mock -CommandName 'Invoke-ConsoleCommand' -ModuleName 'Carbon'
        Disable-CNtfsCompression -Path $script:rootDir
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 0
        Disable-CNtfsCompression -Path $script:rootDir -Force
        Assert-MockCalled 'Invoke-ConsoleCommand' -ModuleName 'Carbon' -Times 1
    }
}
