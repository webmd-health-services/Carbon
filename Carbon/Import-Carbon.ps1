<#
.SYNOPSIS
Imports the Carbon module.

.DESCRIPTION
Imports the Carbon module.  If the Carbon module is already loaded, it will remove it and then reloaded.  If Carbon is present as a sub-module of Carbon, Carbon can't be re-loaded so a warning is output instead.  To hide the warning, use the `-Quiet` parameter.
#>
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
    $varModule = Get-Module $var.Module
    if( -not $Quiet )
    {
        Write-Warning ("Carbon already present as nested module in {0} module ({1})." -f $var.Module, $varModule.ModuleBase)    
    }
    return
}

Import-Module (Join-Path $PSScriptRoot ..\Carbon -Resolve)