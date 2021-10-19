<#
.SYNOPSIS
**INTERNAL. DO NOT USE**
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
    $ProtectedString
)

Set-StrictMode -Version 'Latest'

# Keep cause this script is used by PowerShell 2.
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

Add-Type -AssemblyName 'System.Security'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.psd1' -Resolve)

$string = Unprotect-CString -ProtectedString $ProtectedString -NoWarn
Protect-CString -String $string -ForUser -NoWarn

