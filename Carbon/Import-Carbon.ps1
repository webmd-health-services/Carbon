<#
.SYNOPSIS
Imports the Carbon module.

.DESCRIPTION
Intelligently imports the Carbon module, re-importing it if needed. Carbon will be re-imported if:

 * a different version is currently loaded
 * any of Carbon's files were modified since it was last imported with this script
 * the `Force` switch is set
 * or the `CARBON_ENV` environment variable is set to `developer`

.EXAMPLE
Import-Carbon.ps1

Imports the Carbon module, re-loading it if its already loaded.
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

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter()]
    [string]
    # The prefix to use on all the module's functions, cmdlets, etc.
    $Prefix,

    [Switch]
    # Reload the module no matter what.
    $Force
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$carbonPsd1Path = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve

$startedAt = Get-Date
$loadedModule = Get-Module 'Carbon'
if( $loadedModule )
{
    if( -not $Force -and ($loadedModule | Get-Member 'ImportedAt') )
    {
        $importedAt = $loadedModule.ImportedAt
        $newFiles = Get-ChildItem -Path $PSScriptRoot |
                        Where-Object { $_.LastWriteTime -gt $importedAt }
        if( $newFiles )
        {
            Write-Verbose ('Reloading Carbon module. The following files were modified since {0}:{1} * {2}' -f $importedAt,([Environment]::NewLine),($newFiles -join ('{0} * ' -f ([Environment]::NewLine)))) -Verbose
            $Force = $true
        }
    }

    $thisModuleManifest = Test-ModuleManifest -Path $carbonPsd1Path
    if( $thisModuleManifest )
    {
        if( -not $Force -and $thisModuleManifest.Version -ne $loadedModule.Version )
        {
            Write-Verbose ('Reloading Carbon module. Module from {0} at version {1} not equal to module from {2} at version {3}.' -f $loadedModule.ModuleBase,$loadedModule.Version,(Split-Path -Parent -Path $thisModuleManifest.Path),$thisModuleManifest.Version) -Verbose
            $Force = $true
        }
    }

    if( -not $Force -and $env:CARBON_ENV -eq 'Developer' )
    {
        Write-Verbose ('Reloading Carbon module. CARBON_ENV environment variable set to ''{0}''.' -f $env:CARBON_ENV) -Verbose
        $Force = $true
    }
}

$importModuleParams = @{ }
if( $Prefix )
{
    $importModuleParams.Prefix = $Prefix
}

Import-Module $carbonPsd1Path -ErrorAction Stop -Force:$Force -Verbose:$false @importModuleParams

Get-Module -Name 'Carbon' | Add-Member -MemberType NoteProperty -Name 'ImportedAt' -Value (Get-Date) -Force
