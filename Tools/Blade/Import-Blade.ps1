<#
.SYNOPSIS
Imports the Blade module.

.DESCRIPTION
Normally, you shouldn't need to import Blade.  Usually, you'll just call the `blade.ps1` script directly and it will import Blade for you.

If Blade is already imported, it will be removed and then re-imported.

.EXAMPLE
Import-Blade.ps1

Demonstrates how to import the Blade module.
#>
param(
)

#Requires -Version 3
Set-StrictMode -Version 'Latest'

& {
    $originalVerbosePreference = $Global:VerbosePreference
    $Global:VerbosePreference = [Management.Automation.ActionPreference]::SilentlyContinue

    if( (Get-Module -Name 'Blade') )
    {
        Remove-Module 'Blade'
    }

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Blade.psd1' -Resolve)
}
