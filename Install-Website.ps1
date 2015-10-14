<#
.SYNOPSIS
Installs the get-carbon.org website on the local computer.
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

#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot Carbon\Import-Carbon.ps1 -Resolve)

$websitePath = Join-Path $PSScriptRoot Website -Resolve
Install-IisWebsite -Name 'get-carbon.org' -Path $websitePath -Bindings 'http/*:80:'
Grant-Permission -Identity Everyone -Permission ReadAndExecute -Path $websitePath
