<#
.SYNOPSIS
**INTERNAL. DO NOT USE** Standalone wrapper script for Carbon's `Unprotect-String` function to make it easier to decrypt a string as a custom user.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]
    # A base-64 encoded string that was protected with Carbon's `protect-String`.
    $ProtectedString
)

Set-StrictMode -Version 'Latest'

Add-Type -AssemblyName 'System.Security'

. (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Cryptography\Unprotect-String.ps1' -Resolve)

Unprotect-String -ProtectedString $ProtectedString
