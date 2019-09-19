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

$appPoolName = 'CarbonGetIisAppPool'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisAppPool -Name $appPoolName
}

function Stop-Test
{
    if( (Test-IisAppPool -Name $appPoolName) )
    {
        Uninstall-IisAppPool -Name $appPoolName
    }
}

function Test-ShouldGetAllApplicationPools
{
    Install-IisAppPool -Name 'ShouldGetAllApplicationPools'
    Install-IisAppPool -Name 'ShouldGetAllApplicationPools2'
    try
    {
        $appPools = Get-IisAppPool
        Assert-NotNull $appPools
        Assert-Is $appPools ([object[]])
        Assert-NotNull ($appPools | Where-Object { $_.Name -eq 'ShouldGetAllApplicationPools' })
        Assert-NotNull ($appPools | Where-Object { $_.Name -eq 'ShouldGetAllApplicationPools2' })
    }
    finally
    {
        Uninstall-IisAppPool -Name 'ShouldGetAllApplicationPools'
        Uninstall-IisAppPool -Name 'ShouldGetAllApplicationPools2'
    }
}

function Test-ShouldAddServerManagerMembers
{
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-NotNull $appPool 
    Assert-NotNull $appPool.ServerManager
    $newAppPoolName = 'New{0}' -f $appPoolName
    Uninstall-IisAppPool -Name $newAppPoolName
    $appPool.name = $newAppPoolName
    $appPool.CommitChanges()
    
    try
    {
        $appPool = Get-IisAppPool -Name $newAppPoolName
        Assert-NotNull $appPool
        Assert-Equal $newAppPoolName $appPool.name
    }
    finally
    {
        Uninstall-IisAppPool -Name $newAppPoolName
    }
        
}

