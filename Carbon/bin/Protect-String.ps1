<#
.SYNOPSIS
**INTERNAL. DO NOT USE**
#>
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
param(
    [Parameter(Mandatory=$true)]
    [string]
    $ProtectedString
)

Set-StrictMode -Version 'Latest'

Add-Type -AssemblyName 'System.Security'

. (Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\Protect-String.ps1' -Resolve)
. (Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\Unprotect-String.ps1' -Resolve)

$string = Unprotect-String -ProtectedString $ProtectedString
Protect-String -String $string -ForUser
