<#
.SYNOPSIS
Saves the Carbon signing key.

.DESCRIPTION
Carbon's signing key is required to build Carbon assemblies. On the build server, the key is stored in a secure environment variable. This script grabs the environment variable and saves it as the signing key.
#>
[CmdletBinding()]
param(

)

#Requires -Version 4
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$base64Snk = $env:SNK
if( -not $base64Snk )
{
    Write-Error -Message ('Signing key environment variable not found or doesn''t have a value.')
    exit 1
}

$snkPath = Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.snk'
[IO.File]::WriteAllBytes($snkPath, [Convert]::FromBase64String($base64Snk))
