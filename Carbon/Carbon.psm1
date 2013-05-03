# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$CarbonBinDir = Join-Path $PSScriptRoot bin -Resolve

# Active Directory

# COM
$ComRegKeyPath = 'hklm:\software\microsoft\ole'

# Cryptography
Add-Type -AssemblyName System.Security

# IIS
Add-Type -AssemblyName "System.Web"
$microsoftWebAdministrationPath = Join-Path $env:SystemRoot system32\inetsrv\Microsoft.Web.Administration.dll
if( (Test-Path -Path $microsoftWebAdministrationPath -PathType Leaf) )
{
    Add-Type -Path $microsoftWebAdministrationPath
    Add-Type -Path (Join-Path $CarbonBinDir Carbon.Iis.dll -Resolve)
}

# MSMQ
Add-Type -AssemblyName System.ServiceProcess
Add-Type -AssemblyName System.Messaging

#PowerShell
$TrustedHostsPath = 'WSMan:\localhost\Client\TrustedHosts'

# Services
Add-Type -AssemblyName System.ServiceProcess

# Windows Features
$useServerManager = ((Get-Command -CommandType 'Application' -Name 'servermanagercmd*.exe' | Where-Object { $_.Name -eq 'servermanagercmd.exe' }) -ne $null)
$useWmi = $false
$useOCSetup = $false
if( -not $useServerManager )
{
    $useWmi = ((Get-WmiObject -Class Win32_OptionalFeature -ErrorAction SilentlyContinue) -ne $null)
    $useOCSetup = ((Get-Command 'ocsetup.exe' -ErrorAction SilentlyContinue) -ne $null)
}

$windowsFeaturesNotSupported = (-not ($useServerManager -or ($useWmi -and $useOCSetup) ))
$supportNotFoundErrorMessage = 'Unable to find support for managing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'

Get-Item (Join-Path $PSScriptRoot *\*.ps1) | 
    ForEach-Object {
        Write-Debug ("Importing sub-module {0}." -f $_.FullName)
        . $_.FullName
    }

Export-ModuleMember -Function * -Cmdlet * -Alias *
