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

function Test-ShouldGetCallStores
{
    foreach( $location in ([enum]::GetValues('Security.Cryptography.X509Certificates.StoreLocation')) )
    {
        foreach( $name in ([Enum]::GetValues('Security.Cryptography.X509Certificates.StoreName')) )
        {
            Write-Verbose ('Location: {0}; Name: {1}' -f $location,$name)
            [Security.Cryptography.X509Certificates.X509Store]$store = Get-CertificateStore -StoreLocation $location -StoreName $name
            Assert-NotNull $store
            $actual = $store.Name
            if( $actual -eq 'CA' )
            {
                $actual = 'CertificateAuthority'
            }
            Assert-Equal $location $store.Location 
            Assert-Equal $name $actual
        }
    }
}

function Test-ShouldCreateStore
{
    $store = Get-CertificateStore -StoreLocation CurrentUser -CustomStoreName 'fubar'
    Assert-NotNull $store
    Assert-Equal 0 $store.Certificates.Count
    Assert-Equal 'fubar' $store.Name
}

