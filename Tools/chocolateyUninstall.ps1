<#
.SYNOPSIS
Chocolately install script for Carbon.
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

#Requires -Version 4
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

# Use Get-Item so we can mock it
Get-Item -Path 'env:PSModulePath' |
    Select-Object -ExpandProperty 'Value'-ErrorAction Ignore |
    ForEach-Object { $_ -split ';' } |
    Where-Object { $_ } |
    Join-Path -ChildPath 'Carbon' |
    Where-Object { Test-Path -Path $_ -PathType Container } |
    Rename-Item -NewName { 'Carbon{0}' -f [IO.Path]::GetRandomFileName() } -PassThru |
    Remove-Item -Recurse -Force
