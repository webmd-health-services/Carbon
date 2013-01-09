<#
.SYNOPSIS
Example build server setup script.

.DESCRIPTION
This sample script shows how to setup a simple build server running CruiseControl.NET as a Windows Service.
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
[CmdletBinding()]
param(
)

$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot ..\Import-Carbon.ps1 -Resolve)

$ccservicePath = 'Path\to\ccservice.exe'
$ccserviceUser = 'example.com\CCServiceUser'
$ccservicePassword = 'CCServiceUserPassword'
Install-Service -Name CCService -Path $ccservicePath -Username $ccserviceUser -Password $ccservicePassword

$pathToVersionControlRepository = 'Path\to\version\control\repository'
$pathToBuildOutput = 'Path\to\build\output'
Grant-Permission -Identity $ccserviceUser -Permission FullControl -Path $pathToVersionControlRepository
Grant-Permission -Identity $ccserviceUser -Permission FullControl -Path $pathToBuildOutput