<#
.SYNOPSIS
Example build server setup script.

.DESCRIPTION
This sample script shows how to setup a simple build server running CruiseControl.NET as a Windows Service.
#>
[CmdletBinding()]
param(
)

$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-StrictMode -Version Latest

& (Join-Path $PSScriptRoot ..\Import-Carbon.ps1 -Resolve)

$ccservicePath = 'Path\to\ccservice.exe'
$ccserviceUser = 'example.com\CCServiceUser'
$ccservicePassword = 'CCServiceUserPassword'
Install-Service -Name CCService -Path $ccservicePath -Username $ccserviceUser -Password $ccservicePassword

$pathToVersionControlRepository = 'Path\to\version\control\repository'
$pathToBuildOutput = 'Path\to\build\output'
Grant-Permissions -Identity $ccserviceUser -Permissions FullControl -Path $pathToVersionControlRepository
Grant-Permissions -Identity $ccserviceUser -Permissions FullControl -Path $pathToBuildOutput