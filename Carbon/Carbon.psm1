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

#Requires -Version 4

$CarbonBinDir = Join-Path -Path $PSScriptRoot -ChildPath 'bin' -Resolve

. (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\Test-TypeDataMember.ps1' -Resolve)
. (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\Use-CallerPreference.ps1' -Resolve)

$doNotImport = @{ }

if( [Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess ) 
{
    $doNotImport = 'Initialize-Lcm.ps1'
}

$functionRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Functions' -Resolve

# Active Directory

# COM
$ComRegKeyPath = 'hklm:\software\microsoft\ole'

# Cryptography
Add-Type -AssemblyName 'System.Security'

# FileSystem
Add-Type -Path (Join-Path -Path $PSScriptRoot -ChildPath 'bin\Ionic.Zip.dll' -Resolve)


# IIS
Add-Type -AssemblyName "System.Web"
$microsoftWebAdministrationPath = Join-Path -Path $env:SystemRoot -ChildPath 'system32\inetsrv\Microsoft.Web.Administration.dll'
if( (Test-Path -Path $microsoftWebAdministrationPath -PathType Leaf) )
{
    Add-Type -Path $microsoftWebAdministrationPath
    Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath 'Carbon.Iis.dll' -Resolve)

    if( -not (Test-TypeDataMember -TypeName 'Microsoft.Web.Administration.Site' -MemberName 'PhysicalPath') )
    {
        Update-TypeData -TypeName 'Microsoft.Web.Administration.Site' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value { 
                $this.Applications |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty VirtualDirectories |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty PhysicalPath
            }
    }

    if( -not (Test-TypeDataMember -TypeName 'Microsoft.Web.Administration.Application' -MemberName 'PhysicalPath') )
    {
        Update-TypeData -TypeName 'Microsoft.Web.Administration.Application' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value { 
                $this.VirtualDirectories |
                    Where-Object { $_.Path -eq '/' } |
                    Select-Object -ExpandProperty PhysicalPath
            }
    }
}
else
{
    Get-ChildItem -Path $functionRoot -Filter '*-Iis*.ps1' |
        ForEach-Object { $doNotImport[$_.Name] = $true }
}

# MSMQ
Add-Type -AssemblyName 'System.ServiceProcess'
Add-Type -AssemblyName 'System.Messaging'

#PowerShell
$TrustedHostsPath = 'WSMan:\localhost\Client\TrustedHosts'

# Services
Add-Type -AssemblyName 'System.ServiceProcess'

# Users and Groups
Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'

# Windows Features
$useServerManager = (Get-Command -Name 'servermanagercmd.exe' -ErrorAction Ignore) -ne $null
$useWmi = $false
$useOCSetup = $false
if( -not $useServerManager )
{
    $useWmi = (Get-WmiObject -List -Class 'Win32_OptionalFeature') -ne $null
    $useOCSetup = (Get-Command -Name 'ocsetup.exe' -ErrorAction Ignore ) -ne $null
}

$windowsFeaturesNotSupported = (-not ($useServerManager -or ($useWmi -and $useOCSetup) ))
$supportNotFoundErrorMessage = 'Unable to find support for managing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'


# Extended Type
if( -not (Test-TypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'GetCarbonFileInfo') )
{
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptMethod -MemberName 'GetCarbonFileInfo' -Value {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the Carbon file info property to get.
            $Name
        )

        Set-StrictMode -Version 'Latest'

        if( -not $this.Exists )
        {
            return
        }

        if( -not ($this | Get-Member -Name 'CarbonFileInfo') )
        {
            $this | Add-Member -MemberType NoteProperty -Name 'CarbonFileInfo' -Value (New-Object 'Carbon.IO.FileInfo' $this.FullName)
        }

        if( $this.CarbonFileInfo | Get-Member -Name $Name )
        {
            return $this.CarbonFileInfo.$Name
        }
    }
}

if( -not (Test-TypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'FileIndex') )
{
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'FileIndex' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'FileIndex' )
    }
}

if( -not (Test-TypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'LinkCount') )
{
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'LinkCount' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'LinkCount' )
    }
}

if( -not (Test-TypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'VolumeSerialNumber') )
{
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'VolumeSerialNumber' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'VolumeSerialNumber' )
    }
}

Get-ChildItem -Path $functionRoot -Filter '*.ps1' | 
                    Where-Object { -not $doNotImport.Contains($_.Name) } |
                    ForEach-Object {
                        Write-Verbose ("Importing function {0}." -f $_.FullName)
                        . $_.FullName | Out-Null
                    }

$module = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve)
if( -not $module )
{
    return
}

Export-ModuleMember -Alias '*' -Function ([string[]]$module.ExportedFunctions.Keys)