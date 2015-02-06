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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force
$credential = New-Credential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
$tempDir = $null
$servicePath = $null
$serviceName = 'CarbonDscTestService'

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'Service'
    Install-User -UserName $credential.UserName -Password $credential.GetNetworkCredential().Password
}

function Start-Test
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Service\NoOpService.exe') -Destination $tempDir
    $servicePath = Join-Path -Path $tempDir -ChildPath 'NoOpService.exe'
}

function Stop-Test
{
    Uninstall-Service -Name $serviceName
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldGetExistingServices
{
    Get-Service | ForEach-Object {
        $resource = Get-TargetResource -Name $_.Name
        Assert-NoError
        Assert-NotNull $resource
        Assert-Equal $_.Name $resource.Name
        Assert-Equal $_.Path $resource.Path
        Assert-Equal $_.StartMode $resource.StartupType
        Assert-Equal $_.FirstFailure $resource.OnFirstFailure
        Assert-Equal $_.SecondFailure $resource.OnSecondFailure
        Assert-Equal $_.ThirdFailure $resource.OnThirdFailure
        Assert-Equal $_.ResetPeriod $resource.ResetFailureCount
        Assert-Equal $_.RestartDelay $resource.RestartDelay
        Assert-Equal $_.RebootDelay $resource.RebootDelay
        Assert-Equal $_.FailureProgram $resource.Command
        Assert-Equal $_.RunCommandDelay $resource.RunCommandDelay
        Assert-Equal (($_.ServicesDependedOn | Select-Object -ExpandProperty 'Name') -join ',') ($resource.Dependency -join ',') $_.Name
        if( (Test-Identity -Name $_.UserName) )
        {
            Assert-Equal (Resolve-Identity -Name $_.UserName).FullName $resource.UserName
        }
        else
        {
            Assert-Equal $_.UserName $resource.UserName
        }
        Assert-Null $resource.Credential
        Assert-DscResourcePresent $resource
    }
}

function Test-ShouldGetNonExistentService
{
    $name = [Guid]::NewGuid().ToString()
    $resource = Get-TargetResource -Name $name

    Assert-NoError
    Assert-NotNull $resource
    Assert-Equal $name $resource.Name
    Assert-Null $resource.Path
    Assert-Null $resource.StartupType
    Assert-Null $resource.OnFirstFailure
    Assert-Null $resource.OnSecondFailure
    Assert-Null $resource.OnThirdFailure
    Assert-Null $resource.ResetFailureCount
    Assert-Null $resource.RestartDelay
    Assert-Null $resource.RebootDelay
    Assert-Null $resource.Dependency
    Assert-Null $resource.Command
    Assert-Null $resource.RunCommandDelay
    Assert-Null $resource.UserName
    Assert-Null $resource.Credential
    Assert-DscResourceAbsent $resource
}
    
function Test-ShouldInstallService
{
    Set-TargetResource -Path $servicePath -Name $serviceName -Ensure Present
    Assert-NoError
    $resource = Get-TargetResource -Name $serviceName
    Assert-NotNull $resource
    Assert-Equal $serviceName $resource.Name
    Assert-Equal $servicePath $resource.Path
    Assert-Equal 'Automatic' $resource.StartupType
    Assert-Equal 'TakeNoAction' $resource.OnFirstFailure
    Assert-Equal 'TakeNoAction' $resource.OnSecondFailure
    Assert-Equal 'TakeNoAction' $resource.OnThirdFailure
    Assert-Equal 0 $resource.ResetFailureCount
    Assert-Equal 0 $resource.RestartDelay
    Assert-Equal 0 $resource.RebootDelay
    Assert-Null $resource.Dependency
    Assert-Null $resource.Command
    Assert-Equal 0 $resource.RunCommandDelay
    Assert-Equal 'NT AUTHORITY\NETWORK SERVICE' $resource.UserName
    Assert-Null $resource.Credential
    Assert-DscResourcePresent $resource
}

function Test-ShouldInstallServiceWithAllOptions
{
    Set-TargetResource -Path $servicePath `
                       -Name $serviceName `
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
                       -Credential $credential
    Assert-NoError
    $resource = Get-TargetResource -Name $serviceName
    Assert-NotNull $resource
    Assert-Equal $serviceName $resource.Name
    Assert-Equal $servicePath $resource.Path
    Assert-Equal 'Manual' $resource.StartupType
    Assert-Equal 'RunCommand' $resource.OnFirstFailure
    Assert-Equal 'Restart' $resource.OnSecondFailure
    Assert-Equal 'Reboot' $resource.OnThirdFailure
    Assert-Equal (60*60*24*2) $resource.ResetFailureCount
    Assert-Equal (1000*60*5) $resource.RestartDelay
    Assert-Equal (1000*60*10) $resource.RebootDelay
    Assert-Equal 'W3SVC' $resource.Dependency
    Assert-Equal 'fubar.exe' $resource.Command 
    Assert-Equal (60*1000) $resource.RunCommandDelay
    Assert-Equal (Resolve-Identity -Name $credential.UserName).FullName $resource.UserName
    Assert-Null $resource.Credential
    Assert-DscResourcePresent $resource    
}

function Test-ShouldUninstallService
{
    Set-TargetResource -Name $serviceName -Path $servicePath -Ensure Present
    Assert-NoError
    Assert-DscResourcePresent (Get-TargetResource -Name $serviceName)
    Set-TargetResource -Name $serviceName -Path $servicePath -Ensure Absent
    Assert-NoError
    Assert-DscResourceAbsent (Get-TargetResource -Name $serviceName)
}

function Test-ShouldRequirePathWhenInstallingService
{
    Set-TargetResource -Name $serviceName -Ensure Present -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'Path\b.*\bmandatory'
    Assert-DscResourceAbsent (Get-TargetResource -Name $serviceName)
}

function Test-ShouldTestExistingServices
{
    Get-Service | ForEach-Object {
        Assert-True (Test-TargetResource -Name $_.Name -Ensure Present)
        Assert-False (Test-TargetResource -Name $_.Name -Ensure Absent)
    }
}

function Test-ShouldTestMissingServices
{
    Assert-True (Test-TargetResource -Name $serviceName -Ensure Absent)
    Assert-False (Test-TargetResource -Name $serviceName -Ensure Present)
}

function Test-ShouldTestOnCredentials
{
    Set-TargetResource -Name $serviceName -Path $servicePath -Credential $credential -Ensure Present
    Assert-True (Test-TargetResource -Name $serviceName -Path $servicePath -Credential $credential -Ensure Present)
}

function Test-ShouldTestOnProperties
{
    Set-TargetResource -Name $serviceName -Path $servicePath -Command 'fubar.exe' -Ensure Present
    $testParams = @{ Name = $serviceName; }
    Assert-True (Test-TargetResource @testParams -Path $servicePath -Ensure Present)
    Assert-False (Test-TargetResource @testParams -Path 'C:\fubar.exe' -Ensure Present)

    Assert-True (Test-TargetResource @testParams -StartupType Automatic -Ensure Present)
    Assert-False (Test-TargetResource @testParams -StartupType Manual -Ensure Present)

    Assert-True (Test-TargetResource @testParams -OnFirstFailure TakeNoAction -Ensure Present)
    Assert-False (Test-TargetResource @testParams -OnFirstFailure Restart -Ensure Present)

    Assert-True (Test-TargetResource @testParams -OnSecondFailure TakeNoAction -Ensure Present)
    Assert-False (Test-TargetResource @testParams -OnSecondFailure Restart -Ensure Present)

    Assert-True (Test-TargetResource @testParams -OnThirdFailure TakeNoAction -Ensure Present)
    Assert-False (Test-TargetResource @testParams -OnThirdFailure Restart -Ensure Present)

    Assert-True (Test-TargetResource @testParams -ResetFailureCount 0 -Ensure Present)
    Assert-False (Test-TargetResource @testParams -ResetFailureCount 50 -Ensure Present)

    Assert-True (Test-TargetResource @testParams -RestartDelay 0 -Ensure Present)
    Assert-False (Test-TargetResource @testParams -RestartDelay 50 -Ensure Present)

    Assert-True (Test-TargetResource @testParams -RebootDelay 0 -Ensure Present)
    Assert-False (Test-TargetResource @testParams -RebootDelay 50 -Ensure Present)

    Assert-True (Test-TargetResource @testParams -Dependency @() -Ensure Present)
    Assert-False (Test-TargetResource @testParams -Dependency @( 'W3SVC' ) -Ensure Present)

    Assert-True (Test-TargetResource @testParams -Command 'fubar.exe' -Ensure Present)
    Assert-False (Test-TargetResource @testParams -Command 'fubar2.exe' -Ensure Present)

    Assert-True (Test-TargetResource @testParams -RunCommandDelay 0 -Ensure Present)
    Assert-False (Test-TargetResource @testParams -RunCommandDelay 1000 -Ensure Present)

    Assert-True (Test-TargetResource @testParams -UserName 'NetworkService' -Ensure Present)
    Assert-False (Test-TargetResource @testParams -Credential $credential -Ensure Present)
}


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
            Name = $serviceName;
            Path = $servicePath;
            Ensure = $Ensure;
        }
    }
}

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError
    Assert-True (Test-TargetResource -Name $serviceName -Ensure 'Present')
    Assert-False (Test-TargetResource -Name $serviceName -Ensure 'Absent')

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError
    Assert-False (Test-TargetResource -Name $serviceName -Ensure 'Present')
    Assert-True (Test-TargetResource -Name $serviceName -Ensure 'Absent')
}
