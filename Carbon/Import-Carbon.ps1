<#
.SYNOPSIS
Imports the Carbon module.

.DESCRIPTION
Imports the Carbon module.  If the Carbon module is already loaded, it will remove it and then reloaded.  If Carbon is present as a sub-module of Carbon, Carbon can't be re-loaded so a warning is output instead.  To hide the warning, use the `-Quiet` parameter.
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
    [Switch]
    # Don't show any warnings if Carbon can't be unloaded and re-loaded.
    $Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

if( (Get-Module Carbon) )
{
    Remove-Module Carbon
}
elseif( Test-Path "variable:CarbonImported" )
{
    $var = Get-Variable 'CarbonImported'
    if( -not $Quiet )
    {
        Get-Module $var.Module | 
            ForEach-Object {
                $message = "Carbon already present as nested module in {0} module ({1})." -f $var.Module, $_.ModuleBase
                Write-Warning $message
            }
    }
    return
}

Import-Module (Join-Path $PSScriptRoot ..\Carbon -Resolve)