# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

$servicePath = Join-Path -Path $PSScriptRoot -ChildPath 'Service\NoOpService.exe' -Resolve
$serviceName = 'CarbonTestService'
$serviceAcct = 'CrbnInstllSvcTstAcct'
$servicePassword = [Guid]::NewGuid().ToString().Substring(0,14)
$installServiceParams = @{ 
                            #Verbose = $true 
                            }
$startedAt = Get-Date
$serviceCredential = New-Credential -UserName $serviceAcct -Password $servicePassword
Install-User -Credential $serviceCredential -Description "Account for testing the Carbon Install-Service function."
$defaultServiceAccountName = Resolve-IdentityName -Name 'NT AUTHORITY\NetworkService'

function Assert-ServiceInstalled
{
    $service = Get-Service $serviceName
    $service | Should Not BeNullOrEmpty | Out-Null
    return $service
}
    
function Assert-HasPermissionsOnServiceExecutable($Identity, $Path)
{
    $access = Get-Permission -Path $Path -Identity $Identity
    $access | Should Not BeNullOrEmpty
    ([Security.AccessControl.FileSystemRights]::ReadAndExecute) | Should Be ($access.FileSystemRights -band [Security.AccessControl.FileSystemRights]::ReadAndExecute)
}

function GivenTheServiceIsNotInstalled
{
    Uninstall-Service $serviceName
}
    
Describe 'Install-Service when using the -WhatIf switch' {
    GivenTheServiceIsNotInstalled
    Install-Service -Name $serviceName -Path $servicePath -WhatIf @installServiceParams

    It 'should not install the service ' {
        $service = Get-Service $serviceName -ErrorAction SilentlyContinue
        $service | Should BeNullOrEmpty
    }
 }

