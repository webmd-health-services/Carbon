<#
.SYNOPSIS
Imports the Carbon module.

.DESCRIPTION
Imports the Carbon module.  If the Carbon module is already loaded, it will remove it and then reloaded.

.EXAMPLE
Import-Carbon.ps1

Imports the Carbon module, re-loading it if its already loaded.

Imports the Carbon module, hiding any warnings about Carbon being loaded as a sub-module.
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

Set-StrictMode -Version Latest
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

if( (Get-Module Carbon) )
{
    Remove-Module Carbon
}

Import-Module (Join-Path $PSScriptRoot Carbon.psd1 -Resolve) -ErrorAction Stop
