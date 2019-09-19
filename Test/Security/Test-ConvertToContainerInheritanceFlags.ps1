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

$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()

function Start-TestFixture
{
    & (Join-Path -Path $TestDir -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    Install-User -Username $UserName -Password $Password
}

function Test-ShouldConvertToNtfsContainerInheritanceFlags
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null

    try
    {
        [Enum]::GetValues([Carbon.Security.ContainerInheritanceFlags]) | ForEach-Object {
            Grant-Permission -Path $tempDir -Identity $UserName -Permission FullControl -ApplyTo $_
            $perm = Get-Permission -Path $tempDir -Identity $UserName
            $flags = ConvertTo-ContainerInheritanceFlags -InheritanceFlags $perm.InheritanceFlags -PropagationFlags $perm.PropagationFlags
            Assert-Equal $_ $flags
        }
    }
    finally
    {
        if( Test-Path $tempDir )
        {
            Remove-Item $tempDir -Recurse -Force
        }
    }
}

function Test-ShouldConvertToRegistryContainerInheritanceFlags
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path 'hkcu:\' -ChildPath $tempDir
    New-Item -Path $tempDir 

    try
    {
        [Enum]::GetValues([Carbon.Security.ContainerInheritanceFlags]) | ForEach-Object {
            Grant-Permission -Path $tempDir -Identity $UserName -Permission ReadKey -ApplyTo $_
            $perm = Get-Permission -Path $tempDir -Identity $UserName
            $flags = ConvertTo-ContainerInheritanceFlags -InheritanceFlags $perm.InheritanceFlags -PropagationFlags $perm.PropagationFlags
            Assert-Equal $_ $flags
        }
    }
    finally
    {
        Remove-Item $tempDir
    }
}

