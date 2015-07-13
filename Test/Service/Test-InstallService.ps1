# Copyright 2012 Aaron Jensen
# 
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

$servicePath = Join-Path $TestDir NoOpService.exe
$serviceName = 'CarbonTestService'
$serviceAcct = 'CrbnInstllSvcTstAcct'
$servicePassword = [Guid]::NewGuid().ToString().Substring(0,14)
$installServiceParams = @{ }
$startedAt = Get-Date

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    Install-User -Username $serviceAcct -Password $servicePassword -Description "Account for testing the Carbon Install-Service function."
}

function Stop-TestFixture
{
    Uninstall-Service $serviceName
}

function Start-Test
{
    $startedAt = Get-Date
    $startedAt = $startedAt.AddSeconds(-1)
    Uninstall-Service $serviceName
}

function Stop-Test
{
    Uninstall-Service $serviceName
}

function Test-ShouldInstallService
{
    $result = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    Assert-Null $result
    $service = Assert-ServiceInstalled 
    Assert-Equal 'Running' $service.Status
    Assert-Equal $serviceName $service.Name
    Assert-Equal $serviceName $service.DisplayName
    Assert-Equal 'Automatic' $service.StartMode
    Assert-Equal (Resolve-IdentityName -Name 'NT AUTHORITY\NetworkService') $service.UserName
}


function Test-ShouldReinstallUnchangedServiceWithForceParameter
{
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

        if( $events -and $events.Count -ge 4 )
        {
            if( $events[0].Message -like '*entered the running state*' -and 
                $events[1].Message -like '*entered the stopped state*' -and 
                $events[2].Message -like '*entered the running state*' -and
                $events[3].Message -like '*was installed*' )
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
                                   
    Assert-True $serviceReinstalled ('service not reinstalled')                                     
}

function Test-ShouldNotInstallServiceTwice
{
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    $now = Get-Date
    Start-Sleep -Milliseconds (1001 - $now.Millisecond)

    Stop-Service -Name $serviceName
    $result = Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    Assert-Null $result
    # This could break if Install-Service is ever updated to not start a stopped service
    Assert-Equal 'Stopped' (Get-Service -Name $serviceName).Status
}

function Test-ShouldNotInstallServiceWithSpaceInItsPath
{
    $tempDir = New-TempDirectory -Prefix 'Carbon Test Install Service'
    Copy-Item -Path $servicePath -Destination $tempDir
    try
    {
        $servicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath)

        $svc = Install-Service -Name $serviceName -Path $servicePath
        Assert-Null $svc
        $svc = Install-Service -Name $serviceName -Path $servicePath
        Assert-Null $svc
    }
    finally
    {
        Uninstall-Service -Name $serviceName
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

function Test-ShouldReInstallServiceIfPathChanges
{
    $tempDir = New-TempDir -Prefix 'Carbon+Test-InstallService'
    Copy-Item -Path $servicePath -Destination $tempDir
    $changedServicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath) -Resolve

    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $changedServicePath
    Assert-Equal $changedServicePath (Get-ServiceConfiguration -Name $serviceName).Path
}

function Test-ShouldInstallServiceWithArgumentList
{
    $tempDir = New-TempDirectory -Prefix 'Carbon Test Install Service'
    Copy-Item -Path $servicePath -Destination $tempDir
    try
    {
        $servicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath)

        $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fu bar"
        Assert-Null $svc
        Assert-NoError
        $svcConfig = Get-ServiceConfiguration -Name $serviceName
        Assert-Equal ('"{0}" -k "Fu bar"' -f $servicePath) $svcConfig.Path
    }
    finally
    {
        Uninstall-Service -Name $serviceName
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

function Test-ShouldReinstallServiceIfArgumentListChanges
{
    $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fu bar"
    Assert-Null $svc
    Assert-NoError
    $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fubar"
    Assert-NoError
    Assert-Null $svc
    $svc = Install-Service -Name $serviceName -Path $servicePath -ArgumentList "-k","Fubar"
    Assert-Null $svc
}

function Test-ShouldReinstallServiceIfStartupTypeChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -StartupType Manual
    Assert-Equal 'Manual' (Get-Service -Name $serviceName).StartMode
}

function Test-ShouldReinstallServiceIfResetFailureCountChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -ResetFailureCount 60
    Assert-Equal 60 (Get-ServiceConfiguration -Name $serviceName).ResetPeriod
}

