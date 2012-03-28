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

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Invoke-FindUserOrGroup($name)
{
    return Find-UserOrGroup -Name $name
}

function Test-ShouldFindLocalUser
{
    Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)'" | ForEach-Object {
        $username = $_.Name
        $user = Invoke-FindUserOrGroup $username
        Assert-IsNotNull $user "Unable to find local user $username."
        Assert-Equal $username $user.Name
    }
}

function Test-ShouldFindDomainUser
{
    $user = Invoke-FindUserOrGroup "$($env:USERDOMAIN)\Administrator"
    Assert-IsNotNull $user 'Unable to find Administrator'
    Assert-Equal 'Administrator' $User.Name
}

function Test-ShouldFindLocalGroup
{
    Get-WmiObject Win32_Group -Filter "Domain='$($env:ComputerName)'" | ForEach-Object {
        $groupName = $_.Name
        $group = Invoke-FindUserOrGroup $groupName
        Assert-IsNotNull $group "Unable to find '$groupName'."
        Assert-Equal $groupName $group.Name
    }
}

function Test-ShouldFindDomainGroup
{
    $group = Invoke-FindUserOrGroup "$($env:USERDOMAIN)\Administrator"
    Assert-IsNotNull $group 'Unable to find group'
    Assert-Equal 'Administrator' $group.Name
}

function Test-ShouldNotFindNonExistentGroup
{
    $group = Invoke-FindUserOrGroup 'fdsjklfjsdakfjsdlkfjlskdfjsldkafj'
    Assert-Null $group 'Found a non-existent user/group.'
}
