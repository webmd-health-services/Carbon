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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldNotFindNonExistentAppPool
{
    $exists = Test-IisAppPool -Name 'ANameIMadeUpThatShouldNotExist'
    Assert-False $exists "A non-existent app pool exists."
    Assert-NoError
}

function Test-ShouldFindAppPools
{
    $apppools = Get-IisAppPool
    Assert-GreaterThan $apppools.Length 0 "There aren't any app pools on the current machine!"
    foreach( $apppool in $apppools )
    {
        $exists = Test-IisAppPool -Name $appPool.Name
        Assert-True $exists "An existing app pool '$($appPool.Name)' not found."
    }
}