function Test-ShouldReinstallServiceIfFirstFailureChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart'
    Assert-Equal 'Restart' (Get-ServiceConfiguration -Name $serviceName).FirstFailure
}

function Test-ShouldReinstallServiceIfSecondFailureChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -OnSecondFailure 'Restart'
    Assert-Equal 'Restart' (Get-ServiceConfiguration -Name $serviceName).SecondFailure
}

function Test-ShouldReinstallServiceIfThirdFailureChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -OnThirdFailure 'Restart'
    Assert-Equal 'Restart' (Get-ServiceConfiguration -Name $serviceName).ThirdFailure
}

function Test-ShouldReinstallServiceIfRestartDelayChanges
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart'
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart' -RestartDelay (1000*60*5)
    Assert-Equal 5 (Get-ServiceConfiguration -Name $serviceName).RestartDelayMinutes
}

function Test-ShouldReinstallServiceIfRebootDelayChanges
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Reboot'
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Reboot' -RebootDelay (1000*60*5)
    Assert-Equal 5 (Get-ServiceConfiguration -Name $serviceName).RebootDelayMinutes
}

function Test-ShouldReinstallServiceIfCommandChanges
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -Command 'fubar'
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -command 'fubar2'
    Assert-Equal 'fubar2' (Get-ServiceConfiguration -Name $serviceName).FailureProgram
}

function Test-ShouldReinstallServiceIfRunDelayChanges
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -Command 'fubar' -RunCommandDelay 60000
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -command 'fubar' -RunCommandDelay 30000
    Assert-Equal 30000 (Get-ServiceConfiguration -Name $serviceName).RunCommandDelay
}

function Test-ShouldReinstallServiceIfDependenciesChange
{
    $service2Name = '{0}-2' -f $serviceName
    Install-Service -Name $service2Name -Path $servicePath

    try
    {
        $service3Name = '{0}-3' -f $serviceName
        Install-Service -Name $service3Name -Path $servicePath

        try
        {
            Install-Service -Name $serviceName -Path $servicePath
            Install-Service -Name $serviceName -Path $servicePath -Dependency $service2Name
            Assert-Equal $service2Name (Get-Service -Name $serviceName).ServicesDependedOn[0].Name

            Install-Service -Name $serviceName -Path $servicePath -Dependency $service3Name
            Assert-Equal $service3Name (Get-Service -Name $serviceName).ServicesDependedOn[0].Name
        }
        finally
        {
            Uninstall-Service $serviceName
            Uninstall-Service $service3Name
        }
    }
    finally
    {
        Uninstall-Service -Name $service2Name -Verbose
    }
}

function Test-ShouldReinstallServiceIfUsernameChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -Username 'SYSTEM'
    Assert-Equal 'NT AUTHORITY\SYSTEM' (Get-ServiceConfiguration -Name $serviceName).UserName
}



function Test-ShouldUpdateServiceProperties
{
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    $service = Assert-ServiceInstalled
    
    $tempDir = New-TempDir
    $newServicePath = Join-Path $TempDir NoOpService.exe
    Copy-Item $servicePath $newServicePath
    Install-Service -Name $serviceName -Path $newServicePath -StartupType 'Manual' -Username $serviceAcct -Password $servicePassword @installServiceParams
    $service = Assert-ServiceInstalled
    Assert-Equal 'Manual' $service.StartMode
    Assert-Equal ".\$serviceAcct" $service.UserName
    Assert-Equal 'Running' $service.Status
    Assert-HasPermissionsOnServiceExecutable $serviceAcct $newServicePath
}

