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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
$shareName = 'CarbonUninstallFileShare'
$sharePath = $null
$shareDescription = 'Share for testing Carbon''s Uninstall-FileShare function.'

function Start-Test
{
    $sharePath = New-TempDirectory -Prefix $PSCommandPath
    Install-SmbShare -Path $sharePath -Name $shareName -Description $shareDescription
    Assert-True (Test-FileShare -Name $shareName)
}

function Stop-Test
{
    Remove-Item -Path $sharePath
    Get-FileShare -Name $shareName -ErrorAction Ignore | ForEach-Object { $_.Delete() }
}

function Test-ShouldDeleteShare
{
    Uninstall-FileShare -Name $shareName
    Assert-NoError
    Assert-False (Test-FileShare -Name $shareName)
    Assert-DirectoryExists -Path $sharePath
}

function Test-ShouldSupportShouldProcess
{
    Uninstall-FileShare -Name $shareName -WhatIf
    Assert-True (Test-FileShare -Name $shareName)
}

function Test-ShouldHandleShareThatDoesNotExist
{
    Uninstall-FileShare -Name 'fdsfdsurwoim'
    Assert-NoError
}
