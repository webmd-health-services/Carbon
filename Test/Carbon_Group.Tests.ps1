
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve) -ForDsc

    $script:groupName = 'CarbonGroupTest'
    $script:username1 = $CarbonTestUser.UserName
    $script:username2 = 'CarbonTestUser2'
    $script:username3 = 'CarbonTestUser3'
    $script:user1 = $null
    $script:user2 = $null
    $script:user3 = $null
    $script:description = 'Group for testing Carbon''s Group DSC resource.'

    Start-CarbonDscTestFixture 'Group'
    $script:user1 = Resolve-CIdentity -Name $CarbonTestUser.UserName -NoWarn
    $script:user2 = Install-CUser -Credential (New-CCredential -UserName $script:username2 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    $script:user3 = Install-CUser -Credential (New-CCredential -UserName $script:username3 -Password 'P@ssw0rd1') -Description 'Carbon test user' -PassThru
    Install-CGroup -Name $script:groupName -Description $script:description -Member $script:username1,$script:username2
}

AfterAll {
    Stop-CarbonDscTestFixture
}

Describe 'Carbon_Group' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'get target resource' {
        $admins = Get-CGroup 'Administrators'

        $groupName = 'Administrators'
        $resource = Get-TargetResource -Name $groupName
        $resource | Should -Not -BeNullOrEmpty
        $groupName | Should -Be $resource.Name
        $resource.Description | Should -Be $admins.Description
        Assert-DscResourcePresent $resource

        $resource.Members.Count | Should -Be $admins.Members.Count

        foreach( $admin in $admins.Members )
        {
            $found = $false
            foreach( $potentialAdmin in $resource.Members )
            {
                if( $potentialAdmin.Sid -eq $admin.Sid )
                {
                    $found = $true
                    break
                }
            }
            $found | Should -BeTrue
        }
    }

    It 'get target resource does not exist' {
        $resource = Get-TargetResource -Name 'fubarsnafu'
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be 'fubarsnafu'
        $resource.Description | Should -BeNullOrEmpty
        $resource.Members | Should -BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }

    It 'test target resource' {
        $result = Test-TargetResource -Name $script:groupName `
                                      -Description $script:description `
                                      -Members ($script:username1,$script:username2)
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeTrue

        $result = Test-TargetResource -Name $script:groupName -Ensure Absent
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        # expected to be out of date with no properties passed
        $result = Test-TargetResource -Name $script:groupName
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        $result = Test-TargetResource -Name $script:groupName -Members ($script:username1,$script:username2) -Description $script:description
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeTrue

        # Now, make sure if group has extra member we get false
        $result = Test-TargetResource -Name $script:groupName -Members ($script:username1) -Description $script:description
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        # Now, make sure if group is missing a member we get false
        $result = Test-TargetResource -Name $script:groupName -Members ($script:username1,$script:username2,$script:username3) -Description $script:description
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        # Now, make sure if group description is different we get false
        $result = Test-TargetResource -Name $script:groupName -Members ($script:username1,$script:username2) -Description 'a new description'
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        # We get false even if members are same when Should -be absent
        $result = Test-TargetResource -Name $script:groupName -Members $script:username1,$script:username2 -Ensure Absent
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        # We get false even if description is the same when Should -be absent
        $result = Test-TargetResource -Name $script:groupName -Description $script:description -Ensure Absent
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse
    }

    It 'set target resource' {
        $VerbosePreference = 'Continue'

        $script:groupName = 'TestCarbonGroup01'

        # Test for group creation
        Set-TargetResource -Name $script:groupName -Ensure 'Present'

        $group = Get-CGroup -Name $script:groupName
        $group | Should -Not -BeNullOrEmpty
        $group.Name | Should -Be $script:groupName
        $group.Description | Should -BeNullOrEmpty
        $group.Members.Count | Should -Be 0

        # Change members
        Set-TargetResource -Name $script:groupName -Members $script:username1 -Ensure 'Present'
        $group = Get-CGroup -Name $script:groupName
        $group | Should -Not -BeNullOrEmpty
        $group.Name | Should -Be $script:groupName
        $group.Description | Should -BeNullOrEmpty
        $group.Members.Count | Should -Be 1
        $group.Members[0].Sid | Should -Be $script:user1.Sid

        # Change description
        Set-TargetResource -Name $script:groupName -Members $script:username1 -Description 'group description' -Ensure 'Present'

        $group = Get-CGroup -Name $script:groupName
        $group | Should -Not -BeNullOrEmpty
        $group.Name | Should -Be $script:groupName
        $group.Description | Should -Be 'group description'
        $group.Members.Count | Should -Be 1
        $group.Members[0].Sid | Should -Be $script:user1.Sid

        # expected to add member
        Set-TargetResource -Name $script:groupName -Members $script:username1,$script:username2 -Description 'group description' -Ensure 'Present'
        $group = Get-CGroup -Name $script:groupName
        $group | Should -Not -BeNullOrEmpty
        $group.Name | Should -Be $script:groupName
        $group.Description | Should -Be 'group description'
        $group.Members.Count | Should -Be 2
        ($group.Members.Sid -contains $script:user1.Sid) | Should -BeTrue
        ($group.Members.Sid -contains $script:user2.Sid) | Should -BeTrue

        # expected to support whatif for updating group
        Set-TargetResource -Name $script:groupName -Description 'new description' -WhatIf
        $group = Get-CGroup -Name $script:groupName
        $group.Description | Should -Be 'group description'

        # exepected to support whatif for removing members
        Set-TargetResource -Name $script:groupName -Description 'group description' -WhatIf
        $group = Get-CGroup -Name $script:groupName
        $group.Members.Count | Should -Be 2

        # expected to remove members and set description
        Set-TargetResource -Name $script:groupName -Ensure 'Present'
        $group = Get-CGroup -Name $script:groupName
        $group | Should -Not -BeNullOrEmpty
        $group.Name | Should -Be $script:groupName
        $group.Description | Should -BeNullOrEmpty
        $group.Members.Count | Should -Be 0

        # expected to support WhatIf
        Set-TargetResource -Name $script:groupName -Ensure Absent -WhatIf
        (Test-CGroup -Name $script:groupName) | Should -BeTrue

        # Test for group deletion
        Set-TargetResource -Name $script:groupName -Ensure 'Absent'
        (Test-CGroup -Name $script:groupName) | Should -BeFalse
    }

    $skipDscTest =
        (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' -and $PSVersionTable['PSVersion'].Major -eq 7

    It 'should run through dsc' -Skip:$skipDscTest {
        configuration ShouldCreateGroup
        {
            param(
                $Ensure
            )

            Set-StrictMode -Off

            Import-DscResource -Name '*' -Module 'Carbon'

            node 'localhost'
            {
                Carbon_Group CarbonTestGroup
                {
                    Name = 'CDscGroup1'
                    Description = 'Carbon_Group DSC resource test group'
                    Members = @( $script:username1 )
                    Ensure = $Ensure
                }
            }
        }

        $script:groupName = 'CDscGroup1'

        # Test for group creation through DSC execution
        & ShouldCreateGroup -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0

        $result = Test-TargetResource -Name $script:groupName -Description 'Carbon_Group DSC resource test group' -Members $script:username1
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeTrue

        # Test for group deletion through DSC execution
        & ShouldCreateGroup -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0

        $result = Test-TargetResource -Name $script:groupName
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeFalse

        $result = Get-DscConfiguration
        $Global:Error.Count | Should -Be 0
        $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Group' } | Should -Not -BeNullOrEmpty
    }
}
