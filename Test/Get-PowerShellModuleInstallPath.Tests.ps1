
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1')

describe 'Get-PowerShellModuleInstallPath' {
    it "should get preferred module install path" {
        if( $PSVersionTable.PSVersion -lt [Version]'5.0.0' )
        {
            Get-PowerShellModuleInstallPath | should be (Join-Path -Path $env:SystemRoot -ChildPath 'system32\WindowsPowerShell\v1.0\Modules')
        }
        else
        {
            Get-PowerShellModuleInstallPath | should be (Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules')
        }
    }
}