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
$url = 'http://test-revokehttpurlpermission:10383/'

function Start-Test
{
    $user = Resolve-Identity -Name $CarbonTestUser.UserName
    Grant-HttpUrlPermission -Url $url -Principal $user.FullName -Permission Listen
}

function Stop-Test
{
    netsh http delete urlacl url=$url
}

function Test-ShouldRevokePermission
{
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Assert-NoError
    Assert-Null (Get-HttpUrlAcl -Url $url -ErrorAction Ignore)
}

function Test-ShouldRevokePermissionMultipleTimes
{
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Assert-NoError
    Assert-Null (Get-HttpUrlAcl -Url $url -ErrorAction Ignore)
}

function Test-ShouldRevokeProperlyIfUrlDoesNotEndWithTrailingSlash
{
    Revoke-HttpUrlPermission -Url $url.TrimEnd('/') -Principal $user
    Assert-Null (Get-HttpUrlAcl -LiteralUrl $url -ErrorAction Ignore)
}