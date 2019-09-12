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

$user = $null
$url = 'http://test-granthttpurlpermission:10383/'

function Start-Test
{
    $user = Resolve-Identity -Name $CarbonTestUser.UserName
}

function Stop-Test
{
    netsh http delete urlacl url=$url
}

function Test-ShouldRegisterAUrl
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Listen
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Listen)
}

function Test-ShouldRegisterUrlWithoutTrailingForwardSlash
{
    Grant-HttpUrlPermission -Url $url.TrimEnd("/") -Principal $user -Permission ListenAndDelegate
    Install-User -Credential (New-Credential -UserName 'CarbonTestUser2' -Password 'Password1') -PassThru
    $user2 = Resolve-Identity -Name 'CarbonTestUser2'
    Grant-HttpUrlPermission -Url $url.TrimEnd("/") -Principal $user2.FullName -Permission ListenAndDelegate
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate)
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate) -ExpectedUser $user2.FullName
}

function Test-ShouldGrantJustDelegatePermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Delegate
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Delegate)
}

function Test-ShouldGrantJustReadPermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Read
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Read)
}

function Test-ShouldChangePermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Listen
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Listen)

    Grant-HttpUrlPermission -Url $url -Principal $user -Permission ListenAndDelegate
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate)
}

function Test-ShouldGrantMultipleUsersPermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Listen
    Assert-NoError

    Install-User -Credential (New-Credential -UserName 'CarbonTestUser2' -Password 'Password1') -PassThru
    $user2 = Resolve-Identity -Name 'CarbonTestUser2'

    Grant-HttpUrlPermission -Url $url -Principal $user2.FullName -Permission Listen
    Assert-NoError

    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Listen)
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Listen) -ExpectedUser $user2.FullName
}

function Assert-Permission
{
    param(
        $ExpectedUser = $user.FullName,
        $ExpectedPermission
    )

    $acl = Get-HttpUrlAcl -Url $url
    Assert-NoError
    Assert-NotNull $acl
    Assert-Equal $acl.Url $url
    $rule = $acl.Access | Where-Object { $_.IdentityReference -eq $ExpectedUser }
    Assert-NotNull $rule
    Assert-Equal $ExpectedPermission $rule.HttpUrlAccessRights $ExpectedUser
}