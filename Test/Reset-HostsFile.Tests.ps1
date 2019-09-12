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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Reset-HostsFile' {
    $customHostsFile = ''
    
    BeforeEach {
        $Global:Error.Clear()
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
    
    AfterEach {
        Remove-Item $customHostsFile
    }
    
    It 'should operate on hosts file by default' {
        $originalHostsfile = Read-File -Path (Get-PathToHostsFile)
    
        $firstEntry = '10.1.1.1     one.example.com'
        $commentLine = '# Below are all my custom host entries.'
        $secondEntry = "10.1.1.2     two.example.com"
        @"
    
$firstEntry
$commentLine
$secondEntry
    
"@ | Write-File -Path (Get-PathToHostsFile) 
    
        try
        {
            Reset-HostsFile
            $hostsFile = Read-File -Path (Get-PathToHostsFile)
            $hostsFile | Where-Object { $_ -eq $firstEntry } | Should BeNullOrEmpty
            $hostsFile | Where-Object { $_ -eq $commentLine } | Should BeNullOrEmpty
            $hostsFile | Where-Object { $_ -eq $secondEntry } | Should BeNullOrEmpty
        }
        finally
        {
            if( $originalHostsfile )
            {
                Write-File -Path (Get-PathToHostsFile) -InputObject $originalHostsFile
            }
        }
    }
    
    It 'should remove custom hosts entry' {
        $commentLine = '# Below are all my custom host entries.'
        $customEntry = "10.1.1.1     example.com"
    @"
    
$commentLine
$customEntry
    
"@ | Out-File -FilePath $customHostsFile -Encoding OEM -Append
        Reset-HostsFile -Path $customHostsFile
        $hostsFile = Get-Content -Path $customHostsFile
        $hostsFile | Where-Object { $_ -eq $commentLine } | Should BeNullOrEmpty
        $hostsFile | Where-Object { $_ -eq $customEntry } | Should BeNullOrEmpty
        $hostsFile | Where-Object { $_ -eq '127.0.0.1       localhost' } | Should Not BeNullOrEmpty
    }
    
    It 'should support should process' {
        $customEntry = '1.2.3.4       example.com'
        $customEntry | Set-Content -Path $customHostsFile
        Reset-HostsFile -WhatIf
        Get-Content -Path $customHostsFile | Where-Object { $_ -eq $customEntry } | Should Not BeNullOrEmpty
    }
    
    It 'should create file if it does not exist' {
        Remove-Item $customHostsFile
        
        Reset-HostsFile -Path $customHostsFile
    
        $hostsFile = Get-Content -Path $customHostsFile
        $hostsFile | Where-Object { $_ -eq '127.0.0.1       localhost' } | Should Not BeNullOrEmpty
    }
}
