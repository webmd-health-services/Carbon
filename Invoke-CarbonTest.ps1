<#
.SYNOPSIS
Runs Carbon tests.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]
    $Path,

    [Parameter()]
    [string[]]
    $Test,

    [Switch]
    $Recurse
)

#Requires -Version 3
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$installRoot = Get-PowerShellModuleInstallPath
$carbonModuleRoot = Join-Path -Path $installRoot -ChildPath 'Carbon'
Install-Junction -Link $carbonModuleRoot -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon' -Resolve)
Clear-DscLocalResourceCache

$bladeTestParam = @{ }
if( $Test )
{
    $bladeTestParam.Test = $Test
}

try
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Blade\blade.ps1' -Resolve) -Path $Path @bladeTestParam -Recurse:$Recurse
}
finally
{
    $installRoot = Get-PowerShellModuleInstallPath
    #Remove-Junction -Path $carbonModuleRoot
}