function Test-ShouldSupportWhatIf
{
    Install-Service -Name $serviceName -Path $servicePath -WhatIf @installServiceParams
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    Assert-Null $service
}

function Test-ShouldSetStartupType
{
    Install-Service -Name $serviceName -Path $servicePath -StartupType 'Manual' @installServiceParams
    $service = Assert-ServiceInstalled
    Assert-Equal 'Manual' $service.StartMode
}

function Test-ShouldSetCustomAccount
{
    Install-Service -Name $serviceName -Path $servicePath -UserName $serviceAcct -Password $servicePassword @installServiceParams
    $service = Assert-ServiceInstalled
    Assert-Equal ".\$($serviceAcct)" $service.UserName
    $service = Get-Service $serviceName
    Assert-Equal 'Running' $service.Status
}

function Test-ShouldSetCustomAccountWithNoPassword
{
    $Error.Clear()
    Install-Service -Name $serviceName -Path $servicePath -UserName $serviceAcct -ErrorAction SilentlyContinue @installServiceParams
    Assert-GreaterThan $Error.Count 0
    $service = Assert-ServiceInstalled
    Assert-Equal ".\$($serviceAcct)" $service.UserName
    $service = Get-Service $serviceName
    Assert-Equal 'Stopped' $service.Status
}

function Test-ShouldSetFailureActions
{
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    $service = Assert-ServiceInstalled
    $config = Get-Serviceconfiguration -Name $serviceName
    Assert-Equal 'TakeNoAction' $config.FirstFailure
    Assert-Equal 'TakeNoAction' $config.SecondFailure
    Assert-Equal 'TakeNoAction' $config.ThirdFailure
    Assert-Equal 0 $config.RebootDelay
    Assert-Equal 0 $config.ResetPeriod
    Assert-Equal 0 $config.RestartDelay

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
    Assert-Equal 'RunCommand' $config.FirstFailure
    Assert-Equal 'echo Fubar!' $config.FailureProgram
    Assert-Equal 'Restart' $config.SecondFailure
    Assert-Equal 'Reboot' $config.ThirdFailure
    Assert-Equal 30000 $config.RebootDelay
    Assert-Equal 0 $config.RebootDelayMinutes
    Assert-Equal 1 $config.ResetPeriod
    Assert-Equal 0 $config.ResetPeriodDays
    Assert-Equal 18000 $config.RestartDelay
    Assert-Equal 0 $config.RestartDelayMinutes
    Assert-Equal 6000 $config.RunCommandDelay
    Assert-Equal 0 $config.RunCommandDelayMinutes
}

function Test-ShouldClearCommand
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure RunCommand -Command 'fubar'
    $config = Get-ServiceConfiguration -Name $serviceName
    Assert-Equal 'fubar' $config.FailureProgram
    Assert-Equal 0 $config.RunCommandDelay

    Install-Service -Name $serviceName -Path $servicePath
    $config = Get-ServiceConfiguration -Name $serviceName
    Assert-Null $config.FailureProgram
}

function Test-ShouldSetDependencies
{
    $firstService = (Get-Service)[0]
    $secondService = (Get-Service)[1]
    Install-Service -Name $serviceName -Path $servicePath -Dependencies $firstService.Name,$secondService.Name @installServiceParams
    $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $firstService.Name
    Assert-ContainsLike $dependencies "SERVICE_NAME: $serviceName"
    $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $secondService.Name
    Assert-ContainsLike $dependencies "SERVICE_NAME: $serviceName"
}

function Test-ShouldTestDependenciesExist
{
    $error.Clear()
    Install-Service -Name $serviceName -Path $servicePath -Dependencies IAmAServiceThatDoesNotExist -ErrorAction SilentlyContinue @installServiceParams
    Assert-Equal 1 $error.Count
    Assert-False (Test-Service -Name $serviceName)
}

