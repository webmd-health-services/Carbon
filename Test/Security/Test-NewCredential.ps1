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

function Test-ShouldCreateCredential
{
    $cred = New-Credential -User 'Credential' -Password 'password1'
    Assert-IsNotNull $cred 'New-Credential didn''t create credential object.'
    Assert-Is $cred 'Management.Automation.PSCredential' "didn't create credential object of right type"
    Assert-Equal 'Credential' $cred.UserName 'username not set correctly'
    Assert-NotEmpty (ConvertFrom-SecureString $cred.Password) 'password not set correctly'
}

function Test-ShouldCreateCredentialFromSecureString
{
    $secureString = New-Object 'Security.SecureString'
    $secureString.AppendChar( 'a' )

    $c = New-Credential -UserName 'fubar' -Password $secureString
    Assert-NotNull $c
    Assert-Equal 'a' $c.GetNetworkCredential().Password
}

function Test-ShouldGiveAnErrorIfPassNotAStringOrSecureString
{
    $c = New-Credential -UserName 'fubar' -Password 1 -ErrorAction SilentlyContinue
    Assert-Null $c
    Assert-Error -Last -Regex 'must be'
}

function Test-ShouldAcceptPipelineInput
{
    $c = 'fubar' | New-Credential -UserName 'fizzbuzz'
    Assert-NotNull $c
    Assert-Equal 'fizzbuzz' $c.UserName
    Assert-Equal 'fubar' $c.GetNetworkCredential().Password
}

