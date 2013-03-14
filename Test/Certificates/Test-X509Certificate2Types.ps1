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
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldCreateIssuedPropertiesOnX509Certificate2
{
    Get-ChildItem -Path cert:\ -Recurse |
        Where-Object { -not $_.PsIsContainer } | 
        ForEach-Object {
            Assert-NotNull $_.IssuedTo ('IssuedTo on {0}' -f $_.Subject)
            Assert-NotNull $_.IssuedBy ('IssuedBy on {0}' -f $_.Subject)
            
            Assert-Equal ($_.GetNameInfo( 'SimpleName', $true )) $_.IssuedBy
            Assert-Equal ($_.GetNameInfo( 'SimpleName', $false )) $_.IssuedTo
        }
}