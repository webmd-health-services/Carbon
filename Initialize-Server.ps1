<#
.SYNOPSIS
Initializes a server and gets it ready to run Carbon tests.
#>
[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'
$PSCommandPath = $MyInvocation.MyCommand.Definition
$PSScriptRoot = Split-Path -Parent -Path $PSCommandPath

$os = Get-WmiObject -Class 'Win32_OperatingSystem'

# Windows 2008
$osVersion = [version]$os.Version
if( $osVersion.Major -eq 6 -and $osVersion.Minor -eq 1 )
{
    Import-Module -Name 'ServerManager'
    Add-WindowsFeature -Name 'PowerShell-ISE','MSMQ-Server','Net-Framework-Core','Web-Server'
}
# Windows 2012 R2
elseif( $osVersion.Major -eq 6 -and $osVersion.Minor -eq 3 )
{
    Install-WindowsFeature -Name 'Web-Server','MSMQ-Server'
}

choco install 'sysinternals' -y
choco install 'conemu' -y

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1')

Uninstall-IisWebsite -Name 'Default Web Site'
