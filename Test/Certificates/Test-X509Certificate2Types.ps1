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

function Test-ShouldCreateIssuedPropertiesOnX509Certificate2
{
    $cert = Get-Certificate -Path (Join-Path $TEstDir CarbonTestCertificate.cer -Resolve) -NoWarn
    Assert-NotNull $cert.IssuedTo ('IssuedTo on {0}' -f $cert.Subject)
    Assert-NotNull $cert.IssuedBy ('IssuedBy on {0}' -f $cert.Subject)
    
    Assert-Equal ($cert.GetNameInfo( 'SimpleName', $true )) $cert.IssuedBy
    Assert-Equal ($cert.GetNameInfo( 'SimpleName', $false )) $cert.IssuedTo
}

