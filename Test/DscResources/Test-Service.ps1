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
$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()
$tempDir = $null

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'Service'
    Install-User -UserName $UserName -Password $Password
}

function Start-Test
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null
}

function Stop-Test
{
    if( (Test-Path -Path $Path -PathType Container) )
    {
        Remove-Item -Path $Path
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
        Assert-Equal (($_.ServicesDependedOn | Select-Object -ExpandProperty 'Name') -join ',') ($resource.Dependency -join ',') $_.Name
        Assert-Equal $_.UserName $resource.UserName
        Assert-Null $resource.Password
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
    Assert-Null $resource.UserName
    Assert-Null $resource.Password
    Assert-DscResourceAbsent $resource
}
    
function Test-ShouldInstallService
{
}