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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetUser
{
    Invoke-CPrivateCommand -Name 'Get-CCimInstance' -Parameter @{Class = 'Win32_UserAccount'; Filter = "Domain='$($env:ComputerName)'"} | ForEach-Object {
        $user = Get-WmiLocalUserAccount -Username $_.Name
        Assert-NotNull $user
        Assert-Equal $_.Name $user.Name
        Assert-Equal $_.FullName $user.FullName
        Assert-Equal $_.SID $user.SID
    }
}

