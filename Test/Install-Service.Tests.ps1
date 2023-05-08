
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:serviceNameSuffix = [IO.Path]::GetRandomFileName() -replace '\.', ''
    $script:testDirPath = ''
    $script:testNum = 0
    $script:servicePath = ''
    $script:serviceNamePrefix = 'CarbonTestService'
    $script:serviceName = $null
    $script:serviceAcct = "CISvc${script:serviceNameSuffix}"
    $script:servicePassword = """a1""'~!@# $%^&*("""  # sc.exe needs to have certain characters escaped.
    $script:installServiceParams = @{ }
    $script:startedAt = Get-Date
    $script:serviceCredential = New-CCredential -UserName $script:serviceAcct -Password $script:servicePassword
    Install-CUser -Credential $script:serviceCredential -Description "Account for testing the Carbon Install-CService function."
    $script:defaultServiceAccountName = Resolve-CIdentityName -Name 'NT AUTHORITY\NetworkService'

    function Assert-ServiceInstalled
    {
        $service = Get-Service $script:serviceName
        $service | Should -Not -BeNullOrEmpty | Out-Null
        return $service
    }

    function Assert-HasPermissionsOnServiceExecutable($Identity, $Path)
    {
        $access = Get-CPermission -Path $Path -Identity $Identity
        $access | Should -Not -BeNullOrEmpty
        ([Security.AccessControl.FileSystemRights]::ReadAndExecute) | Should -Be ($access.FileSystemRights -band [Security.AccessControl.FileSystemRights]::ReadAndExecute)
    }

    function Assert-HasNoPermissionsOnServiceExecutable($Identity, $Path)
    {
        $access = Get-CPermission -Path $Path -Identity $Identity
        $access | Should -BeNullOrEmpty
    }

    function Assert-HasPrivilegesOnServiceExecutable($Identity)
    {
        $privilege = Get-CPrivilege -Identity $Identity
        $privilege | Should -Not -BeNullOrEmpty
    }

    function Assert-HasPrivilegesRemovedOnServiceExecutable($Identity)
    {
        $privilege = Get-CPrivilege -Identity $Identity
        $privilege | Should -BeNullOrEmpty
    }

    function Uninstall-TestService
    {
        Uninstall-CService $script:serviceName
    }
}

AfterAll {
    Get-Service -Name 'CarbonTestService*' |
        ForEach-Object { Uninstall-CService -Name $_.Name }
}

