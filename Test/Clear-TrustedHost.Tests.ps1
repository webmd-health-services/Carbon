
#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:originalTrustedHosts = $null
}

Describe 'Clear-CTrustedHost' {
    BeforeEach {
        $script:originalTrustedHosts = @( Get-CTrustedHost )
    }

    AfterEach {
        if( $script:originalTrustedHosts )
        {
            Set-CTrustedHost -Entry $script:originalTrustedHosts
        }
    }

    It 'should remove trusted hosts' {
        Set-CTrustedHost 'example.com'
        (Get-CTrustedHost) | Should -Be 'example.com'
        Clear-CTrustedHost
        (Get-CTrustedHost) | Should -BeNullOrEmpty
    }

    It 'should support what if' {
        Set-CTrustedHost 'example.com'
        (Get-CTrustedHost) | Should -Be 'example.com'
        Clear-CTrustedHost -WhatIf
        (Get-CTrustedHost) | Should -Be 'example.com'
    }
}
