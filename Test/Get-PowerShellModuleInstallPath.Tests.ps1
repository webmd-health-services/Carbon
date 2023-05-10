
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1')

    $script:programFilesModulePath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
    if ($PSVersionTable['PSEdition'] -eq 'Core')
    {
        $script:programFilesModulePath = Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell\Modules'
    }
    $script:psHomeModulePath = Join-Path -Path $PSHOME -ChildPath 'Modules'
}

Describe 'Get-PowerShellModuleInstallPath' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should get preferred module install path' {
        if( (Test-Path -Path $script:programFilesModulePath -PathType Container) )
        {
            Get-PowerShellModuleInstallPath | Should -Be $script:programFilesModulePath
        }
        else
        {
            Get-PowerShellModuleInstallPath | Should -Be $script:psHomeModulePath
        }
    }

    It 'should use PSHOME if Program Files not in PSModulePath' {
        $originalPsModulePath = $env:PSModulePath
        $env:PSModulePath = $script:psHomeModulePath
        try
        {
            $path = Get-PowerShellModuleInstallPath
            $Global:Error.Count | Should -Be 0
            ,$path | Should -BeOfType ([string])
            ,$path | Should -Be $script:psHomeModulePath
        }
        finally
        {
            $env:PSModulePath = $originalPsModulePath
        }
    }

    It 'should fail if modules paths aren''t in PSModulePath' {
        $originalPsModulePath = $env:PSModulePath
        try
        {
            $env:PSModulePath = (Get-Location).Path
            $path = Get-PowerShellModuleInstallPath -ErrorAction SilentlyContinue
            $Global:Error.Count | Should -Be 1
            $Global:Error | Should -Match 'not found'
            ,$path | Should -BeNullOrEmpty
        }
        finally
        {
            $env:PSModulePath = $originalPsModulePath
        }
    }
}