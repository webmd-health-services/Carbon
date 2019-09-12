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

$hostsFile = $null
$hostname = 'example.com'

function Get-HostsEntry
{
    param(
        [string]
        $HostName,
    
        [string]
        $Path = $hostsFile
    )
    $HostName = [Text.RegularExpressions.Regex]::Escape( $HostName )
    Get-Content -Path $Path |
        Where-Object { $_ -match ('^[0-9a-f.:]+\s+\b{0}\b' -f $HostName) }
}
    
function Assert-HostsEntry
{
    param(
        [string]
        $HostName,
    
        [string]
        $Path = $hostsFile
    )
    
    (Get-HostsEntry -HostName $HostName -Path $Path) | Should Not BeNullOrEmpty
}
    
function Assert-NoHostsEntry
{
    param(
        [string]
        $HostName,
    
        [string]
        $Path = $hostsFile
    )
    
    (Get-HostsEntry -HostName $HostName -Path $Path) | Should BeNullOrEmpty
}

function New-TestHostsFile
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $InputObject    
    )
    begin
    {
        $path = Join-Path -Path (Get-Item -Path 'TestDrive:').FullName -ChildPath ('Carbon+Test-RemoveHostsEntry+{0}' -f [IO.Path]::GetRandomFileName())
    }

    process
    {
        if( $InputObject )
        {
            $InputObject | Add-Content -Path $path
        }
    }

    end
    {
        return $path
    }
}

Describe 'Remove-HostsEntry when removing an IPv6 address' {
    $hostsFile = '2001:4860:4860::8844 one','2001:4860:4860::8844 two' | New-TestHostsFile
    Remove-HostsEntry -HostName 'two'  -Path $hostsFile
    It 'should remove the hosts entry' {
        Get-Content -Path $hostsFile | Where-Object { $_ -like '* two' } | Should BeNullOrEmpty
        Get-Content -Path $hostsFile | Where-Object { $_ -like '* one' } | Should Not BeNullOrEmpty
    }
}
    
Describe 'Remove-HostsEntry' {
    BeforeEach {
        $hostsFile = New-TestHostsFile
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname -Path $hostsFile
    }
    
    AfterEach {
        if( (Test-Path -Path $hostsFile -PathType Leaf) )
        {
            Remove-Item $hostsFile
        }
    }
    
    It 'should remove hosts entry' {
        Remove-HostsEntry -HostName $hostname -Path $hostsFile
        Assert-NoHostsEntry -HostName $hostname
    }
    
    It 'should ignore similar hosts entry with different t l d' {
        $dup = '{0}m' -f $hostname
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Path $hostsFile
        Remove-HostsEntry $hostname -Path $hostsFile
        Assert-NoHostsEntry -HostName $hostname
        Assert-HostsEntry -HostName $dup
    }
    
    It 'should ignore similar hosts entry with similar tld' {
        $dup = 'example.co'
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Path $hostsFile
        Remove-HostsEntry $hostname -Path $hostsFile
        Assert-NoHostsEntry -HostName $hostname
        Assert-HostsEntry -HostName $dup
    }
    
    It 'should ignore similar hosts entry with extra sub domain' {
        $dup = 'www.{0}' -f $hostname
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Path $hostsFile
        Remove-HostsEntry $hostname -Path $hostsFile
        Assert-NoHostsEntry -HostName $hostname
        Assert-HostsEntry -HostName $dup
    }
    
    It 'should ignore comments when removing' {
        $dup = 'www.{0}' -f $hostname
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Description $hostname -Path $hostsFile
        Remove-HostsEntry $hostname -Path $hostsFile
        Assert-NoHostsEntry -HostName $hostname
        Assert-HostsEntry -HostName $dup
    }
    
    It 'should remove multiple hosts entries' {
        $hostname2 = 'www.{0}' -f $hostname
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname2 -Path $hostsFile
        Remove-HostsEntry -HostName $hostname,$hostname2 -Path $hostsFile
        Assert-NoHostsEntry $hostname
        Assert-NoHostsEntry $hostname2
    }
    
    It 'should remove multiple hosts entries from pipeline' {
        $hostname2 = 'www.{0}' -f $hostname
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname2 -Path $hostsFile
        ($hostname,$hostname2) | Remove-HostsEntry -Path $hostsFile
        Assert-NoHostsEntry $hostname
        Assert-NoHostsEntry $hostname2
    }
    
    It 'should operate on windows hosts file' {
        Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname
        Remove-HostsEntry -HostName $hostname
        Assert-NoHostsEntry -HostName $hostname -Path 'C:\Windows\system32\drivers\etc\hosts'
    }
    
    It 'should support what if' {
        Remove-HostsEntry -HostName $hostname -WhatIf -Path $hostsFile
        Assert-HostsEntry -HostName $hostname
    }
    
}
