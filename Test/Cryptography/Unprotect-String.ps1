<#
.SYNOPSIS
**INTERNAL. DO NOT USE** Standalone wrapper script for Carbon's `Unprotect-String` function to make it easier to decrypt a string as a custom user.
#>
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
    # A base-64 encoded string that was protected with Carbon's `protect-String`.
    $ProtectedString
)

Set-StrictMode -Version 'Latest'

Add-Type -AssemblyName 'System.Security'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Carbon.psd1' -Resolve)

Unprotect-CString -ProtectedString $ProtectedString -NoWarn

