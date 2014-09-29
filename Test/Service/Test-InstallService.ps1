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
$serviceName = ''
$serviceAcct = 'CrbnInstllSvcTstAcct'
$servicePassword = [Guid]::NewGuid().ToString().Substring(0,14)
$installServiceParams = @{ }
$startedAt = Get-Date

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $serviceName = 'CarbonTestService' + ([Guid]::NewGuid().ToString())
    Install-User -Username $serviceAcct -Password $servicePassword -Description "Account for testing the Carbon Install-Service function."
    $startedAt = Get-Date
    $startedAt = $startedAt.AddSeconds(-1)
}

function Stop-Test
{
    Uninstall-Service $serviceName
    Uninstall-User $serviceAcct
    $now = Get-Date
    if( $now.Second -ne $startedAt.Second )
    {
        Start-Sleep -Milliseconds (1000 - $now.Millisecond)
    }
}

function Test-ShouldInstallService
{
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    $service = Assert-ServiceInstalled 
    Assert-Equal 'Running' $service.Status
    Assert-Equal $serviceName $service.Name
    Assert-Equal $serviceName $service.DisplayName
    Assert-Equal 'Automatic' $service.StartMode
    Assert-Equal 'NT AUTHORITY\NetworkService' $service.UserName
}


function Test-ShouldReinstallUnchangedServiceWithForceParameter
{
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams -Force
    Assert-ServiceReInstalled
}

