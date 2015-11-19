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

$originalHostsFile = ''
$customHostsFile = ''

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
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

function Stop-Test
{
    Remove-Item $customHostsFile
}

function Test-ShouldOperateOnSystemHostsFileByDefault
{
    $originalHostsfile = Get-Content (Get-PathToHostsFile)

    try
    {
        Set-HostsEntry -IPAddress '5.6.7.8' -HostName 'example.com' -Description 'Customizing example.com'
    
        Assert-HostsFileContains -Line "5.6.7.8         example.com`t# Customizing example.com"  -Path (Get-PathToHostsFile)
    }
    finally
    {
        Set-Content -Path (Get-PathToHostsFile) -Value $originalHostsFile
    }
}

function Test-ShouldUpdateExistingHostsEntry
{
    $hostsEntry = '1.2.3.4  example.com'
    $hostsEntry | Out-HostsFile
    
    Assert-HostsFileContains -Line $hostsEntry
    
    Set-HostsEntry -IPAddress '5.6.7.8' -HostName 'example.com' -Description 'Customizing example.com' -Path $customHostsFile
    
    Assert-HostsFileContains -Line "5.6.7.8         example.com`t# Customizing example.com"  
}

function Test-ShouldAddNewHostsEntry
{
    $ip = '255.255.255.255'
    $hostname = 'shouldaddnewhostsentry.example.com'
    $description = 'testing if new hosts entries get added'
    
    Set-HostsEntry -IPAddress $ip -Hostname $hostname -Description $description -Path $customHostsFile
    
    Assert-HostsFileContains -Line "$ip $hostname`t# $description"
}

function Test-ShouldRemoveComment
{
    $ip = '1.1.1.1'
    $hostname = 'shouldremovecomment.example.com'
    
    "$ip $hostname  # this comment should get removed" | Out-HostsFile
    
    Set-HostsEntry -IPAddress $ip -HostName $hostname -Path $customHostsFile
   
    Assert-HostsFileContains -Line "$ip         $hostname"
}

function Test-ShouldCommentOutDuplicates
{
    $ip = '3.3.3.3'
    $hostname = 'shouldcommentoutduplicates.example.com'
    
    $line = "$ip $hostname"
    ($line,$line) | Out-HostsFile
    
    Set-HostsEntry -IPAddress $ip -HostName $hostname -Path $customHostsFile
    
    Assert-HostsFileContains -Line "$ip         $hostname"
    Assert-HostsFileContains -Line "#$ip $hostname"
}

function Test-ShouldSupportWhatIf
{
    Reset-HostsFile -Path $customHostsFile
    
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -WhatIf -Path $customHostsFile
    
    Assert-HostsFileContains '127.0.0.1       localhost'
}

function Test-ShouldSetEntryInEmptyHostsFile
{
    Remove-Item $customHostsFile
    New-Item -Path $customHostsFile -ItemType File
    
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -Path $customHostsFile
    
    Assert-HostsFileContains '127.0.0.1       example.com'
}

function Test-ShouldHandleMissingHostsFile
{
    Remove-Item $customHostsFile
    
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -Path $customHostsFile
    
    Assert-HostsFileContains '127.0.0.1       example.com'
}

function Test-ShouldIgnoreAndCommentInvalidHostsEntry
{
    'Invalid Line' | Out-HostsFile
    Set-HostsEntry -IPAddress '4.3.2.1' -Hostname 'example.com' -Path $customHostsFile
    Assert-HostsFileContains '4.3.2.1         example.com'
    Assert-HostsFileContains '# Invalid line'
}

function Test-ShouldHandleIfHostsFileInUse
{
    $file = [IO.File]::Open($customHostsFile, 'Open', 'Read', 'Read')
    try
    {
        Set-HostsEntry '1.2.3.4' -HostName 'example.com' -Path $customHostsFile -ErrorAction SilentlyContinue
    }
    finally
    {
        $file.Close()
    }
    Assert-Equal 1 $Global:Error.Count
    Assert-Error -Last -Regex 'looks like the hosts file is in use'
}

#This test check case from Issue #148 
function Test-MultipleCallShouldNotDeleteTabulation
{
    Set-HostsEntry -IPAddress 127.0.0.1 -HostName 'test' -Description 'Test' -Path $customHostsFile
    Set-HostsEntry -IPAddress 127.0.0.1 -HostName 'test2' -Description 'Test2' -Path $customHostsFile
    Set-HostsEntry -IPAddress 127.0.0.1 -HostName 'test3' -Path $customHostsFile
    
    Assert-HostsFileContains -Line "127.0.0.1       test`t# Test"
    Assert-HostsFileContains -Line "127.0.0.1       test2`t# Test2"
    Assert-HostsFileContains -Line "127.0.0.1       test3"
}


function Assert-HostsFileContains($Line, $Path = $customHostsFile)
{
    $hostsFile = Get-Content $Path
    Assert-Contains $hostsFile $Line "Hosts file"
}


filter Out-HostsFile
{
    process
    {
        $_ | Out-File $customHostsFile -Append -Encoding OEM
    }
}

