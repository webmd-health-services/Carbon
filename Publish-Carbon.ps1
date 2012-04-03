<#
.SYNOPSIS
Packages and publishes Carbon packages.
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

ise [CmdletBinding()]
param(
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

$version = [Version] (Get-Content (Join-Path $PSScriptRoot Version.txt -Resolve))

Copy-Item (Join-Path $PSScriptRoot LICENSE -Resolve) (Join-Path $PSScriptRoot Carbon\ -Resolve)

$carbonZipFileName = "Carbon-$version.zip"
$zipAppPath = Join-Path $PSScriptRoot Tools\7-Zip\7za.exe -Resolve

Push-Location $PSScriptRoot
try
{
    if( Test-Path $carbonZipFileName -PathType Leaf )
    {
        Remove-Item $carbonZipFileName
    }
    & $zipAppPath a $carbonZipFileName .\Carbon
}
finally
{
    Remove-Item (Join-Path $PSScriptRoot Carbon\LICENSE)
    Pop-Location
}