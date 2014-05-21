<#
.SYNOPSIS
**INTERNAL. DO NOT USE**
#>
param(
    [Parameter(Mandatory=$true)]
    [string]
    $ProtectedString
)

Set-StrictMode -Version 'Latest'

Add-Type -AssemblyName 'System.Security'

. (Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\Protect-String.ps1' -Resolve)
. (Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\Unprotect-String.ps1' -Resolve)

$string = Unprotect-String -ProtectedString $ProtectedString
Protect-String -String $string -ForUser
