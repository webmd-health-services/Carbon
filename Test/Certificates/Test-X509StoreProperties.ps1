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

function Test-ShouldCreateDisplayNameProperty
{
    $storeNameValues = [Enum]::GetValues( [Security.Cryptography.X509Certificates.StoreName] )
    Get-Item cert:\*\* | ForEach-Object {
        Assert-NotNull $_.DisplayName
        
        $storeName = $null

        $enumValue= $_.Name
        if( $enumValue -eq 'CA' )
        {
            $enumValue = 'CertificateAuthority'
        }
        if( $storeNameValues -contains $enumValue )
        {
            Assert-NotEqual $_.Name $_.DisplayName
        }
        else
        {
            Assert-Equal '' $_.DisplayName
        }
    }
}

