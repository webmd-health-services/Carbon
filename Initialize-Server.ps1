<#
.SYNOPSIS
Initializes a server and gets it ready to run Carbon tests.
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

[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'
$PSCommandPath = $MyInvocation.MyCommand.Definition
$PSScriptRoot = Split-Path -Parent -Path $PSCommandPath

Install-WindowsFeature -Name 'Web-Server','MSMQ-Server','Web-Scripting-Tools'

choco install 'sysinternals' -y
choco install 'conemu' -y

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1')

Uninstall-IisWebsite -Name 'Default Web Site'

# For tests that do stuff over remoting.
Add-TrustedHost -Entry $env:COMPUTERNAME
