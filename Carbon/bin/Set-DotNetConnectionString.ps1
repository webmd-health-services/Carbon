<#
.SYNOPSIS
Internal.  Use `Set-DotNetConnectionString` function instead.
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
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $Name,

    [Parameter(Mandatory=$true,Position=1)]
    [string]
    $Value,

    [Parameter(Position=2)]
    [string]
    $ProviderName
)

Set-StrictMode -Version Latest
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
. (Join-Path $PSScriptRoot ..\Text\ConvertFrom-Base64.ps1 -Resolve)

$Name = $Name | ConvertFrom-Base64
$Value = $Value | ConvertFrom-Base64
$ProviderName = $ProviderName | ConvertFrom-Base64

Add-Type -AssemblyName System.Configuration

$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
$connectionStrings = $config.ConnectionStrings.ConnectionStrings
if( $connectionStrings[$Name] )
{
    $connectionStrings.Remove( $Name )
}

$args = @( $Name, $Value )
if( $ProviderName )
{
    $args += $ProviderName
}
$connectionString = New-Object Configuration.ConnectionStringSettings $args
$connectionStrings.Add( $connectionString )

$config.Save()
