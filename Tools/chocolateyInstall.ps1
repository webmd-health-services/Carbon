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
