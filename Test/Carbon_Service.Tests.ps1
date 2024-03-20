
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

    $script:testDirPath = ''
    $script:testNum = 0
    $script:credential = New-CCredential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
    $script:servicePath = $null
    $script:serviceName = 'CarbonDscTestService'
    Install-CUser -Credential $script:credential

    Start-CarbonDscTestFixture 'Service'
}

AfterAll {
    Uninstall-CService -Name $script:serviceName
    Stop-CarbonDscTestFixture
}

Describe 'Carbon_Service' {
    BeforeEach {
        Uninstall-CService -Name $script:serviceName
        $Global:Error.Clear()
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-item -Path $script:testDirPath -ItemType 'Directory'
        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Service\NoOpService.exe') -Destination $script:testDirPath
        $script:servicePath = Join-Path -Path $script:testDirPath -ChildPath 'NoOpService.exe'
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'should get existing services' {
        Get-Service -ErrorAction Ignore |
            # Some services can't be retrieved di-rectly.
            Where-Object 'Name' -NotIn @('lltdsvc', 'lltdio', 'McpManagementService') |
            Where-Object { (Get-Service -Name $_.Name -ErrorAction Ignore) } |
            Where-Object { (-Not [string]::IsNullOrWhitespace($_.Name)) } |
            Select-Object -First 1 |
            ForEach-Object {
                Write-Verbose -Message ($_.Name) -Verbose
                $resource = Get-TargetResource -Name $_.Name
                $Global:Error.Count | Should -Be 0
                $resource | Should -Not -BeNullOrEmpty
                $resource.Name | Should -Be $_.Name
                $path,$argumentList = [Carbon.Shell.Command]::Split($_.Path)
                $resource.Path | Should -Be $path
                $resource.ArgumentList | Should -Be $argumentList
                $resource.StartupType | Should -Be $_.StartMode
                $resource.Delayed | Should -Be $_.DelayedAutoStart
                $resource.OnFirstFailure | Should -Be $_.FirstFailure
                $resource.OnSecondFailure | Should -Be $_.SecondFailure
                $resource.OnThirdFailure | Should -Be $_.ThirdFailure
                $resource.ResetFailureCount | Should -Be $_.ResetPeriod
                $resource.RestartDelay | Should -Be $_.RestartDelay
                $resource.RebootDelay | Should -Be $_.RebootDelay
                $resource.Command | Should -Be $_.FailureProgram
                $resource.RunCommandDelay | Should -Be $_.RunCommandDelay
                $resource.DisplayName | Should -Be $_.DisplayName
                $resource.Description | Should -Be $_.Description
                ($resource.Dependency -join ',') | Should -Be (($_.ServicesDependedOn | Select-Object -ExpandProperty 'Name') -join ',')
                if( $_.UserName -and (Test-CIdentity -Name $_.UserName -NoWarn) )
                {
                    $resource.UserName | Should -Be (Resolve-CIdentityName -Name $_.UserName -NoWarn)
                }
                else
                {
                    $resource.UserName | Should -Be $_.UserName
                }
                $resource.Credential | Should -BeNullOrEmpty
                Assert-DscResourcePresent $resource
            }
    }

    It 'should get non existent service' {
        $name = [Guid]::NewGuid().ToString()
        $resource = Get-TargetResource -Name $name

        $Global:Error.Count | Should -Be 0
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $name
        $resource.Path | Should -BeNullOrEmpty
        $resource.StartupType | Should -BeNullOrEmpty
        $resource.Delayed | Should -BeNullOrEmpty
        $resource.OnFirstFailure | Should -BeNullOrEmpty
        $resource.OnSecondFailure | Should -BeNullOrEmpty
        $resource.OnThirdFailure | Should -BeNullOrEmpty
        $resource.ResetFailureCount | Should -BeNullOrEmpty
        $resource.RestartDelay | Should -BeNullOrEmpty
        $resource.RebootDelay | Should -BeNullOrEmpty
        $resource.Dependency | Should -BeNullOrEmpty
        $resource.Command | Should -BeNullOrEmpty
        $resource.RunCommandDelay | Should -BeNullOrEmpty
        $resource.DisplayName | Should -BeNullOrEmpty
        $resource.Description | Should -BeNullOrEmpty
        $resource.UserName | Should -BeNullOrEmpty
        $resource.Credential | Should -BeNullOrEmpty
        $resource.ArgumentList | Should -Be $null
        Assert-DscResourceAbsent $resource
    }

    It 'should install service' {
        Set-TargetResource -Path $script:servicePath -Name $script:serviceName -Ensure Present
        $Global:Error.Count | Should -Be 0
        $resource = Get-TargetResource -Name $script:serviceName
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $script:serviceName
        $resource.Path | Should -Be $script:servicePath
        $resource.StartupType | Should -Be 'Automatic'
        $resource.Delayed | Should -BeFalse
        $resource.OnFirstFailure | Should -Be 'TakeNoAction'
        $resource.OnSecondFailure | Should -Be 'TakeNoAction'
        $resource.OnThirdFailure | Should -Be 'TakeNoAction'
        $resource.ResetFailureCount | Should -Be 0
        $resource.RestartDelay | Should -Be 0
        $resource.RebootDelay | Should -Be 0
        $resource.Dependency | Should -BeNullOrEmpty
        $resource.Command | Should -BeNullOrEmpty
        $resource.RunCommandDelay | Should -Be 0
        $resource.UserName | Should -Be 'NT AUTHORITY\NETWORK SERVICE'
        $resource.Credential | Should -BeNullOrEmpty
        $resource.DisplayName | Should -Be $script:serviceName
        $resource.Description | Should -BeNullOrEmpty
        $resource.ArgumentList | Should -Be $null
        Assert-DscResourcePresent $resource
    }

    It 'should install service with all options' {
        Set-TargetResource -Path $script:servicePath `
                           -Name $script:serviceName `
                           -Ensure Present `
                           -StartupType Manual `
                           -OnFirstFailure RunCommand `
                           -OnSecondFailure Restart `
                           -OnThirdFailure Reboot `
                           -ResetFailureCount (60*60*24*2) `
                           -RestartDelay (1000*60*5) `
                           -RebootDelay (1000*60*10) `
                           -Command 'fubar.exe' `
                           -RunCommandDelay (60*1000) `
                           -Dependency 'W3SVC' `
                           -DisplayName 'Display Name' `
                           -Description 'Description description description' `
                           -Credential $script:credential
        $Global:Error.Count | Should -Be 0
        $resource = Get-TargetResource -Name $script:serviceName
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $script:serviceName
        $resource.Path | Should -Be $script:servicePath
        $resource.StartupType | Should -Be 'Manual'
        $resource.Delayed | Should -BeFalse
        $resource.OnFirstFailure | Should -Be 'RunCommand'
        $resource.OnSecondFailure | Should -Be 'Restart'
        $resource.OnThirdFailure | Should -Be 'Reboot'
        $resource.ResetFailureCount | Should -Be (60*60*24*2)
        $resource.RestartDelay | Should -Be (1000*60*5)
        $resource.RebootDelay | Should -Be (1000*60*10)
        $resource.Dependency | Should -Be 'W3SVC'
        $resource.Command | Should -Be 'fubar.exe'
        $resource.RunCommandDelay | Should -Be (60*1000)
        $resource.DisplayName | Should -Be 'Display Name'
        $resource.Description | Should -Be 'Description description description'
        $resource.UserName | Should -Be (Resolve-CIdentity -Name $script:credential.UserName -NoWarn).FullName
        $resource.Credential | Should -BeNullOrEmpty
        $resource.ArgumentList | Should -Be $null
        Assert-DscResourcePresent $resource
    }

    It 'should install service as automatic delayed' {
        Set-TargetResource -Path $script:servicePath -Name $script:serviceName -StartupType Automatic -Delayed  -Ensure Present
        $Global:Error.Count | Should -Be 0
        $resource = Get-TargetResource -Name $script:serviceName
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $script:serviceName
        $resource.Path | Should -Be $script:servicePath
        $resource.StartupType | Should -Be 'Automatic'
        $resource.Delayed | Should -BeTrue
        $resource.OnFirstFailure | Should -Be 'TakeNoAction'
        $resource.OnSecondFailure | Should -Be 'TakeNoAction'
        $resource.OnThirdFailure | Should -Be 'TakeNoAction'
        $resource.ResetFailureCount | Should -Be 0
        $resource.RestartDelay | Should -Be 0
        $resource.RebootDelay | Should -Be 0
        $resource.Dependency | Should -BeNullOrEmpty
        $resource.Command | Should -BeNullOrEmpty
        $resource.RunCommandDelay | Should -Be 0
        $resource.UserName | Should -Be 'NT AUTHORITY\NETWORK SERVICE'
        $resource.Credential | Should -BeNullOrEmpty
        $resource.DisplayName | Should -Be $script:serviceName
        $resource.Description | Should -BeNullOrEmpty
        $resource.ArgumentList | Should -Be $null
        Assert-DscResourcePresent $resource
    }

    It 'should install service with argumentlist' {
        Set-TargetResource -Path $script:servicePath -Name $script:serviceName -StartupType Automatic -Delayed  -Ensure Present -ArgumentList @('arg1', 'arg2')
        $Global:Error.Count | Should -Be 0
        $resource = Get-TargetResource -Name $script:serviceName -ArgumentList @('arg1', 'arg2')
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be $script:serviceName
        $resource.Path | Should -Be $script:servicePath
        $resource.StartupType | Should -Be 'Automatic'
        $resource.Delayed | Should -BeTrue
        $resource.OnFirstFailure | Should -Be 'TakeNoAction'
        $resource.OnSecondFailure | Should -Be 'TakeNoAction'
        $resource.OnThirdFailure | Should -Be 'TakeNoAction'
        $resource.ResetFailureCount | Should -Be 0
        $resource.RestartDelay | Should -Be 0
        $resource.RebootDelay | Should -Be 0
        $resource.Dependency | Should -BeNullOrEmpty
        $resource.Command | Should -BeNullOrEmpty
        $resource.RunCommandDelay | Should -Be 0
        $resource.UserName | Should -Be 'NT AUTHORITY\NETWORK SERVICE'
        $resource.Credential | Should -BeNullOrEmpty
        $resource.DisplayName | Should -Be $script:serviceName
        $resource.Description | Should -BeNullOrEmpty
        $resource.ArgumentList | Should -Be @('arg1', 'arg2')
        Assert-DscResourcePresent $resource
    }

    It 'should uninstall service' {
        Set-TargetResource -Name $script:serviceName -Path $script:servicePath -Ensure Present
        $Global:Error.Count | Should -Be 0
        Assert-DscResourcePresent (Get-TargetResource -Name $script:serviceName)
        Set-TargetResource -Name $script:serviceName -Path $script:servicePath -Ensure Absent
        $Global:Error.Count | Should -Be 0
        Assert-DscResourceAbsent (Get-TargetResource -Name $script:serviceName)
    }

    It 'should require path when installing service' {
        Set-TargetResource -Name $script:serviceName -Ensure Present -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'Path\b.*\bmandatory'
        Assert-DscResourceAbsent (Get-TargetResource -Name $script:serviceName)
    }

    It 'should test existing services' {
        $svc = Get-Service -ErrorAction Ignore | Select-Object -First 1
        Test-TargetResource -Name $svc.Name -Ensure Present | Should -BeTrue
        Test-TargetResource -Name $svc.Name -Ensure Absent | Should -BeFalse
    }

    It 'should test missing services' {
        (Test-TargetResource -Name $script:serviceName -Ensure Absent) | Should -BeTrue
        (Test-TargetResource -Name $script:serviceName -Ensure Present) | Should -BeFalse
    }

    It 'should test on credentials' {
        Set-TargetResource -Name $script:serviceName -Path $script:servicePath -Credential $script:credential -Ensure Present
        (Test-TargetResource -Name $script:serviceName -Path $script:servicePath -Credential $script:credential -Ensure Present) | Should -BeTrue
    }

    It 'should not allow both username and credentials' {
        Set-TargetResource -Name $script:serviceName -Path $script:servicePath -Credential $script:credential -username LocalService -Ensure Present -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        (Test-CService -Name $script:serviceName) | Should -BeFalse
    }

    It 'should test on properties' {
        Set-TargetResource -Name $script:serviceName -Path $script:servicePath -Command 'fubar.exe' -Description 'Fubar' -Ensure Present
        $testParams = @{ Name = $script:serviceName; }
        (Test-TargetResource @testParams -Path $script:servicePath -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -Path 'C:\fubar.exe' -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -StartupType Automatic -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -StartupType Manual -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -Delayed -Ensure Present) | Should -BeFalse
        (Test-TargetResource @testParams -Delayed:$false -Ensure Present) | Should -BeTrue

        (Test-TargetResource @testParams -OnFirstFailure TakeNoAction -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -OnFirstFailure Restart -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -OnSecondFailure TakeNoAction -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -OnSecondFailure Restart -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -OnThirdFailure TakeNoAction -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -OnThirdFailure Restart -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -ResetFailureCount 0 -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -ResetFailureCount 50 -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -RestartDelay 0 -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -RestartDelay 50 -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -RebootDelay 0 -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -RebootDelay 50 -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -Dependency @() -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -Dependency @( 'W3SVC' ) -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -Command 'fubar.exe' -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -Command 'fubar2.exe' -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -RunCommandDelay 0 -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -RunCommandDelay 1000 -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -UserName 'NetworkService' -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -Credential $script:credential -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -Description 'Fubar' -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -Description 'Description' -Ensure Present) | Should -BeFalse

        (Test-TargetResource @testParams -DisplayName $script:serviceName -Ensure Present) | Should -BeTrue
        (Test-TargetResource @testParams -DisplayName 'fubar' -Ensure Present) | Should -BeFalse
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
                Carbon_Service set
                {
                    Name = $script:serviceName;
                    Path = $script:servicePath;
                    Ensure = $Ensure;
                }
            }
        }

        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Name $script:serviceName -Ensure 'Present') | Should -BeTrue
        (Test-TargetResource -Name $script:serviceName -Ensure 'Absent') | Should -BeFalse

        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        (Test-TargetResource -Name $script:serviceName -Ensure 'Present') | Should -BeFalse
        (Test-TargetResource -Name $script:serviceName -Ensure 'Absent') | Should -BeTrue

        $result = Get-DscConfiguration
        $Global:Error.Count | Should -Be 0
        $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Service' } | Should -Not -BeNullOrEmpty
    }

}
