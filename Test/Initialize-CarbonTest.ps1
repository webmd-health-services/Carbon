[CmdletBinding()]
param(
    [Switch]
    $ForDsc
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)

if( $ForDsc )
{
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force
}
else
{
    if( (Get-Module -Name 'CarbonDscTest') )
    {
        Remove-Module -Name 'CarbonDscTest' -Force
    }
}
