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

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-HostsFileContains
{
    param(
        [Parameter(ParameterSetName='ExactLine')]
        $Line, 
        [Parameter(ParameterSetName='ConstructLine')]
        [Net.IPAddress]
        $IPAddress,
        [Parameter(ParameterSetName='ConstructLine')]
        $HostName,
        [Parameter(ParameterSetName='ConstructLine')]
        $Description,
        $Path = $customHostsFile
    )

    if( $PSCmdlet.ParameterSetName -eq 'ConstructLine' )
    {
        $Line = '{0,-45}  {1}' -f $IPAddress,$HostName
        if( $Description )
        {
            $Line = "{0}`t# {1}" -f $Line,$Description
        }
    }

    It ('should set entry {0}' -f $Line) {
        $hostsFile = Read-File -Path $Path
        $hostsFile | Where-Object { $_ -eq $Line } | Should Not BeNullOrEmpty
    }
}
    
function New-TestHostsFile
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $Line
    )
    begin
    {
        $testDrive = (Get-Item -Path 'TestDrive:').FullName
        $path = Join-Path -Path $testDrive -ChildPath 'hosts'
    }
    process
    {
        $Line | Add-Content -Path $path
    }
    end
    {
        return $path
    }
}

Describe 'Set-HostsEntry.when passed a new IPv6 address' {
    $hostsPath = New-TestHostsFile
    Set-HostsEntry -IPAddress  'cc1a:2078:ec06:4f32:8ea8:7119:663a:f2d2' -HostName 'ipv6' -Path $hostsPath
    Assert-HostsFileContains -IPAddress 'cc1a:2078:ec06:4f32:8ea8:7119:663a:f2d2' -HostName 'ipv6' -Path $hostsPath
}

Describe 'Set-HostsEntry.when IPv6 address contains IP tunnel' {
    $hostsPath = New-TestHostsFile
    Set-HostsEntry -IPAddress '2001:4860:4860::8888:255.255.255.255' -HostName 'ipv6' -Path $hostsPath
    Assert-HostsFileContains -IPAddress '2001:4860:4860::8888:255.255.255.255' -HostName 'ipv6' -Path $hostsPath
}

Describe 'Set-HostsEntry.when updating an existing IPv6 address' {
    $hostsPath = New-TestHostsFile
    Set-HostsEntry -IPAddress '2001:4860:4860::8888' -HostName 'ipv6' -Path $hostsPath
    Set-HostsEntry -IPAddress '2001:4860:4860::8844' -HostName 'ipv6' -Path $hostsPath
    Assert-HostsFileContains -IPAddress '2001:4860:4860::8844' -HostName 'ipv6' -Path $hostsPath
}

Describe 'Set-HostsEntry.when no path parameter provided' {
    Mock -CommandName 'Write-CFile' -Verifiable -ModuleName 'Carbon'

    Set-HostsEntry -IPAddress '5.6.7.8' -HostName 'example.com' -Description 'Customizing example.com'

    It 'should operate on system hosts file by default' {
        Assert-MockCalled -CommandName 'Write-CFile' -ModuleName 'Carbon'  -ParameterFilter {
            #$DebugPreference = 'Continue'
            Write-Debug $Path 
            Write-Debug (Get-PathToHostsFile)
            $Path -eq (Get-PathToHostsFile)
        }
    }
}

Describe 'Set-HostsEntry.when setting an existin IPv4 entry' {
    $hostsFile = '1.2.3.4  example.com' | New-TestHostsFile
    
    Set-HostsEntry -IPAddress '5.6.7.8' -HostName 'example.com' -Description 'Customizing example.com' -Path $hostsFile
    Assert-HostsFileContains -IPAddress "5.6.7.8" -HostName 'example.com' -Description 'Customizing example.com' -Path $hostsFile
}

Describe 'Set-HostsEntry.when adding a new IPv4 entry' {    
    $hostsFile = New-TestHostsFile
    $ip = '255.255.255.255'
    $hostname = 'shouldaddnewhostsentry.example.com'
    $description = 'testing if new hosts entries get added'
        
    Set-HostsEntry -IPAddress $ip -Hostname $hostname -Description $description -Path $hostsFile
        
    Assert-HostsFileContains -IPAddress $ip -HostName $hostname -Description $description -Path $hostsFile
}

Describe 'Set-HostsEntry.when an existing entry has a comment but is updated without a comment' {    
    $ip = '1.1.1.1'
    $hostname = 'shouldremovecomment.example.com'

    $hostsFile = "$ip $hostname  # this comment should get removed" | New-TestHostsFile
        
    Set-HostsEntry -IPAddress $ip -HostName $hostname -Path $hostsFile
       
    Assert-HostsFileContains -IPAddress $ip -HostName $hostname -Path $hostsFile
}
    
Describe 'Set-HostsEntry.when there are duplicate hostnames' {
    $ip = '3.3.3.3'
    $hostname = 'shouldcommentoutduplicates.example.com'
    $line = "$ip $hostname"

    $hostsFile = ($line,$line) | New-TestHostsFile
        
    Set-HostsEntry -IPAddress $ip -HostName $hostname -Path $hostsFile
        
    Assert-HostsFileContains -IPAddress $ip -HostName $hostname -Path $hostsFile

    $commentedLine = '#{0}' -f $line

    Assert-HostsFileContains -Line $commentedLine -Path $hostsFile
    It 'should comment out second duplicate' {
        Get-Content -Path $hostsFile | Select-Object -Last 1 | Should Be $commentedLine
    }
}