function Test-ShouldInstallServiceWithRelativePath
{
    $parentDir = Split-Path -Parent -Path $TestDir
    $dirName = Split-Path -Leaf -Path $TestDir
    $serviceExeName = Split-Path -Leaf -Path $servicePath
    $path = ".\{0}\{1}" -f $dirName,$serviceExeName

    Push-Location -Path $parentDir
    try
    {
        Install-Service -Name $serviceName -Path $path @installServiceParams
        $service = Assert-ServiceInstalled 
        $svc = Get-WmiObject -Class 'Win32_Service' -Filter ('Name = "{0}"' -f $serviceName)
        Assert-Equal $servicePath $svc.PathName
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldClearDependencies
{
    $service2Name = '{0}-2' -f $serviceName
    try
    {
        Install-Service -Name $service2Name -Path $servicePath
        Install-Service -Name $serviceName -Path $servicePath -Dependency $service2Name

        $service = Get-Service -Name $serviceName
        Assert-Equal 1 $service.ServicesDependedOn.Length
        Assert-Equal $service2Name $service.ServicesDependedOn[0].Name

        Install-Service -Name $serviceName -Path $servicePath
        $service = Get-Service -Name $serviceName
        Assert-Equal 0 $service.ServicesDependedOn.Length
    }
    finally
    {
        Uninstall-Service -Name $service2Name
    }
}

function Test-ShouldNotStartManualService
{
    Install-Service -Name $serviceName -Path $servicePath -StartupType Manual
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
    Assert-Equal 'Stopped' $service.Status

    Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -Force
    $service = Get-Service -Name $serviceName
    Assert-Equal 'Stopped' $service.Status

    Start-Service -Name $serviceName
    Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -Force
    $service = Get-Service -Name $serviceName
    Assert-Equal 'Running' $service.Status
}

function Test-ShouldNotStartDisabledService
{
    Install-Service -Name $serviceName -Path $servicePath -StartupType Disabled
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
    Assert-Equal 'Stopped' $service.Status

    Install-Service -Name $serviceName -Path $servicePath -StartupType Disabled -Force
    $service = Get-Service -Name $serviceName
    Assert-Equal 'Stopped' $service.Status
}

function Test-ShouldStartAStoppedAutomaticService
{
    Install-Service -Name $serviceName -Path $servicePath -StartupType Automatic
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
    Assert-Equal 'Running' $service.Status

    Stop-Service -Name $serviceName
    Install-Service -Name $serviceName -Path $servicePath -StartupType Automatic -Force
    $service = Get-Service -Name $serviceName
    Assert-Equal 'Running' $service.Status
}

function Test-ShouldReturnServiceObject
{
    $svc = Install-Service -Name $serviceName -Path $servicePath -StartupType Automatic -PassThru
    Assert-NotNull $svc
    Assert-Equal $serviceName $svc.Name

    # Change service, make sure  object reeturned
    $svc = Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -PassThru
    Assert-NotNull $svc
    Assert-Equal $serviceName $svc.Name

    # No changes, service still returned
    $svc = Install-Service -Name $serviceName -Path $servicePath -StartupType Manual -PassThru
    Assert-NotNull $svc
    Assert-Equal $serviceName $svc.Name
}


function Assert-ServiceInstalled
{
    $service = Get-Service $serviceName
    Assert-NotNull $service
    return $service
}

function Assert-HasPermissionsOnServiceExecutable($Identity, $Path)
{
    $access = Get-Permission -Path $Path -Identity $Identity
    Assert-NotNull $access "'$Identity' doesn't have any access to '$Path'."
    Assert-Equal ($access.FileSystemRights -band [Security.AccessControl.FileSystemRights]::ReadAndExecute) ([Security.AccessControl.FileSystemRights]::ReadAndExecute) "'$Identity' doesn't have ReadAndExecute on '$Path'."
}
