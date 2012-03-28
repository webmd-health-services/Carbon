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

$customHostsFile = ''

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    
    $customHostsFile = Join-Path $env:temp ([IO.Path]::GetRandomFileName())
    @"
# Copyright (c) 1993-1999 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

127.0.0.1       localhost
"@ | Out-File -FilePath $customHostsfile -Encoding OEM    
}

function TearDown
{
    Remove-Item $customHostsFile
    Remove-Module Carbon
}

function Test-ShouldOperateOnHostsFileByDefault
{
    $originalHostsfile = Get-Content (Get-PathToHostsFile)

    $commentLine = '# Below are all my custom host entries.'
    $customEntry = "10.1.1.1     example.com"
    @"

$commentLine
$customEntry

"@ | Out-File -FilePath (Get-PathToHostsFile) -Encoding OEM -Append

    try
    {
        Reset-HostsFile
        $hostsFile = Get-Content -Path (Get-PathToHostsFile)
        Assert-DoesNotContain $hostsFile $commentLine
        Assert-DoesNotContain $hostsFile $customEntry
        Assert-Contains $hostsFile '127.0.0.1       localhost'
    }
    finally
    {
        Set-Content -Path (Get-PathToHostsFile) -Value $originalHostsFile
    }
}

function Test-ShouldRemoveCustomHostsEntry
{
    $commentLine = '# Below are all my custom host entries.'
    $customEntry = "10.1.1.1     example.com"
    @"

$commentLine
$customEntry

"@ | Out-File -FilePath $customHostsFile -Encoding OEM -Append
    Reset-HostsFile -Path $customHostsFile
    $hostsFile = Get-Content -Path $customHostsFile
    Assert-DoesNotContain $hostsFile $commentLine
    Assert-DoesNotContain $hostsFile $customEntry
    Assert-Contains $hostsFile '127.0.0.1       localhost'
}

function Test-ShouldSupportShouldProcess
{
    $customEntry = '1.2.3.4       example.com'
    $customEntry >> $customHostsFile
    Reset-HostsFile -WhatIf
    Assert-Contains (Get-Content -Path $customHostsFile) $customEntry
}

function Test-ShouldCreateFileIfItDoesNotExist
{
    Remove-Item $customHostsFile
    
    Reset-HostsFile -Path $customHostsFile

    $hostsFile = Get-Content -Path $customHostsFile
    Assert-Contains $hostsFile '127.0.0.1       localhost'
}
