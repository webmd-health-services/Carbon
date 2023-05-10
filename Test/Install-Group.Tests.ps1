
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:GroupName = 'Setup Group'
    $script:userName = $CarbonTestUser.UserName
    $script:description = 'Carbon user for use in Carbon tests.'

    function Assert-GroupExists
    {
        $groups = Get-CGroup
        try
        {
            $group = $groups | Where-Object { $_.Name -eq $script:GroupName }
            $group | Should -Not -BeNullOrEmpty
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }

    function Remove-Group
    {
        $groups = Get-CGroup
        try
        {
            $group = $groups | Where-Object { $_.Name -eq $script:GroupName }
            if( $null -ne $group )
            {
                net localgroup $script:GroupName /delete
            }
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }

    function Invoke-NewGroup
    {
        param(
            $Description = '',
            $Members = @()
        )

        $group = Install-CGroup -Name $script:GroupName -Description $Description -Members $Members -PassThru
        try
        {
            $group | Should -Not -BeNullOrEmpty
            Assert-GroupExists
            $expectedGroup = Get-CGroup -Name $script:GroupName
            try
            {
                $expectedGroup.Sid | Should -Be $group.Sid
            }
            finally
            {
                $expectedGroup.Dispose()
            }
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    }

}

Describe 'Install-CGroup' {
    BeforeEach {
        Remove-Group
    }

    AfterEach {
        Remove-Group
    }

    It 'should create group' {
        $expectedDescription = 'Hello, wordl!'
        Invoke-NewGroup -Description $expectedDescription
        $group = Get-CGroup -Name $script:GroupName
        try
        {
            $group | Should -Not -BeNullOrEmpty
            $group.Name | Should -Be $script:GroupName
            $group.Description | Should -Be $expectedDescription
        }
        finally
        {
            $group.Dispose()
        }
    }

    It 'should pass thru group' {
        $group = Install-CGroup -Name $script:GroupName
        try
        {
            $group | Should -BeNullOrEmpty
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }

        $group = Install-CGroup -Name $script:GroupName -PassThru
        try
        {
            $group | Should -Not -BeNullOrEmpty
            $group | Should -BeOfType ([DirectoryServices.AccountManagement.GroupPrincipal])
        }
        finally
        {
            $group.Dispose()
        }
    }

    It 'should add members' {
        Invoke-NewGroup -Members $script:userName

        $details = net localgroup $script:GroupName
        $details | Where-Object { $_ -like ('*{0}*' -f $script:userName) } | Should -Not -BeNullOrEmpty
    }

    It 'should not recreate if group already exists' {
        Invoke-NewGroup -Description 'Description 1'
        $group1 = Get-CGroup -Name $script:GroupName
        try
        {

            Invoke-NewGroup -Description 'Description 2'
            $group2 = Get-CGroup -Name $script:GroupName

            try
            {
                $group2.Description | Should -Be 'Description 2'
                $group2.SID | Should -Be $group1.SID
            }
            finally
            {
                $group2.Dispose()
            }
        }
        finally
        {
            $group1.Dispose()
        }
    }

    It 'should not add member multiple times' {
        Invoke-NewGroup -Members $script:userName

        $Error.Clear()
        Invoke-NewGroup -Members $script:userName
        $Error.Count | Should -Be 0
    }

    It 'should add member with long name' {
        $longUsername = 'abcdefghijklmnopqrst'
        Install-CUser -Credential (New-CCredential -Username $longUsername -Password 'a1b2c34d!')
        try
        {
            Invoke-NewGroup -Members ('{0}\{1}' -f $env:COMPUTERNAME,$longUsername)
            $details = net localgroup $script:GroupName
            $details | Where-Object { $_ -like ('*{0}*' -f $longUsername) }| Should -Not -BeNullOrEmpty
        }
        finally
        {
            Uninstall-CUser -Username $script:userName
        }
    }

    It 'should support what if' {
        $Error.Clear()
        $group = Install-CGroup -Name $script:GroupName -WhatIf -Member 'Administrator'
        try
        {
            $Global:Error.Count | Should -Be 0
            $group | Should -BeNullOrEmpty
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }

        $group = Get-CGroup -Name $script:GroupName -ErrorAction SilentlyContinue
        try
        {
            $group | Should -BeNullOrEmpty
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    }
}
