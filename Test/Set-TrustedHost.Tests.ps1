
#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:originalTrustedHosts = $null
}

$skip = -not (Test-Path -Path 'WSMan:\localhost\Client\TrustedHosts')

Describe 'Set-CTrustedHost' -Skip:$skip {
    BeforeEach {
        $script:originalTrustedHosts = @( Get-CTrustedHost )
        Clear-CTrustedHost
    }

    AfterEach {
        if( $script:originalTrustedHosts )
        {
            Set-CTrustedHost -Entry $script:originalTrustedHosts
        }
    }

    It 'should set trusted hosts' {
        Set-CTrustedHost 'example.com'
        (Get-CTrustedHost) | Should -Be 'example.com'
        Set-CTrustedHost 'example.com','sub.example.com'
        $hosts = @( Get-CTrustedHost )
        $hosts[0] | Should -Be 'example.com'
        $hosts[1] | Should -Be 'sub.example.com'
    }

    It 'should support what if' {
        Set-CTrustedHost 'example.com'
        (Get-CTrustedHost) | Should -Be 'example.com'
        Set-CTrustedHost 'badexample.com' -WhatIf
        (Get-CTrustedHost) | Should -Be 'example.com'
    }
}
