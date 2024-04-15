
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

    $UserName = 'CarbonDscTestUser'
    $Password = [Guid]::NewGuid().ToString()
    Install-CUser -UserName $UserName -Password $Password

    Start-CarbonDscTestFixture 'Privilege'

    function Revoke-TestUserPrivilege
    {
        if( (Get-CPrivilege -Identity $UserName -NoWarn) )
        {
            Revoke-CPrivilege -Identity $UserName -Privilege (Get-CPrivilege -Identity $UserName -NoWarn) -NoWarn
        }
    }
}

AfterAll {
    Stop-CarbonDscTestFixture
}

Describe 'Carbon_Privilege' {
    BeforeEach {
        $Global:Error.Clear()
        Revoke-TestUserPrivilege
    }

    AfterEach {
        Revoke-TestUserPrivilege
    }

    It 'should grant privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeTrue
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeTrue
    }

    It 'should revoke privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeTrue
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeTrue
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Absent'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeFalse
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeFalse
    }

    It 'should revoke all other privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight' -Ensure 'Present'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeFalse
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeFalse
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyInteractiveLogonRight' -NoWarn) | Should -BeTrue
    }

    It 'should revoke all privileges if ensure absent' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Ensure 'Absent'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeFalse
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeFalse
    }

    It 'should revoke all privileges if privilege null' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege $null -Ensure 'Present'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeFalse
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeFalse
    }

    It 'should revoke all privileges if privilege empty' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present'
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -NoWarn) | Should -BeFalse
        (Test-CPrivilege -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -NoWarn) | Should -BeFalse
    }

    It 'gets no privileges' {
        $resource = Get-TargetResource -Identity $UserName -Privilege @()
        $resource | Should -Not -BeNullOrEmpty
        $resource.Identity | Should -Be $UserName
        ,$resource.Privilege | Should -BeOfType ([string[]])
        $resource.Privilege.Count | Should -Be 0
        Assert-DscResourcePresent $resource
    }

    It 'gets current privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyNetworkLogonRight' -Ensure 'Present'
        $resource = Get-TargetResource -Identity $UserName -Privilege @()
        $resource | Should -Not -BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyBatchLogonRight' } | Should -Not -BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyNetworkLogonRight' } | Should -Not -BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }

    It 'should be absent if any privilege missing' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        $resource = Get-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight'
        $resource | Should -Not -BeNullOrEmpty
        $resource.Privilege | Where-Object { $_ -eq 'SeDenyBatchLogonRight' } | Should -Not -BeNullOrEmpty
        ($resource.Privilege -contains 'SeDenyNetworkLogonRight') | Should -BeFalse
        Assert-DscResourceAbsent $resource
    }

    It 'should test no privileges' {
        (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Present') | Should -BeTrue
        (Test-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent') | Should -BeTrue
    }

    It 'should test existing privileges' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeTrue
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should -BeFalse
    }

    It 'should test and not allow any privileges when absent' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent') | Should -BeFalse
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present') | Should -BeFalse
        Set-TargetResource -Identity $UserName -Privilege @() -Ensure 'Absent'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Absent') | Should -BeTrue
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyNetworkLogonRight' -Ensure 'Present') | Should -BeFalse
    }

    It 'should test when user has extra privilege' {
        Set-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight','SeDenyInteractiveLogonRight' -Ensure 'Present'
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should -BeFalse
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeFalse
    }

    $skipDscTest =
        (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' -and $PSVersionTable['PSVersion'].Major -eq 7

    It 'should run through dsc' -Skip:$skipDscTest {
        configuration DscConfiguration
        {
            param(
                $Ensure
            )

            Set-StrictMode -Off

            Import-DscResource -Name '*' -Module 'Carbon'

            node 'localhost'
            {
                Carbon_Privilege set
                {
                    Identity = $UserName;
                    Privilege = 'SeDenyBatchLogonRight';
                    Ensure = $Ensure;
                }
            }
        }

        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeTrue
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should -BeFalse

        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeFalse
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should -BeTrue
    }

    It 'should run through dsc' -Skip:$skipDscTest {
        configuration DscConfiguration2
        {
            Set-StrictMode -Off

            Import-DscResource -Name '*' -Module 'Carbon'

            node 'localhost'
            {
                Carbon_Privilege set
                {
                    Identity = $UserName;
                    Privilege = 'SeDenyBatchLogonRight';
                    Ensure = 'Present';
                }
            }
        }

        configuration DscConfiguration3
        {
            Set-StrictMode -Off

            Import-DscResource -Name '*' -Module 'Carbon'

            node 'localhost'
            {
                Carbon_Privilege set
                {
                    Identity = $UserName;
                    Ensure = 'Absent';
                }
            }
        }

        & DscConfiguration2 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeTrue

        & DscConfiguration3 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Absent') | Should -BeTrue
    }

    It 'should run through dsc' -Skip:$skipDscTest {
        configuration DscConfiguration4
        {
            Set-StrictMode -Off

            Import-DscResource -Name '*' -Module 'Carbon'

            node 'localhost'
            {
                Carbon_Privilege set
                {
                    Identity = $UserName;
                    Privilege = 'SeDenyBatchLogonRight';
                    Ensure = 'Present';
                }
            }
        }

        configuration DscConfiguration5
        {
            Set-StrictMode -Off

            Import-DscResource -Name '*' -Module 'Carbon'

            node 'localhost'
            {
                Carbon_Privilege set
                {
                    Identity = $UserName;
                    Privilege = $null;
                    Ensure = 'Present';
                }
            }
        }

        & DscConfiguration4 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeTrue

        & DscConfiguration5 -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Identity $UserName -Privilege 'SeDenyBatchLogonRight' -Ensure 'Present') | Should -BeFalse

        $result = Get-DscConfiguration
        $Global:Error.Count | Should -Be 0
        $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Privilege' } | Should -Not -BeNullOrEmpty
    }

}
