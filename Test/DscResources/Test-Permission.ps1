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
    Start-CarbonDscTestFixture 'Permission'
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
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldGrantPermissionOnFileSystem
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
    Assert-NoError
    Assert-True (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Exact)
}

function Test-ShouldGrantPermissionWithInheritenceOnFileSystem
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo Container -Ensure Present
    Assert-NoError
    Assert-True (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo Container -Exact)
}

function Test-ShouldGrantPermissionOnRegistry
{
    $keyPath = 'hkcu:\{0}' -f (Split-Path -Leaf -Path $tempDir)
    New-Item -Path $keyPath
    try
    {
        Set-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Ensure Present
        Assert-NoError
        Assert-True (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact)
    }
    finally
    {
        Remove-Item -Path $keyPath
    }
}

function Test-ShouldChangePermission
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present
    Assert-True (Test-Permission -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Exact)
}

function Test-ShouldRevokePermission
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
    Set-TargetResource -Identity $UserName -Path $tempDir -Ensure Absent
    Assert-False (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -Exact)
}

function Test-ShouldRequirePermissionWhenGranting
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Ensure Present -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'mandatory'
    Assert-Null (Get-Permission -Path $tempDir -Identity $UserName)
}

function Test-ShouldGetNoPermission
{
    $resource = Get-TargetResource -Identity $UserName -Path $tempDir
    Assert-NotNull $resource
    Assert-Equal $UserName $resource.Identity
    Assert-Equal $tempDir $resource.Path
    Assert-Empty $resource.Permission
    Assert-Null $resource.ApplyTo
    Assert-DscResourceAbsent $resource
}

function Test-ShouldGetCurrentPermission
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
    $resource = Get-TargetResource -Identity $UserName -Path $tempDir
    Assert-NotNull $resource
    Assert-Equal $UserName $resource.Identity
    Assert-Equal $tempDir $resource.Path
    Assert-Equal 'FullControl' $resource.Permission
    Assert-Equal 'ContainerAndSubContainersAndLeaves' $resource.ApplyTo
    Assert-DscResourcePresent $resource
}

function Test-ShouldGetMultiplePermissions
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read,Write -Ensure Present
    $resource = Get-TargetResource -Identity $UserName -Path $tempDir
    Assert-Is $resource.Permission 'string[]'
    Assert-Equal 'Write,Read' ($resource.Permission -join ',')
}


function Test-ShouldGetCurrentContainerInheritanceFlags
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo SubContainers -Ensure Present
    $resource = Get-TargetResource -Identity $UserName -Path $tempDir
    Assert-NotNull $resource
    Assert-Equal 'SubContainers' $resource.ApplyTo
}

function Test-ShouldTestNoPermission
{
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present)
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Ensure Present)
    Assert-True (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Absent)
    Assert-True (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Ensure Absent)
}

function Test-ShouldTestExistingPermission
{
    Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present
    Assert-True (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -Ensure Present -Verbose)
    Assert-True (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present)
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -Ensure Absent)
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Absent)

    # Now, see what happens if permissions are wrong
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Write -Ensure Present)
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Leaves -Ensure Present)
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Write -Ensure Absent)
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Leaves -Ensure Absent)
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
        Carbon_Permission set
        {
            Identity = $UserName;
            Path = $tempDir;
            Permission = 'Read';
            ApplyTo = 'Container';
            Ensure = $Ensure;
        }
    }
}

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-True (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read' -ApplyTo 'Container' -Ensure 'Present')
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read' -ApplyTo 'Container' -Ensure 'Absent')

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-False (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Ready' -ApplyTo 'Container' -Ensure 'Present')
    Assert-True (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Ready' -ApplyTo 'Container' -Ensure 'Absent')
}
