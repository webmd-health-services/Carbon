<#
.SYNOPSIS
Installs the get-carbon.org website on the local computer.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

if( -not (Get-Module Carbon) )
{
    Import-Module (Join-Path $PSScriptRoot Carbon -Resolve)
}

$websitePath = Join-Path $PSScriptRoot Website -Resolve
Install-IisWebsite -Name 'get-carbon.org' -Path $websitePath -Bindings 'http/*:80:'
Grant-Permissions -Identity Everyone -Permissions ReadAndExecute -Path $websitePath