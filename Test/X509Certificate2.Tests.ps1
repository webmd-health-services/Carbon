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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)
}


Describe 'X509Certificate2' {
    It 'should create issued properties on x509 certificate2' {
        $certPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificate.cer' -Resolve
        $cert = Get-CCertificate -Path $certPath -NoWarn
        $cert.IssuedTo | Should -Not -BeNullOrEmpty
        $cert.IssuedBy | Should -Not -BeNullOrEmpty

        $cert.IssuedBy | Should -Be ($cert.GetNameInfo( 'SimpleName', $true ))
        $cert.IssuedTo | Should -Be ($cert.GetNameInfo( 'SimpleName', $false ))
    }

}
