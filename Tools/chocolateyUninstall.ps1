<#
.SYNOPSIS
Chocolately install script for Carbon.
#>
[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

# Use Get-Item so we can mock it
Get-Item -Path 'env:PSModulePath' |
    Select-Object -ExpandProperty 'Value'-ErrorAction Ignore |
    ForEach-Object { $_ -split ';' } |
    Join-Path -ChildPath 'Carbon' |
    Where-Object { Test-Path -Path $_ -PathType Container } |
    Rename-Item -NewName { 'Carbon{0}' -f [IO.Path]::GetRandomFileName() } -PassThru |
    Remove-Item -Recurse -Force
