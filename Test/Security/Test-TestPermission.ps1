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

$tempDir = $null
$identity = 'Administrators'
$dirPath = $null
$filePath = $null
$tempKeyPath = $null
$keyPath = $null
$childKeyPath = $null

function Start-Test
{
    & (Join-Path -Path $TestDir -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
    $tempDir = New-TempDirectoryTree -Prefix 'Carbon-Test-TestPermission' @'
+ Directory
  * File
'@
    $dirPath = Join-Path -Path $tempDir -ChildPath 'Directory'
    $filePath = Join-Path -Path $dirPath -ChildPath 'File'
    Grant-Permission -Identity $identity -Permission ReadAndExecute -Path $dirPath -ApplyTo 'ChildLeaves'

    $tempKeyPath = 'hkcu:\Software\Carbon\Test'
    $keyPath = Join-Path -Path $tempKeyPath -ChildPath 'Test-Permission'
    Install-RegistryKey -Path $keyPath
    $childKeyPath = Join-Path -Path $keyPath -ChildPath 'ChildKey'
    Grant-Permission -Identity $identity -Permission 'ReadKey','WriteKey' -Path $keyPath -ApplyTo 'ChildLeaves'
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
    Remove-Item -Path $tempKeyPath -Recurse
}

function Test-ShouldHandleNonExistentPath
{
    $Error.Clear()
    Assert-Null (Test-Permission -path 'C:\I\Do\Not\Exist' -Identity $identity -Permission 'FullControl' -ErrorAction SilentlyContinue)
    Assert-Equal 2 $Error.Count
}

function Test-ShouldCheckUngrantedPermissionOnFileSystem
{
    Assert-False (Test-Permission -Path $dirPath -Identity $identity -Permission 'Write')
}

function Test-ShouldCheckGrantedPermissionOnFileSystem
{
    Assert-True (Test-Permission -Path $dirPath -Identity $identity -Permission 'Read')
}

function Test-ShouldCheckExactPartialPermissionOnFileSystem
{
    Assert-False (Test-Permission -Path $dirPath -Identity $identity -Permission 'Read' -Exact)
}

function Test-ShouldCheckExactPermissionOnFileSystem
{
    Assert-True (Test-Permission -Path $dirPath -Identity $identity -Permission 'ReadAndExecute','Synchronize' -Exact)
}

function Test-ShouldExcludeInheritedPermission
{
    Assert-False (Test-Permission -Path $filePath -Identity $identity -Permission 'ReadAndExecute')
}

function Test-ShouldIncludeInheritedPermission
{
    Assert-True (Test-Permission -Path $filePath -Identity $identity -Permission 'ReadAndExecute' -Inherited)
}

function Test-ShouldExcludeInheritedPartialPermission
{
    Assert-False (Test-Permission -Path $filePath -Identity $identity -Permission 'ReadAndExecute','Synchronize' -Exact)
}

function Test-ShouldIncludeInheritedExactPermission
{
    Assert-True (Test-Permission -Path $filePath -Identity $identity -Permission 'ReadAndExecute','Synchronize' -Inherited -Exact)
}

function Test-ShouldCheckUngrantedPermissionOnRegistry
{
    Assert-False (Test-Permission -Path $keyPath -Identity $identity -Permission 'Delete')
}

function Test-ShouldCheckGrantedPermissionOnRegistry
{
    Assert-True (Test-Permission -Path $keyPath -Identity $identity -Permission 'ReadKey')
}

function Test-ShouldCheckExactPartialPermissionOnRegistry
{
    Assert-False (Test-Permission -Path $keyPath -Identity $identity -Permission 'ReadKey' -Exact)
}

function Test-ShouldCheckExactPermissionOnRegistry
{
    Assert-True (Test-Permission -Path $keyPath -Identity $identity -Permission 'ReadKey','WriteKey' -Exact)
}

function Test-ShouldCheckUngrantedInheritanceFlags
{
    Assert-False (Test-Permission -Path $dirPath -Identity $identity -Permission 'ReadAndExecute' -ApplyTo ContainerAndSubContainersAndLeaves )
}

function Test-ShouldCheckGrantedInheritanceFlags
{
    Assert-True (Test-Permission -Path $dirPath -Identity $identity -Permission 'ReadAndExecute' -ApplyTo ContainerAndLeaves)
    Assert-True (Test-Permission -Path $dirPath -Identity $identity -Permission 'ReadAndExecute' -ApplyTo ChildLeaves )
}


function Test-ShouldCheckExactUngrantedInheritanceFlags
{
    Assert-False (Test-Permission -Path $dirPath -Identity $identity -Permission 'ReadAndExecute','Synchronize' -ApplyTo ContainerAndLeaves -Exact)
}

function Test-ShouldCheckExactGrantedInheritanceFlags
{
    Assert-True (Test-Permission -Path $dirPath -Identity $identity -Permission 'ReadAndExecute','Synchronize' -ApplyTo ChildLeaves -Exact)
}