function Test-ShouldNotInstallServiceTwice
{
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams
    Install-Service -Name $serviceName -Path $servicePath @installServiceParams

    do
    {
        [object[]]$events = Get-EventLog -LogName 'System' `
                                         -After $startedAt `
                                         -Source 'Service Control Manager' `
                                         -EntryType Information |
                                Where-Object { $_.EventID -eq 7045 }
        if( -not $events )
        {
            Start-Sleep -Milliseconds 100
        }
    }
    while( -not $events )
                                     
    Assert-NotNull $events
    Assert-Equal 1 $events.Count
}

function Test-ShouldReInstallServiceIfPathChanges
{
    $tempDir = New-TempDir -Prefix 'Carbon+Test-InstallService'
    Copy-Item -Path $servicePath -Destination $tempDir
    $changedServicePath = Join-Path -Path $tempDir -ChildPath (Split-Path -Leaf -Path $servicePath) -Resolve

    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $changedServicePath
    Assert-ServiceReinstalled 
}

function Test-ShouldReinstallServiceIfStartupTypeChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -StartupType Manual
    Start-Service -Name $serviceName  # So our assertion below passes.
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfResetFailureCountChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -ResetFailureCount 60
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfFirstFailureChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart'
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfSecondFailureChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -OnSecondFailure 'Restart'
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfThirdFailureChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -OnThirdFailure 'Restart'
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfRestartDelayChanges
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart'
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Restart' -RestartDelay (1000*60*5)
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfRebootDelayChanges
{
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Reboot'
    Install-Service -Name $serviceName -Path $servicePath -OnFirstFailure 'Reboot' -RebootDelay (1000*60*5)
    Assert-ServiceReInstalled
}

function Test-ShouldReinstallServiceIfDependenciesChange
{
    $service2Name = '{0}-2' -f $serviceName
    Install-Service -Name $service2Name -Path $servicePath

    try
    {
        $service3Name = '{0}-3' -f $serviceName
        Install-Service -Name $service3Name -Path $servicePath
        $now = Get-Date
        Start-Sleep -Milliseconds (1000 - $now.Millisecond)
        $startedAt = Get-Date
        $startedAt = $startedAt.AddSeconds(-1)

        try
        {
            Install-Service -Name $serviceName -Path $servicePath
            Install-Service -Name $serviceName -Path $servicePath -Dependency $service2Name
            Assert-ServiceReInstalled

            Install-Service -Name $serviceName -Path $servicePath -Dependency $service3Name
            Assert-ServiceReInstalled
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

function Test-ShouldReinstallServiceIfUsernameChanges
{
    Install-Service -Name $serviceName -Path $servicePath
    Install-Service -Name $serviceName -Path $servicePath -Username 'SYSTEM'
    Assert-ServiceReInstalled
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
    Assert-Equal 'Stopped' $service.Status
    Assert-HasPermissionsOnServiceExecutable "$($env:ComputerName)\$serviceAcct" $newServicePath
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
    $failureActionBytes = (Get-ItemProperty "hklm:\System\ControlSet001\services\$serviceName\" -Name FailureActions).FailureActions
    $failureAction = [Convert]::ToBase64String( $failureActionBytes )
    Assert-Equal "AAAAAAAAAAAAAAAAAwAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" $failureAction
    
    Install-Service -Name $serviceName -Path $servicePath -ResetFailureCount 1 -OnFirstFailure Restart -OnSecondFailure Restart -OnThirdFailure Reboot -RestartDelay 18000 -RebootDelay 30000 @installServiceParams
    $failureActionBytes = (Get-ItemProperty "hklm:\System\ControlSet001\services\$serviceName\" -Name FailureActions).FailureActions
    $updatedFailureAction = [Convert]::ToBase64String( $failureActionBytes )

    # First four bytes are reset failure count period.  
    Assert-Equal $failureActionBytes[0] 1 # The reset failure count

    Assert-Equal 1 $failureActionBytes[20] # Restart on first failure
    # Bytes 24-27 are the delay in milliseconds
    $delay = [int]$failureActionBytes[24]
    $delay = $delay -bor ([int]$failureActionBytes[25] * 256)
    Assert-Equal 18000 $delay 

    Assert-Equal 1 $failureActionBytes[28] # Restart on second failure
    # Bytes 32-35 are the delay in milliseconds
    $delay = [int]$failureActionBytes[32]
    $delay = $delay -bor ([int]$failureActionBytes[33] * 256)
    Assert-Equal 18000 $delay 

    Assert-Equal 2 $failureActionBytes[36] # Reboot on third failure
    # Bytes 40-43 are the delay in milliseconds
    $delay = [int]$failureActionBytes[40]
    $delay = $delay -bor ([int]$failureActionBytes[41] * 256)
    Assert-Equal 30000 $delay 

    Assert-NotEqual $updatedFailureAction $failureAction
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

function Assert-ServiceInstalled
{
    $service = Get-Service $serviceName
    Assert-NotNull $service
    return $service
}

function Assert-HasPermissionsOnServiceExecutable($Identity, $Path)
{
    $acl = Get-Acl $Path |
            Select-Object -ExpandProperty Access |
            Where-Object { 
                $_.IdentityReference -eq $Identity -and (($_.FileSystemRights -band [Security.AccessControl.FileSystemRights]::ReadAndExecute) -eq 'ReadAndExecute') 
            }

    Assert-Null $acl "'$Identity' didn't have full control to '$Path'."
            
}

function Assert-ServiceReInstalled
{
    $maxTries = 10
    $tryNum = 0
    do
    {
        [object[]]$events = Get-EventLog -LogName 'System' `
                                         -After $startedAt `
                                         -Source 'Service Control Manager' `
                                         -EntryType Information |
                                Where-Object { $_.EventID -eq 7036 -or $_.EventID -eq 7045 }

        if( -not $events-or $events.Count -lt 4)
        {
            Start-Sleep -Milliseconds 100
        }
    }
    while( $tryNum++ -lt $maxTries -and (-not $events -or $events.Count -lt 4) )
                                     
    Assert-NotNull $events
    Assert-Equal 4 $events.Count
    Assert-Like $events[0].Message '*entered the running state*'
    Assert-Like $events[1].Message '*entered the stopped state*'
    Assert-Like $events[2].Message '*entered the running state*'
    Assert-Like $events[3].Message '*was installed*'
}