
#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:originalTrustedHosts = $null
}


Describe 'Add-CTrustedHost' {
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

    It 'should add new host' {
        Add-CTrustedHost -Entries example.com
        $trustedHosts = @( Get-CTrustedHost )
        ($trustedHosts -contains 'example.com') | Should -Be $true
        $trustedHosts.Count | Should -Be 1
    }

    It 'should add multiple hosts' {
        Add-CTrustedHost -Entry example.com,webmd.com
        $trustedHosts = @( Get-CTrustedHost )
        ($trustedHosts -contains 'example.com') | Should -Be $true
        ($trustedHosts -contains 'webmd.com') | Should -Be $true
        $trustedHosts.Count | Should -Be 2
    }

    It 'should not duplicate entries' {
        Add-CTrustedHost -Entry example.com
        Add-CTrustedHost -Entry example.com
        $trustedHosts = @( Get-CTrustedHost )
        ($trustedHosts -contains 'example.com') | Should -Be $true
        $trustedHosts.Count | Should -Be 1
    }

    It 'should support what if' {
        $preTrustedHosts = @( Get-CTrustedHost )
        Add-CTrustedHost -Entry example.com -WhatIf
        $trustedHosts = @( Get-CTrustedHost )
        ($trustedHosts -notcontains 'example.com') | Should -Be $true
        $trustedHosts.Count | Should -Be $preTrustedHosts.Count

    }
}