Describe 'Install-Service' {

    BeforeEach {
        $Global:Error.Clear()
        $startedAt = Get-Date
        $startedAt = $startedAt.AddSeconds(-1)
        GivenTheServiceIsNotInstalled
    }
    
    It 'should install service' {
        $result = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $result | Should BeNullOrEmpty
        $service = Assert-ServiceInstalled 
        $service.Status | Should Be 'Running'
        $service.Name | Should Be $serviceName
        $service.DisplayName | Should Be $serviceName
        $service.StartMode | Should Be 'Automatic'
        $service.UserName | Should Be $defaultServiceAccountName
    }
    
    It 'should reinstall unchanged service with force parameter' -Skip {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $now = Get-Date
        Start-Sleep -Milliseconds (1001 - $now.Millisecond)
    
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams -Force
    
        $maxTries = 50
        $tryNum = 0
        $serviceReinstalled = $false
        do
        {
            [object[]]$events = Get-EventLog -LogName 'System' `
                                             -After $startedAt `
                                             -Source 'Service Control Manager' `
                                             -EntryType Information |
                                    Where-Object { ($_.EventID -eq 7036 -or $_.EventID -eq 7045) -and $_.Message -like ('*{0}*' -f $serviceName) }
    
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
                                       
        $serviceReinstalled | Should Be $true
    }
    
    It 'should not install service twice' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $now = Get-Date
        Start-Sleep -Milliseconds (1001 - $now.Millisecond)
    
        Stop-Service -Name $serviceName
        $result = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $result | Should BeNullOrEmpty
        # This could break if Install-Service is ever updated to not start a stopped service
        (Get-Service -Name $serviceName).Status | Should Be 'Stopped'
    }
    
    It 'should start stopped automatic service' {
        $output = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $output | Should BeNullOrEmpty
    
        Stop-Service -Name $serviceName
    
        $warnings = @()
        $output = Install-Service -Name $serviceName -Path $servicePath -Description 'something new' @installServiceParams -WarningVariable 'warnings'
        $output | Should BeNullOrEmpty
        (Get-Service -Name $serviceName).Status | Should Be 'Running'
        $warnings.Count | Should Be 0
    }
    
    It 'should not install service with space in its path' {
        $tempDir = New-TempDirectory -Prefix 'Carbon Test Install Service'
        Copy-Item -Path $servicePath -Destination $tempDir
        try
        {
            $servicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath)
    
            $svc = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
            $svc | Should BeNullOrEmpty
            $svc = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
            $svc | Should BeNullOrEmpty
        }
        finally
        {
            Uninstall-Service -Name $serviceName
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Ignore
        }
    }
    
    It 'should re install service if path changes' {
        $tempDir = New-TempDir -Prefix 'Carbon+Test-InstallService'
        Copy-Item -Path $servicePath -Destination $tempDir
        $changedServicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath) -Resolve
    
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $changedServicePath @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).Path | Should Be $changedServicePath
    }
    
    It 'should install service with argument list' {
        $tempDir = New-TempDirectory -Prefix 'Carbon Test Install Service'
        Copy-Item -Path $servicePath -Destination $tempDir
        try
        {
            $servicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath)
    
            $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fu bar","-w",'"Surrounded By Quotes"' @installServiceParams
            $svc | Should BeNullOrEmpty
            $Global:Error.Count | Should Be 0
            $svcConfig = Get-ServiceConfiguration -Name $serviceName
            $svcConfig.Path | Should Be ('"{0}" -k "Fu bar" -w "Surrounded By Quotes"' -f $servicePath)
        }
        finally
        {
            Uninstall-Service -Name $serviceName
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
    
    It 'should reinstall service if argument list changes' {
        $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fu bar" @installServiceParams
        $svc | Should BeNullOrEmpty
        $Global:Error.Count | Should Be 0
        $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fubar" @installServiceParams
        $Global:Error.Count | Should Be 0
        $svc | Should BeNullOrEmpty
        $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fubar" @installServiceParams
        $svc | Should BeNullOrEmpty
    }
    
    It 'should reinstall service if startup type changes' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -StartupType Manual @installServiceParams
        (Get-Service -Name $serviceName).StartMode | Should Be 'Manual'
    }
    
    It 'should reinstall service if reset failure count changes' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -ResetFailureCount 60 @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).ResetPeriod | Should Be 60
    }
    
    It 'should reinstall service if first failure changes' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart' @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).FirstFailure | Should Be 'Restart'
    }
    
    It 'should reinstall service if second failure changes' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnSecondFailure 'Restart' @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).SecondFailure | Should Be 'Restart'
    }
    
    It 'should reinstall service if third failure changes' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnThirdFailure 'Restart' @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).ThirdFailure | Should Be 'Restart'
    }
    
    It 'should reinstall service if restart delay changes' {
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart' @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart' -RestartDelay (1000*60*5) @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).RestartDelayMinutes | Should Be 5
    }
    
    It 'should reinstall service if reboot delay changes' {
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Reboot' @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Reboot' -RebootDelay (1000*60*5) @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).RebootDelayMinutes | Should Be 5
    }
    
    It 'should reinstall service if command changes' {
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -Command 'fubar' @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -command 'fubar2' @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).FailureProgram | Should Be 'fubar2'
    }
    
    It 'should reinstall service if run delay changes' {
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -Command 'fubar' -RunCommandDelay 60000 @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -command 'fubar' -RunCommandDelay 30000 @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).RunCommandDelay | Should Be 30000
    }
    
    It 'should reinstall service if dependencies change' {
        $service2Name = '{0}-2' -f $serviceName
        Install-Service -Name $service2Name -Path $servicePath
    
        try
        {
            $service3Name = '{0}-3' -f $serviceName
            Install-Service -Name $service3Name -Path $servicePath @installServiceParams
    
            try
            {
                Install-Service -Name $serviceName -Path $servicePath  @installServiceParams
                Install-Service -Name $serviceName -Path $servicePath -Dependency $service2Name @installServiceParams
                (Get-Service -Name $serviceName).ServicesDependedOn[0].Name | Should Be $service2Name
    
                Install-Service -Name $serviceName -Path $servicePath -Dependency $service3Name @installServiceParams
                (Get-Service -Name $serviceName).ServicesDependedOn[0].Name | Should Be $service3Name
            }
            finally
            {
                Uninstall-Service $serviceName
                Uninstall-Service $service3Name
            }
        }
        finally
        {
            Uninstall-Service -Name $service2Name
        }
    }
    
    It 'should reinstall service if username changes' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        Install-Service -Name $serviceName -Path $servicePath -Username 'SYSTEM' @installServiceParams
        (Get-ServiceConfiguration -Name $serviceName).UserName | Should Be 'NT AUTHORITY\SYSTEM'
    }
    
    It 'should update service properties' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $service = Assert-ServiceInstalled
        
        $tempDir = New-TempDir
        $newServicePath = Join-Path $TempDir NoOpService.exe
        Copy-Item $servicePath $newServicePath
        Install-Service -Name $serviceName -Path $newServicePath -StartupType 'Manual' -Username $serviceAcct -Password $servicePassword @installServiceParams
        $service = Assert-ServiceInstalled
        $service.StartMode | Should Be 'Manual'
        $service.UserName | Should Be ".\$serviceAcct"
        $service.Status | Should Be 'Running'
        Assert-HasPermissionsOnServiceExecutable $serviceAcct $newServicePath
    }
    
    It 'should set startup type' {
        Install-Service -Name $serviceName -Path $servicePath -StartupType 'Manual' @installServiceParams
        $service = Assert-ServiceInstalled
        $service.StartMode | Should Be 'Manual'
    }
    
    It 'should set custom account' {
        $warnings = @()
        Install-Service -Name $serviceName -Path $servicePath -UserName $serviceAcct -Password $servicePassword @installServiceParams -WarningVariable 'warnings'
        $service = Assert-ServiceInstalled
        $service.UserName | Should Be ".\$($serviceAcct)"
        $service = Get-Service $serviceName
        $service.Status | Should Be 'Running'
        $warnings.Count | Should Be 1
        $warnings[0] -like '*obsolete*' | Should Be $true
    }
    
    It 'should set custom account with no password' {
        $Error.Clear()
        Install-Service -Name $serviceName -Path $servicePath -UserName $serviceAcct -ErrorAction SilentlyContinue @installServiceParams
        $Error.Count | Should BeGreaterThan 0
        $service = Assert-ServiceInstalled
        $service.UserName | Should Be ".\$($serviceAcct)"
        $service = Get-Service $serviceName
        $service.Status | Should Be 'Stopped'
    }
    
    It 'should set custom account with credential' {
        $credential = New-Credential -UserName $serviceAcct -Password $servicePassword
        Install-Service -Name $serviceName -Path $servicePath -Credential $credential @installServiceParams
        $service = Assert-ServiceInstalled
        $service.UserName | Should Be ".\$($serviceAcct)"
        $service = Get-Service $serviceName
        $service.Status | Should Be 'Running'
    }
    
    It 'should set failure actions' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $service = Assert-ServiceInstalled
        $config = Get-Serviceconfiguration -Name $serviceName
        $config.FirstFailure | Should Be 'TakeNoAction'
        $config.SecondFailure | Should Be 'TakeNoAction'
        $config.ThirdFailure | Should Be 'TakeNoAction'
        $config.RebootDelay | Should Be 0
        $config.ResetPeriod | Should Be 0
        $config.RestartDelay | Should Be 0
    
        Install-Service -Name $serviceName `
                        -Path $servicePath `
                        -ResetFailureCount 1 `
                        -OnFirstFailur RunCommand `
                        -OnSecondFailure Restart `
                        -OnThirdFailure Reboot `
                        -RestartDelay 18000 `
                        -RebootDelay 30000 `
                        -RunCommandDelay 6000 `
                        -Command 'echo Fubar!' `
                        @installServiceParams
    
        $config = Get-ServiceConfiguration -Name $serviceName
        $config.FirstFailure | Should Be 'RunCommand'
        $config.FailureProgram | Should Be 'echo Fubar!'
        $config.SecondFailure | Should Be 'Restart'
        $config.ThirdFailure | Should Be 'Reboot'
        $config.RebootDelay | Should Be 30000
        $config.RebootDelayMinutes | Should Be 0
        $config.ResetPeriod | Should Be 1
        $config.ResetPeriodDays | Should Be 0
        $config.RestartDelay | Should Be 18000
        $config.RestartDelayMinutes | Should Be 0
        $config.RunCommandDelay | Should Be 6000
        $config.RunCommandDelayMinutes | Should Be 0
    }
    
    It 'should clear command' {
        Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -Command 'fubar' @installServiceParams
        $config = Get-ServiceConfiguration -Name $serviceName
        $config.FailureProgram | Should Be 'fubar'
        $config.RunCommandDelay | Should Be 0
    
        Install-Service -Name $serviceName -Path $servicePath
        $config = Get-ServiceConfiguration -Name $serviceName
        $config.FailureProgram | Should BeNullOrEmpty
    }
    
    It 'should set dependencies' {
        $firstService = (Get-Service)[0]
        $secondService = (Get-Service)[1]
        Install-Service -Name $serviceName -Path $servicePath -Dependencies $firstService.Name,$secondService.Name @installServiceParams
        $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $firstService.Name
        $dependencies | Where-Object { $_ -eq "SERVICE_NAME: $serviceName" } | Should Not BeNullOrEmpty
        $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $secondService.Name
        $dependencies | Where-Object { $_ -eq "SERVICE_NAME: $serviceName" } | Should Not BeNullOrEmpty
    }
    
    It 'should test dependencies exist' {
        $error.Clear()
        Install-Service -Name $serviceName -Path $servicePath -Dependencies IAmAServiceThatDoesNotExist -ErrorAction SilentlyContinue @installServiceParams
        $error.Count | Should Be 1
        (Test-Service -Name $serviceName) | Should Be $false
    }
    
    It 'should install service with relative path' {
        $parentDir = Split-Path -Parent -Path $PSScriptRoot
        $dirName = Split-Path -Leaf -Path $PSScriptRoot
        $serviceExeName = Split-Path -Leaf -Path $servicePath
        $path = ".\{0}\Service\{1}" -f $dirName,$serviceExeName
    
        Push-Location -Path $parentDir
        try
        {
            Install-Service -Name $serviceName -Path $path @installServiceParams
            $service = Assert-ServiceInstalled 
            $svc = Get-WmiObject -Class 'Win32_Service' -Filter ('Name = "{0}"' -f $serviceName)
            $svc.PathName | Should Be $servicePath
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should clear dependencies' {
        $service2Name = '{0}-2' -f $serviceName
        try
        {
            Install-Service -Name $service2Name -Path $servicePath @installServiceParams
            Install-Service -Name $serviceName -Path $servicePath -Dependency $service2Name @installServiceParams
    
            $service = Get-Service -Name $serviceName
            $service.ServicesDependedOn.Length | Should Be 1
            $service.ServicesDependedOn[0].Name | Should Be $service2Name
    
            Install-Service -Name $serviceName -Path $servicePath
            $service = Get-Service -Name $serviceName
            $service.ServicesDependedOn.Length | Should Be 0
        }
        finally
        {
            Uninstall-Service -Name $service2Name
        }
    }
    
    It 'should not start manual service' {
        Install-Service -Name $serviceName -Path $servicePath -StartupType Manual @installServiceParams
        $service = Get-Service -Name $serviceName
        $service | Should Not BeNullOrEmpty
        $service.Status | Should Be 'Stopped'
    
        Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -Force @installServiceParams
        $service = Get-Service -Name $serviceName
        $service.Status | Should Be 'Stopped'
    
        Start-Service -Name $serviceName
        Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -Force @installServiceParams
        $service = Get-Service -Name $serviceName
        $service.Status | Should Be 'Running'
    }
    
    It 'should not start disabled service' {
        Install-Service -Name $serviceName -Path $servicePath -StartupType Disabled @installServiceParams
        $service = Get-Service -Name $serviceName
        $service | Should Not BeNullOrEmpty
        $service.Status | Should Be 'Stopped'
    
        Install-Service -Name $serviceName -Path $servicePath -StartupType Disabled -Force @installServiceParams
        $service = Get-Service -Name $serviceName
        $service.Status | Should Be 'Stopped'
    }
    
    It 'should start a stopped automatic service' {
        Install-Service -Name $serviceName -Path $servicePath -StartupType Automatic @installServiceParams
        $service = Get-Service -Name $serviceName
        $service | Should Not BeNullOrEmpty
        $service.Status | Should Be 'Running'
    
        Stop-Service -Name $serviceName
        Install-Service -Name $serviceName -Path $servicePath -StartupType Automatic -Force @installServiceParams
        $service = Get-Service -Name $serviceName
        $service.Status | Should Be 'Running'
    }
    
    It 'should return service object' {
        $svc = Install-Service -Name $serviceName -Path $servicePath -StartupType Automatic -PassThru @installServiceParams
        $svc | Should Not BeNullOrEmpty
        $svc.Name | Should Be $serviceName
    
        # Change service, make sure  object reeturned
        $svc = Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -PassThru @installServiceParams
        $svc | Should Not BeNullOrEmpty
        $svc.Name | Should Be $serviceName
    
        # No changes, service still returned
        $svc = Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -PassThru @installServiceParams
        $svc | Should Not BeNullOrEmpty
        $svc.Name | Should Be $serviceName
    }
    
    It 'should set description' {
        $description = [Guid]::NewGuid()
        $output = Install-Service -Name $serviceName -Path $servicePath -Description $description @installServiceParams
        $output | Should BeNullOrEmpty
    
        $svc = Get-Service -Name $serviceName
        $svc | Should Not BeNullOrEmpty
        $svc.Description | Should Be $description
    
        $description = [Guid]::NewGuid().ToString()
        $output = Install-Service -Name $serviceName -Path $servicePath -Description $description @installServiceParams
        $output | Should BeNullOrEmpty
    
        $svc = Get-Service -Name $serviceName
        $svc | Should Not BeNullOrEmpty
        $svc.Description | Should Be $description
    
        # Should preserve the description
        $output = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $output | Should BeNullOrEmpty
        $svc.Description | Should Be $description
    }
    
    It 'should set display name' {
        $displayName = [Guid]::NewGuid().ToString()
        $output = Install-Service -Name $serviceName -Path $servicePath -DisplayName $displayName @installServiceParams
        $output | Should BeNullOrEmpty
    
        $svc = Get-Service -Name $serviceName
        $svc | Should Not BeNullOrEmpty
        $svc.DisplayName | Should Be $displayName
    
        $displayName = [Guid]::NewGuid().ToString()
        $output = Install-Service -Name $serviceName -Path $servicePath -DisplayName $displayName @installServiceParams
        $output | Should BeNullOrEmpty
    
        $svc = Get-Service -Name $serviceName
        $svc | Should Not BeNullOrEmpty
        $svc.DisplayName | Should Be $displayName
    
        $output = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $output | Should BeNullOrEmpty
    
        $svc = Get-Service -Name $serviceName
        $svc | Should Not BeNullOrEmpty
        $svc.DisplayName | Should Be $serviceName
    
    }
    
    It 'should switch from built-in account to custom acount with credential' {
        Install-Service -Name $serviceName -Path $servicePath @installServiceParams
        $service = Assert-ServiceInstalled
        $service.UserName | Should Be $defaultServiceAccountName
        Install-Service -Name $serviceName -Path $servicePath -Credential $serviceCredential
        $service = Assert-ServiceInstalled
        (Resolve-IdentityName $service.UserName) | Should Be (Resolve-IdentityName $serviceCredential.UserName)
    }

}

GivenTheServiceIsNotInstalled
