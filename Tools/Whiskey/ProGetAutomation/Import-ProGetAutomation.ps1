[CmdletBinding()]
param(
)

if( (Get-Module -Name 'ProGetAutomation') )
{
    Remove-Module -Name 'ProGetAutomation' -Force
}

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'ProGetAutomation.psd1' -Resolve)
