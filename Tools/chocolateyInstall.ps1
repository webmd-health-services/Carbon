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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)

$installPath = Get-PowerShellModuleInstallPath
$installPath = Join-Path -Path $installPath -ChildPath 'Carbon'

$source = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve
if( -not $source )
{
    return
}

if( (Test-Path -Path $installPath -PathType Container) )
{
    $newName = 'Carbon{0}' -f [IO.Path]::GetRandomFileName()
    Write-Verbose ('Renaming existing Carbon module: {0} -> {1}' -f $installPath,$newName)
    Rename-Item -Path $installPath $newName
    $oldModulePath = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath $newName
    if( Test-Path -Path $oldModulePath -PathType Container )
    {
        Write-Verbose ('Removing old Carbon module: {0}' -f $oldModulePath)
        Remove-Item -Path $oldModulePath -Force -Recurse
    }
    else
    {
        return
    }

    if( Test-Path -Path $oldModulePath -PathType Container )
    {
        return
    }
}

Write-Verbose -Message ('Installing Carbon: {0} -> {1}' -f $source,$installPath)
Copy-Item -Path $source -Destination $installPath -Recurse
