<#
.SYNOPSIS
Packages and publishes Carbon packages.
#>
[CmdletBinding()]
param(
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

$version = [Version] (Get-Content (Join-Path $PSScriptRoot Version.txt -Resolve))

Copy-Item (Join-Path $PSScriptRoot LICENSE -Resolve) (Join-Path $PSScriptRoot Carbon\ -Resolve)

$carbonZipFileName = "Carbon-$version.zip"
$zipAppPath = Join-Path $PSScriptRoot Tools\7-Zip\7za.exe -Resolve

Push-Location $PSScriptRoot
try
{
    if( Test-Path $carbonZipFileName -PathType Leaf )
    {
        Remove-Item $carbonZipFileName
    }
    & $zipAppPath a $carbonZipFileName .\Carbon
}
finally
{
    Remove-Item (Join-Path $PSScriptRoot Carbon\LICENSE)
    Pop-Location
}