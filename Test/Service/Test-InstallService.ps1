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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    $serviceName = 'CarbonTestService' + ([Guid]::NewGuid().ToString())
    Install-User -Username $serviceAcct -Password $servicePassword -Description "Account for testing the Carbon Install-Service function."
}

function Stop-Test
{
    Uninstall-Service $serviceName
    Uninstall-User $serviceAcct
}

function Test-ShouldInstallService
{
    Install-Service -Name $serviceName -Path $servicePath
    $service = Assert-ServiceInstalled 
    Assert-Equal 'Running' $service.Status
    Assert-Equal $serviceName $service.Name
    Assert-Equal $serviceName $service.DisplayName
    Assert-Equal 'Automatic' $service.StartMode
    Assert-Equal (Resolve-Identity -Name 'NT AUTHORITY\NetworkService').FullName $service.UserName
}

function Test-ShouldUpdateServiceProperties
{
    Install-Service -Name $serviceName -Path $servicePath
    $service = Assert-ServiceInstalled
    
    $tempDir = New-TempDir
    $newServicePath = Join-Path $TempDir NoOpService.exe
    Copy-Item $servicePath $newServicePath
    Install-Service -Name $serviceName -Path $newServicePath -StartupType 'Manual' -Username $serviceAcct -Password $servicePassword
    $service = Assert-ServiceInstalled
    Assert-Equal 'Manual' $service.StartMode
    Assert-Equal ".\$serviceAcct" $service.UserName
    Assert-Equal 'Stopped' $service.Status
    Assert-HasPermissionsOnServiceExecutable "$($env:ComputerName)\$serviceAcct" $newServicePath
}

function Test-ShouldSupportWhatIf
{
    Install-Service -Name $serviceName -Path $servicePath -WhatIf
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    Assert-Null $service
}

function Test-ShouldSetStartupType
{
    Install-Service -Name $serviceName -Path $servicePath -StartupType 'Manual'
    $service = Assert-ServiceInstalled
    Assert-Equal 'Manual' $service.StartMode
}

function Test-ShouldSetCustomAccount
{
    Install-Service -Name $serviceName -Path $servicePath -UserName $serviceAcct -Password $servicePassword
    $service = Assert-ServiceInstalled
    Assert-Equal ".\$($serviceAcct)" $service.UserName
    $service = Get-Service $serviceName
    Assert-Equal 'Running' $service.Status
}

function Test-ShouldSetCustomAccountWithNoPassword
{
    $Error.Clear()
    Install-Service -Name $serviceName -Path $servicePath -UserName $serviceAcct -ErrorAction SilentlyContinue
    Assert-GreaterThan $Error.Count 0
    $service = Assert-ServiceInstalled
    Assert-Equal ".\$($serviceAcct)" $service.UserName
    $service = Get-Service $serviceName
    Assert-Equal 'Stopped' $service.Status
}

function Test-ShouldSetFailureActions
{
    Install-Service -Name $serviceName -Path $servicePath
    $service = Assert-ServiceInstalled
    $failureActionBytes = (Get-ItemProperty "hklm:\System\ControlSet001\services\$serviceName\" -Name FailureActions).FailureActions
    $failureAction = [Convert]::ToBase64String( $failureActionBytes )
    Assert-Equal "AAAAAAAAAAAAAAAAAwAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" $failureAction
    
    Install-Service -Name $serviceName -Path $servicePath -ResetFailureCount 1 -OnFirstFailure Restart -OnSecondFailure Restart -OnThirdFailure Reboot -RestartDelay 18000 -RebootDelay 30000
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
    Install-Service -Name $serviceName -Path $servicePath -Dependencies $firstService.Name,$secondService.Name
    $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $firstService.Name
    Assert-ContainsLike $dependencies "SERVICE_NAME: $serviceName"
    $dependencies = & (Join-Path $env:SystemRoot system32\sc.exe) enumdepend $secondService.Name
    Assert-ContainsLike $dependencies "SERVICE_NAME: $serviceName"
}

function Test-ShouldTestDependenciesExist
{
    $error.Clear()
    Install-Service -Name $serviceName -Path $servicePath -Dependencies IAmAServiceThatDoesNotExist -ErrorAction SilentlyContinue
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
        Install-Service -Name $serviceName -Path $path
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
