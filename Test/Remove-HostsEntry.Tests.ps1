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

$hostsFile = $null
$hostname = 'example.com'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $hostsFile = Join-Path -Path $env:TEMP -ChildPath ('Carbon+Test-RemoveHostsEntry+{0}' -f [IO.Path]::GetRandomFileName())

    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname -Path $hostsFile
}

function Stop-Test
{
    if( (Test-Path -Path $hostsFile -PathType Leaf) )
    {
        Remove-Item $hostsFile
    }
}

function Test-ShouldRemoveHostsEntry
{
    Remove-HostsEntry -HostName $hostname -Path $hostsFile
    Assert-NoHostsEntry -HostName $hostname
}

function Test-ShouldIgnoreSimilarHostsEntryWithDifferentTLD
{
    $dup = '{0}m' -f $hostname
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Path $hostsFile
    Remove-HostsEntry $hostname -Path $hostsFile
    Assert-NoHostsEntry -HostName $hostname
    Assert-HostsEntry -HostName $dup
}

function Test-ShouldIgnoreSimilarHostsEntryWithSimilarTld
{
    $dup = 'example.co'
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Path $hostsFile
    Remove-HostsEntry $hostname -Path $hostsFile
    Assert-NoHostsEntry -HostName $hostname
    Assert-HostsEntry -HostName $dup
}

function Test-ShouldIgnoreSimilarHostsEntryWithExtraSubDomain
{
    $dup = 'www.{0}' -f $hostname
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Path $hostsFile
    Remove-HostsEntry $hostname -Path $hostsFile
    Assert-NoHostsEntry -HostName $hostname
    Assert-HostsEntry -HostName $dup
}

function Test-ShouldIgnoreCommentsWhenRemoving
{
    $dup = 'www.{0}' -f $hostname
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $dup -Description $hostname -Path $hostsFile
    Remove-HostsEntry $hostname -Path $hostsFile
    Assert-NoHostsEntry -HostName $hostname
    Assert-HostsEntry -HostName $dup
}

function Test-ShouldRemoveMultipleHostsEntries
{
    $hostname2 = 'www.{0}' -f $hostname
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname2 -Path $hostsFile
    Remove-HostsEntry -HostName $hostname,$hostname2 -Path $hostsFile
    Assert-NoHostsEntry $hostname
    Assert-NoHostsEntry $hostname2
}

function Test-ShouldRemoveMultipleHostsEntriesFromPipeline
{
    $hostname2 = 'www.{0}' -f $hostname
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname2 -Path $hostsFile
    ($hostname,$hostname2) | Remove-HostsEntry -Path $hostsFile
    Assert-NoHostsEntry $hostname
    Assert-NoHostsEntry $hostname2
}

function Test-ShouldOperateOnWindowsHostsFile
{
    Set-HostsEntry -IPAddress '1.2.3.4' -HostName $hostname
    Remove-HostsEntry -HostName $hostname
    Assert-NoHostsEntry -HostName $hostname -Path 'C:\Windows\system32\drivers\etc\hosts'
}

function Test-ShouldSupportWhatIf
{
    Remove-HostsEntry -HostName $hostname -WhatIf -Path $hostsFile
    Assert-HostsEntry -HostName $hostname
}

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

    Assert-NotNull (Get-HostsEntry -HostName $HostName -Path $Path)
}

function Assert-NoHostsEntry
{
    param(
        [string]
        $HostName,

        [string]
        $Path = $hostsFile
    )

    Assert-Null (Get-HostsEntry -HostName $HostName -Path $Path)
}