Describe 'Install-CService' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDirPath -ItemType 'Directory'

        Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Service\NoOpService.exe' -Resolve) `
                  -Destination $script:testDirPath
        $script:servicePath = Join-Path -Path $script:testDirPath -ChildPath 'NoOpService.exe' -Resolve

        $numCarbonServices =
            Get-Service -Name ('{0}*' -f $script:serviceNamePrefix) |
            Measure-Object |
            Select-Object -ExpandProperty 'Count'
        $script:serviceName = "${script:serviceNamePrefix}-${script:serviceNameSuffix}-$($numCarbonServices + 1)"
        $Global:Error.Clear()
        $script:startedAt = Get-Date
        $script:startedAt = $script:startedAt.AddSeconds(-1)
    }

    AfterEach {
        $script:testNum += 1
        Uninstall-CService -Name $script:serviceName
    }

    It 'should not install the service ' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -WhatIf @installServiceParams
        $service = Get-Service $script:serviceName -ErrorAction SilentlyContinue
        $service | Should -BeNullOrEmpty
    }

    It 'when a service depends on a device driver' {
        $driver =
            [ServiceProcess.ServiceController]::GetDevices() |
            Where-Object 'Status' -EQ 'Running' |
            Select-Object -First 1
        Install-CService -Name $script:serviceName `
                         -Path $script:servicePath `
                         -Dependency $driver.Name `
                         -StartupType Disabled `
                         -ErrorVariable 'errors'
        $errors | Should -BeNullOrEmpty

        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty

        # Can't do this with sc.exe. Maybe it works with the services Win32 APIs?
        $service.DependentServices | Should -HaveCount 0
        $service.ServicesDependedOn | Should -HaveCount 1
        $service.ServicesDependedOn[0].ServiceName | Should -Be $driver.ServiceName
    }

    It 'when startup type is automatic delayed' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -Delayed
        $svc = Get-Service -Name $script:serviceName
        $svc.StartMode | Should -Be 'Automatic'
        $svc.DelayedAutoStart | Should -Be $true
    }

    It 'when startup type is changed to automatic delayed' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic
        $svc = Get-Service -Name $script:serviceName
        $svc.DelayedAutoStart | Should -Be $false

        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -Delayed
        $svc = Get-Service -Name $script:serviceName
        $svc.StartMode | Should -Be 'Automatic'
        $svc.DelayedAutoStart | Should -Be $true
    }


    It 'when startup type is changed' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -Delayed

        $Global:Error.Clear()
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Disabled

        $svc = Get-Service -Name $script:serviceName
        # Regression. When switching from automatic delayed to disabled, error starting the service.
        $Global:Error | Should -HaveCount 0
        $svc.StartMode | Should -Be 'Disabled'
        $svc.DelayedAutoStart | Should -Be $false
        $svc.Status | Should -Be ([ServiceProcess.ServiceControllerStatus]::Stopped)
    }

    It 'when service is stopped and service should be started' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic
        Stop-Service -Name $script:serviceName
        $Global:Error.Clear()
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -EnsureRunning
        Get-Service -Name $script:serviceName | Select-Object -ExpandProperty 'Status' | Should -Be 'Running'
    }

    It 'when service changing from custom account to default account' {
        Install-CService -Name $script:serviceName `
                         -Path $script:servicePath `
                         -StartupType Automatic `
                         -Credential $script:serviceCredential
        Mock -CommandName 'Write-Debug' -ModuleName 'Carbon' -Verifiable
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic
        $svc = Get-Service -Name $script:serviceName
        $svc.UserName | Should -Be (Resolve-IdentityName 'NetworkService')
    }

    It 'when service is a local account and installed multiple times' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -Credential $script:serviceCredential
        Mock -CommandName 'Write-Debug' -ModuleName 'Carbon' -Verifiable
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -Credential $script:serviceCredential
        Assert-MockCalled -CommandName 'Write-Debug' -ModuleName 'Carbon' -Times 1 -ParameterFilter { $Message -like '*settings unchanged*' }
    }

    It 'should install service' {
        $result = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $result | Should -BeNullOrEmpty
        $service = Assert-ServiceInstalled
        $service.Status | Should -Be 'Running'
        $service.Name | Should -Be $script:serviceName
        $service.DisplayName | Should -Be $script:serviceName
        $service.StartMode | Should -Be 'Automatic'
        $service.UserName | Should -Be $script:defaultServiceAccountName
    }

    It 'should reinstall unchanged service with force parameter' -Skip {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $now = Get-Date
        Start-Sleep -Milliseconds (1001 - $now.Millisecond)

        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams -Force

        $maxTries = 50
        $tryNum = 0
        $serviceReinstalled = $false
        do
        {
            [object[]]$events = Get-EventLog -LogName 'System' `
                                             -After $script:startedAt `
                                             -Source 'Service Control Manager' `
                                             -EntryType Information |
                                    Where-Object { ($_.EventID -eq 7036 -or $_.EventID -eq 7045) -and $_.Message -like ('*{0}*' -f $script:serviceName) }

            if( $events )
            {
                if( $events.Count -ge 4 -and
                    $events[0].Message -like '*entered the running state*' -and
                    $events[1].Message -like '*entered the stopped state*' -and
                    $events[2].Message -like '*entered the running state*' -and
                    $events[3].Message -like '*was installed*' )
                {
                    $serviceReinstalled = $true
                    break
                }

                # Windows 10 (and probably Windows 2016)
                if( $events.Count -eq 1 -and
                    $events[0].Message -like '*A service was installed*' )
                {
                    $serviceReinstalled = $true
                    break
                }

            }
            else
            {
                Start-Sleep -Milliseconds 100
            }
        }
        while( $tryNum++ -lt $maxTries )

        $serviceReinstalled | Should -Be $true
    }

    It 'should not install service twice' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $now = Get-Date
        Start-Sleep -Milliseconds (1001 - $now.Millisecond)

        Stop-Service -Name $script:serviceName
        $result = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $result | Should -BeNullOrEmpty
        # This could break if Install-CService is ever updated to not start a stopped service
        (Get-Service -Name $script:serviceName).Status | Should -Be 'Stopped'
    }

    It 'should start stopped automatic service' {
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $output | Should -BeNullOrEmpty

        Stop-Service -Name $script:serviceName

        $warnings = @()
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath -Description 'something new' @installServiceParams -WarningVariable 'warnings'
        $output | Should -BeNullOrEmpty
        (Get-Service -Name $script:serviceName).Status | Should -Be 'Running'
        $warnings.Count | Should -Be 0
    }

    It 'should not install service with space in its path' {
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $svc | Should -BeNullOrEmpty
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $svc | Should -BeNullOrEmpty
    }

    It 'should re install service if path changes' {
        $changedServicePath = Join-Path -Path $script:testDirPath -ChildPath 'NewNoOpService.exe'
        Copy-Item -Path $script:servicePath -Destination $changedServicePath

        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $changedServicePath @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).Path | Should -Be $changedServicePath
    }

    It 'should install service with argument list' {
        $svc = Install-CService -Name $script:serviceName `
                                -Path $script:servicePath `
                                -ArgumentList "-k","Fu bar","-w",'"Surrounded By Quotes"' `
                                @installServiceParams
        $svc | Should -BeNullOrEmpty
        $Global:Error | Should -HaveCount 0
        $svcConfig = Get-CServiceConfiguration -Name $script:serviceName
        $expectedPath = "${script:servicePath} -k ""Fu bar"" -w ""Surrounded By Quotes"""
        $svcConfig.Path | Should -Be $expectedPath
    }

    It 'should reinstall service if argument list changes' {
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath -ArgumentList "-k","Fu bar" @installServiceParams
        $svc | Should -BeNullOrEmpty
        $Global:Error | Should -HaveCount 0
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath -ArgumentList "-k","Fubar" @installServiceParams
        $Global:Error | Should -HaveCount 0
        $svc | Should -BeNullOrEmpty
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath -ArgumentList "-k","Fubar" @installServiceParams
        $svc | Should -BeNullOrEmpty
    }

    It 'should reinstall service if startup type changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Manual @installServiceParams
        (Get-Service -Name $script:serviceName).StartMode | Should -Be 'Manual'
    }

    It 'should reinstall service if reset failure count changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -ResetFailureCount 60 @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).ResetPeriod | Should -Be 60
    }

    It 'should reinstall service if first failure changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure 'Restart' @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).FirstFailure | Should -Be 'Restart'
    }

    It 'should reinstall service if second failure changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnSecondFailure 'Restart' @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).SecondFailure | Should -Be 'Restart'
    }

    It 'should reinstall service if third failure changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnThirdFailure 'Restart' @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).ThirdFailure | Should -Be 'Restart'
    }

    It 'should reinstall service if restart delay changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure 'Restart' @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure 'Restart' -RestartDelay (1000*60*5) @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).RestartDelayMinutes | Should -Be 5
    }

    It 'should reinstall service if reboot delay changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure 'Reboot' @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure 'Reboot' -RebootDelay (1000*60*5) @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).RebootDelayMinutes | Should -Be 5
    }

    It 'should reinstall service if command changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure RunCommand -Command 'fubar' @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure RunCommand -command 'fubar2' @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).FailureProgram | Should -Be 'fubar2'
    }

    It 'should reinstall service if run delay changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure RunCommand -Command 'fubar' -RunCommandDelay 60000 @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure RunCommand -command 'fubar' -RunCommandDelay 30000 @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).RunCommandDelay | Should -Be 30000
    }

    It 'should reinstall service if dependencies change' {
        $service2Name = '{0}-2' -f $script:serviceName
        Install-CService -Name $service2Name -Path $script:servicePath

        try
        {
            $service3Name = '{0}-3' -f $script:serviceName
            Install-CService -Name $service3Name -Path $script:servicePath @installServiceParams

            try
            {
                Install-CService -Name $script:serviceName -Path $script:servicePath  @installServiceParams
                Install-CService -Name $script:serviceName -Path $script:servicePath -Dependency $service2Name @installServiceParams
                (Get-Service -Name $script:serviceName).ServicesDependedOn[0].Name | Should -Be $service2Name

                Install-CService -Name $script:serviceName -Path $script:servicePath -Dependency $service3Name @installServiceParams
                (Get-Service -Name $script:serviceName).ServicesDependedOn[0].Name | Should -Be $service3Name
            }
            finally
            {
                Uninstall-CService $script:serviceName
                Uninstall-CService $service3Name
            }
        }
        finally
        {
            Uninstall-CService -Name $service2Name
        }
    }

    It 'should reinstall service if username changes' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        Install-CService -Name $script:serviceName -Path $script:servicePath -Username 'SYSTEM' @installServiceParams
        (Get-CServiceConfiguration -Name $script:serviceName).UserName | Should -Be 'NT AUTHORITY\SYSTEM'
    }

    It 'should update service properties' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $service = Assert-ServiceInstalled

        $newServicePath = Join-Path -Path $script:testDirPath -ChildPath 'NewNoOpService.exe'
        Copy-Item $script:servicePath $newServicePath
        Install-CService -Name $script:serviceName -Path $newServicePath -StartupType 'Manual' -Username $script:serviceAcct -Password $script:servicePassword @installServiceParams
        $service = Assert-ServiceInstalled
        $service.StartMode | Should -Be 'Manual'
        $service.UserName | Should -Be ".\$script:serviceAcct"
        $service.Status | Should -Be 'Running'
        Assert-HasPermissionsOnServiceExecutable $script:serviceAcct $newServicePath
    }

    It 'should set startup type' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType 'Manual' @installServiceParams
        $service = Assert-ServiceInstalled
        $service.StartMode | Should -Be 'Manual'
    }

    It 'runs service with custom credentials' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -UserName $script:serviceAcct -Password $script:servicePassword @installServiceParams
        $service = Assert-ServiceInstalled
        $service.UserName | Should -Be ".\$($script:serviceAcct)"
        $service = Get-Service $script:serviceName
        $service.Status | Should -Be 'Running'
    }

    It 'should re-install the service with previously removed privileges' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -Credential $script:serviceCredential @installServiceParams
        Assert-HasPrivilegesOnServiceExecutable $script:serviceAcct
        $currentPrivileges = Get-CPrivilege -Identity $script:serviceAcct
        Revoke-CPrivilege -Identity $script:serviceAcct -Privilege $currentPrivileges
        Assert-HasPrivilegesRemovedOnServiceExecutable $script:serviceAcct
        Install-CService -Name $script:serviceName -Path $script:servicePath -Credential $script:serviceCredential
        Assert-HasPrivilegesOnServiceExecutable $script:serviceAcct
    }

    It 'should re-install the service with previously removed permissions'{
        Install-CService -Name $script:serviceName -Path $script:servicePath -Credential $script:serviceCredential @installServiceParams
        Assert-HasPermissionsOnServiceExecutable $script:serviceAcct $script:servicePath
        Revoke-CPermission -Path $script:servicePath -Identity $script:serviceAcct
        $currentPermissions = Get-CPermission -Identity $script:serviceAcct -Path $script:servicePath
        $currentPermissions | Should -BeNullOrEmpty
        Install-CService -Name $script:serviceName -Path $script:servicePath -Credential $script:serviceCredential
        $currentPermissions = Get-CPermission -Identity $script:serviceAcct -Path $script:servicePath
        Assert-HasPermissionsOnServiceExecutable $script:serviceAcct $script:servicePath
    }

    It 'should set custom account with no password' {
        $Error.Clear()
        Install-CService -Name $script:serviceName -Path $script:servicePath -UserName $script:serviceAcct -ErrorAction SilentlyContinue @installServiceParams
        $Error.Count | Should -BeGreaterThan 0
        $service = Assert-ServiceInstalled
        $service.UserName | Should -Be ".\$($script:serviceAcct)"
        $service = Get-Service $script:serviceName
        $service.Status | Should -Be 'Stopped'
    }

    It 'should set custom account with credential' {
        $credential = New-CCredential -UserName $script:serviceAcct -Password $script:servicePassword
        Install-CService -Name $script:serviceName -Path $script:servicePath -Credential $credential @installServiceParams
        $service = Assert-ServiceInstalled
        $service.UserName | Should -Be ".\$($script:serviceAcct)"
        $service = Get-Service $script:serviceName
        $service.Status | Should -Be 'Running'
    }

    It 'should set failure actions' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $service = Assert-ServiceInstalled
        $config = Get-CServiceConfiguration -Name $script:serviceName
        $config.FirstFailure | Should -Be 'TakeNoAction'
        $config.SecondFailure | Should -Be 'TakeNoAction'
        $config.ThirdFailure | Should -Be 'TakeNoAction'
        $config.RebootDelay | Should -Be 0
        $config.ResetPeriod | Should -Be 0
        $config.RestartDelay | Should -Be 0

        Install-CService -Name $script:serviceName `
                        -Path $script:servicePath `
                        -ResetFailureCount 1 `
                        -OnFirstFailur RunCommand `
                        -OnSecondFailure Restart `
                        -OnThirdFailure Reboot `
                        -RestartDelay 18000 `
                        -RebootDelay 30000 `
                        -RunCommandDelay 6000 `
                        -Command 'echo Fubar!' `
                        @installServiceParams

        $config = Get-CServiceConfiguration -Name $script:serviceName
        $config.FirstFailure | Should -Be 'RunCommand'
        $config.FailureProgram | Should -Be 'echo Fubar!'
        $config.SecondFailure | Should -Be 'Restart'
        $config.ThirdFailure | Should -Be 'Reboot'
        $config.RebootDelay | Should -Be 30000
        $config.RebootDelayMinutes | Should -Be 0
        $config.ResetPeriod | Should -Be 1
        $config.ResetPeriodDays | Should -Be 0
        $config.RestartDelay | Should -Be 18000
        $config.RestartDelayMinutes | Should -Be 0
        $config.RunCommandDelay | Should -Be 6000
        $config.RunCommandDelayMinutes | Should -Be 0
    }

    It 'should clear command' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -OnFirstFailure RunCommand -Command 'fubar' @installServiceParams
        $config = Get-CServiceConfiguration -Name $script:serviceName
        $config.FailureProgram | Should -Be 'fubar'
        $config.RunCommandDelay | Should -Be 0

        Install-CService -Name $script:serviceName -Path $script:servicePath
        $config = Get-CServiceConfiguration -Name $script:serviceName
        $config.FailureProgram | Should -BeNullOrEmpty
    }

    It 'should set dependencies' {
        $firstService = (Get-Service -ErrorAction Ignore)[0]
        $secondService = (Get-Service -ErrorAction Ignore)[1]
        Install-CService -Name $script:serviceName -Path $script:servicePath -Dependencies $firstService.Name,$secondService.Name @installServiceParams
        $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $firstService.Name
        $dependencies | Where-Object { $_ -eq "SERVICE_NAME: $script:serviceName" } | Should -Not -BeNullOrEmpty
        $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $secondService.Name
        $dependencies | Where-Object { $_ -eq "SERVICE_NAME: $script:serviceName" } | Should -Not -BeNullOrEmpty
    }

    It 'should test dependencies exist' {
        $error.Clear()
        Install-CService -Name $script:serviceName -Path $script:servicePath -Dependencies IAmAServiceThatDoesNotExist -ErrorAction SilentlyContinue @installServiceParams
        $error.Count | Should -Be 1
        (Test-CService -Name $script:serviceName) | Should -Be $false
    }

    It 'should install service with relative path' {
        $workingDir = $script:servicePath | Split-Path -Parent | Split-Path -Parent
        $dirName = $script:servicePath | Split-Path -Parent | Split-Path -Leaf
        $serviceExeName = $script:servicePath | Split-Path -Leaf
        $svcPath = ".\${dirName}\${serviceExeName}"

        Push-Location -Path $workingDir
        try
        {
            Install-CService -Name $script:serviceName -Path $svcPath @installServiceParams
            Assert-ServiceInstalled
            $svc = Invoke-CPrivateCommand -Name 'Get-CCimInstance' `
                                          -Parameter @{
                                                Class = 'Win32_Service';
                                                Filter = "Name = ""${script:serviceName}"""
                                            }
            $svc.PathName | Should -Be $script:servicePath
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should clear dependencies' {
        $service2Name = '{0}-2' -f $script:serviceName
        try
        {
            Install-CService -Name $service2Name -Path $script:servicePath @installServiceParams
            Install-CService -Name $script:serviceName -Path $script:servicePath -Dependency $service2Name @installServiceParams

            $service = Get-Service -Name $script:serviceName
            $service.ServicesDependedOn.Length | Should -Be 1
            $service.ServicesDependedOn[0].Name | Should -Be $service2Name

            Install-CService -Name $script:serviceName -Path $script:servicePath
            $service = Get-Service -Name $script:serviceName
            $service.ServicesDependedOn.Length | Should -Be 0
        }
        finally
        {
            Uninstall-CService -Name $service2Name
        }
    }

    It 'should not start manual service' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Manual @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty
        $service.Status | Should -Be 'Stopped'

        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Manual -Force @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service.Status | Should -Be 'Stopped'

        Start-Service -Name $script:serviceName
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Manual -Force @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service.Status | Should -Be 'Running'
    }

    It 'should not start disabled service' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Disabled @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty
        $service.Status | Should -Be 'Stopped'

        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Disabled -Force @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service.Status | Should -Be 'Stopped'
    }

    It 'should start a stopped automatic service' {
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service | Should -Not -BeNullOrEmpty
        $service.Status | Should -Be 'Running'

        Stop-Service -Name $script:serviceName
        Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -Force @installServiceParams
        $service = Get-Service -Name $script:serviceName
        $service.Status | Should -Be 'Running'
    }

    It 'should return service object' {
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Automatic -PassThru @installServiceParams
        $svc | Should -Not -BeNullOrEmpty
        $svc.Name | Should -Be $script:serviceName

        # Change service, make sure  object reeturned
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Manual -PassThru @installServiceParams
        $svc | Should -Not -BeNullOrEmpty
        $svc.Name | Should -Be $script:serviceName

        # No changes, service still returned
        $svc = Install-CService -Name $script:serviceName -Path $script:servicePath -StartupType Manual -PassThru @installServiceParams
        $svc | Should -Not -BeNullOrEmpty
        $svc.Name | Should -Be $script:serviceName
    }

    It 'should set description' {
        $description = [Guid]::NewGuid()
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath -Description $description @installServiceParams
        $output | Should -BeNullOrEmpty

        $svc = Get-Service -Name $script:serviceName
        $svc | Should -Not -BeNullOrEmpty
        $svc.Description | Should -Be $description

        $description = [Guid]::NewGuid().ToString()
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath -Description $description @installServiceParams
        $output | Should -BeNullOrEmpty

        $svc = Get-Service -Name $script:serviceName
        $svc | Should -Not -BeNullOrEmpty
        $svc.Description | Should -Be $description

        # Should preserve the description
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $output | Should -BeNullOrEmpty
        $svc.Description | Should -Be $description
    }

    It 'should set display name' {
        $displayName = [Guid]::NewGuid().ToString()
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath -DisplayName $displayName @installServiceParams
        $output | Should -BeNullOrEmpty

        $svc = Get-Service -Name $script:serviceName
        $svc | Should -Not -BeNullOrEmpty
        $svc.DisplayName | Should -Be $displayName

        $displayName = [Guid]::NewGuid().ToString()
        $output = Install-CService -Name $script:serviceName -Path $script:servicePath -DisplayName $displayName @installServiceParams
        $output | Should -BeNullOrEmpty

        $svc = Get-Service -Name $script:serviceName
        $svc | Should -Not -BeNullOrEmpty
        $svc.DisplayName | Should -Be $displayName

        $output = Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $output | Should -BeNullOrEmpty

        $svc = Get-Service -Name $script:serviceName
        $svc | Should -Not -BeNullOrEmpty
        $svc.DisplayName | Should -Be $script:serviceName

    }

    It 'should switch from built-in account to custom acount with credential' {
        Install-CService -Name $script:serviceName -Path $script:servicePath @installServiceParams
        $service = Assert-ServiceInstalled
        $service.UserName | Should -Be $script:defaultServiceAccountName
        Install-CService -Name $script:serviceName -Path $script:servicePath -Credential $script:serviceCredential
        $service = Assert-ServiceInstalled
        (Resolve-IdentityName $service.UserName) | Should -Be (Resolve-IdentityName $script:serviceCredential.UserName)
    }
}