Describe 'Set-HostsEntry.when using -WhatIf switch' {
    $hostsFile = New-TestHostsFile
        
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -WhatIf -Path $hostsFile
        
    It 'should not update the hosts file' {
        Get-Content -Path $hostsFile | Should BeNullOrEmpty
    }
}

Describe 'Set-HostsEntry.when hosts file exists and is empty' {
    $hostsFile = New-TestHostsFile
    Remove-Item -Path $hostsFile
    New-Item -Path $hostsFile -ItemType File
    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -Path $hostsFile
    Assert-HostsFileContains -IPAddress '127.0.0.1' -Hostname 'example.com' -Path $hostsFile
}    

Describe 'Set-HostsEntry.when hosts file does not exist' {
    $Global:Error.Clear()
    $hostsFile = New-TestHostsFile
    Remove-Item -Path $hostsFile

    Set-HostsEntry -IPAddress '127.0.0.1' -Hostname 'example.com' -Path $hostsFile
    It 'should not write any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
    It 'should create hosts file' {
        $hostsFile | Should Exist
    }
    Assert-HostsFileContains -IPAddress '127.0.0.1' -HostName 'example.com' -Path $hostsFile
}

Describe 'Set-HostsEntry.when hosts file contains invalid entries' {
    $hostsFile = 'Invalid Line' | New-TestHostsFile
        
    Set-HostsEntry -IPAddress '4.3.2.1' -Hostname 'example.com' -Path $hostsFile
    Assert-HostsFileContains -IPAddress '4.3.2.1' -HostName 'example.com' -Path $hostsFile
    Assert-HostsFileContains -Line '# Invalid line' -Path $hostsFile
}
    
Describe 'Set-HostsEntry.when the hosts file is in use' {
    $Global:Error.Clear()

    $line1 = '0.3.2.1 example1.com'
    $line2 = '0.6.7.8 example2.com'

    $hostsFile = $line1,$line2 | New-TestHostsFile
    
    $expectedHostsFile = @"
$line1
$line2

"@

    Context 'the hosts file is locked for writing' {
        $file = [IO.File]::Open($hostsFile, 'Open', 'Read', 'Read')
        try
        {
            Set-HostsEntry '1.2.3.4' -HostName 'example.com' -Path $hostsFile -ErrorAction SilentlyContinue
        }
        finally
        {
            $file.Close()
        }

        It 'should write an error' {
            $Global:Error.Count | Should Be 1
            $Global:Error.Count | Should BeGreaterThan 0
            $Global:Error | Should Match 'cannot access the file'
        }
            
        It 'should not modify the file' {    
            Get-Content -Raw -Path $hostsFile | Should Be $expectedHostsFile
        }
    }

    Context 'the hosts file is locked for reading' {
        $Global:Error.Clear()
    
        $job = Start-Job -ScriptBlock {
                                            $file = [IO.File]::Open($using:hostsFile, 'Open', 'Read', 'None')
                                            Start-Sleep -Seconds 5
                                            $file.Close()
                                        }
        try
        {
            do
            {
                Start-Sleep -Milliseconds 100
                Write-Debug -Message ('Waiting for hosts file to get locked.')
            }
            while( (Get-Content -Raw -Path $hostsFile -ErrorAction Ignore) )
    
            Set-HostsEntry '0.4.5.6' -HostName 'example1.com' -Path $hostsFile -ErrorAction SilentlyContinue
    
            It 'should write error' {
                $Global:Error.Count | Should BeGreaterThan 0
                $Global:Error[0] | Should Match 'cannot access the file'
            }
    
            do
            {
                Start-Sleep -Milliseconds 100
                Write-Debug -Message ('Waiting for hosts file to get unlocked.')
            }
            while( -not (Get-Content -Raw -Path $hostsFile -ErrorAction Ignore) )

            It 'should not modify the file' {    
                $hostsFile = Get-Content -Raw -Path $hostsFile -ErrorAction Ignore | Should Be $expectedHostsFile
            }
        }
        finally
        {
            $job | Wait-Job | Receive-Job | Out-String | Write-Debug
        }
    }
}

# This test check case from Issue #148 
Describe 'Set-HostsEntry.when updating entries with descriptions' {
    $hostsFile = New-TestHostsFile

    Set-HostsEntry -IPAddress 127.0.0.1 -HostName 'test' -Description 'Test' -Path $hostsFile
    Set-HostsEntry -IPAddress 127.0.0.1 -HostName 'test2' -Description 'Test2' -Path $hostsFile
    Set-HostsEntry -IPAddress 127.0.0.1 -HostName 'test3' -Path $hostsFile
        
    Assert-HostsFileContains -IPAddress "127.0.0.1" -HostName 'test' -Description 'Test' -Path $hostsFile
    Assert-HostsFileContains -IPAddress "127.0.0.1" -HostName 'test2' -Description 'Test2' -Path $hostsFile
    Assert-HostsFileContains -IPAddress "127.0.0.1" -HostName 'test3' -Path $hostsFile
}

Describe 'Set-HostsEntry.when the hosts file contains trailing empty lines' {
        $line = @"
{0,-45}  fubarsnafu
{0,-45}  snafufubar
"@ -f '127.0.0.1'

    $hostsFile = $line | New-TestHostsFile

    Set-HostsEntry -IPAddress '127.0.0.1' -HostName 'fubarsnafu' -Path $hostsFile
    It 'should trim trailing space' {
        (Get-Content -Raw -Path $hostsFile).Trim("`r","`n") | Should Be $line.Trim()
    }
}