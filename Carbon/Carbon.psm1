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

$startedAt = Get-Date
function Write-Timing
{
    param(
        [Parameter(Position=0)]
        $Message
    )

    $now = Get-Date
    Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $startedAt),$Message)
}

if( -not (Test-Path 'variable:IsWindows') )
{
    $IsWindows = $true
    $IsLinux = $IsMacOS = $false
}

Write-Timing ('BEGIN')
$CarbonBinDir = Join-Path -Path $PSScriptRoot -ChildPath 'bin' -Resolve
$carbonAssemblyDir = Join-Path -Path $CarbonBinDir -ChildPath 'fullclr' -Resolve

$IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
if( $IsPSCore )
{
    $carbonAssemblyDir = Join-Path -Path $CarbonBinDir -ChildPath 'coreclr' -Resolve
}

Write-Timing ('Loading Carbon assemblies from "{0}".' -f $carbonAssemblyDir)
Get-ChildItem -Path (Join-Path -Path $carbonAssemblyDir -ChildPath '*') -Filter 'Carbon*.dll' -Exclude 'Carbon.Iis.dll' |
    ForEach-Object { Add-Type -Path $_.FullName }

Write-Timing ('Dot-sourcing Test-TypeDataMember.')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\Test-TypeDataMember.ps1' -Resolve)
Write-Timing ('Dot-sourcing Use-CallerPreference.')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\Use-CallerPreference.ps1' -Resolve)


$doNotImport = @{ }

if( -not $IsWindows -or ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) ) 
{
    $doNotImport['Initialize-Lcm.ps1'] = $true
}

$functionRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Functions' -Resolve

# Active Directory

# COM
$ComRegKeyPath = 'hklm:\software\microsoft\ole'

# Cryptography
Write-Timing ('Adding System.Security assembly.')
Add-Type -AssemblyName 'System.Security'

# FileSystem
Write-Timing ('Adding Ionic.Zip assembly.')
Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath 'Ionic.Zip.dll' -Resolve)


# IIS
$exportIisFunctions = $false
if( (Test-Path -Path 'env:SystemRoot') )
{
    Write-Timing ('Adding System.Web assembly.')
    Add-Type -AssemblyName "System.Web"
    $microsoftWebAdministrationPath = Join-Path -Path $env:SystemRoot -ChildPath 'system32\inetsrv\Microsoft.Web.Administration.dll'
    if( (Test-Path -Path $microsoftWebAdministrationPath -PathType Leaf) )
    {
        $exportIisFunctions = $true
        if( -not $IsPSCore )
        {
            Write-Timing ('Adding Microsoft.Web.Administration assembly.')
            Add-Type -Path $microsoftWebAdministrationPath
            Write-Timing ('Adding Carbon.Iis assembly.')
            Add-Type -Path (Join-Path -Path $carbonAssemblyDir -ChildPath 'Carbon.Iis.dll' -Resolve)
        }

        if( -not (Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Site' -MemberName 'PhysicalPath') )
        {
            Write-Timing ('Updating Microsoft.Web.Administration.Site type data.')
            Update-TypeData -TypeName 'Microsoft.Web.Administration.Site' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value { 
                    $this.Applications |
                        Where-Object { $_.Path -eq '/' } |
                        Select-Object -ExpandProperty VirtualDirectories |
                        Where-Object { $_.Path -eq '/' } |
                        Select-Object -ExpandProperty PhysicalPath
                }
        }

        if( -not (Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Application' -MemberName 'PhysicalPath') )
        {
            Write-Timing ('Updating Microsoft.Web.Administration.Application type data.')
            Update-TypeData -TypeName 'Microsoft.Web.Administration.Application' -MemberType ScriptProperty -MemberName 'PhysicalPath' -Value { 
                    $this.VirtualDirectories |
                        Where-Object { $_.Path -eq '/' } |
                        Select-Object -ExpandProperty PhysicalPath
                }
        }
    }
}

if( -not $exportIisFunctions )
{
    Write-Timing ('Filtering out IIS functions.')
    Get-ChildItem -Path $functionRoot -Filter '*-Iis*.ps1' |
        ForEach-Object { $doNotImport[$_.Name] = $true }
}

# MSMQ
if( $IsWindows )
{
    Write-Timing ('Adding System.ServiceProcess assembly.')
    Add-Type -AssemblyName 'System.ServiceProcess'
    Write-Timing ('Adding System.Messaging assembly.')
    Add-Type -AssemblyName 'System.Messaging'
}

#PowerShell
$TrustedHostsPath = 'WSMan:\localhost\Client\TrustedHosts'

# Services
Write-Timing ('Adding System.ServiceProcess assembly.')
Add-Type -AssemblyName 'System.ServiceProcess'

# Users and Groups
Write-Timing ('Adding System.DirectoryServices.AccountManagement assembly.')
Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'

# Windows Features
Write-Timing ('Checking if servermanagercmd.exe exists.')
$useServerManager = (Get-Command -Name 'servermanagercmd.exe' -ErrorAction Ignore) -ne $null
$useWmi = $false
$useOCSetup = $false
if( -not $useServerManager )
{
    Write-Timing ('Checking if Win32_OptionalFeature WMI class is available.')
    $win32OptionalFeatureClass = $null
    if( (Get-Command -Name 'Get-CimClass' -ErrorAction Ignore) )
    {
        $win32OptionalFeatureClass = Get-CimClass -ClassName 'Win32_OptionalFeature'
    }
    elseif( Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore )
    {
        $win32OptionalFeatureClass = Get-WmiObject -List | Where-Object { $_.Name -eq 'Win32_OptionalFeature' }
    }
        
    $useWmi = $win32OptionalFeatureClass -ne $null
    Write-Timing ('Checking if ocsetup.exe exists.')
    $useOCSetup = (Get-Command -Name 'ocsetup.exe' -ErrorAction Ignore ) -ne $null
}

$windowsFeaturesNotSupported = (-not ($useServerManager -or ($useWmi -and $useOCSetup) ))
$supportNotFoundErrorMessage = 'Unable to find support for managing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'


# Extended Type
if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'GetCarbonFileInfo') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (GetCarbonFileInfo).')
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

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'FileIndex') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (FileIndex).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'FileIndex' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'FileIndex' )
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'LinkCount') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (LinkCount).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'LinkCount' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'LinkCount' )
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'VolumeSerialNumber') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (ColumeSerialNumber).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'VolumeSerialNumber' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'VolumeSerialNumber' )
    }
}

Write-Timing ('Dot-sourcing functions.')
Get-ChildItem -Path $functionRoot -Filter '*.ps1' | 
                    Where-Object { -not $doNotImport.Contains($_.Name) } |
                    ForEach-Object {
                        Write-Verbose ("Importing function {0}." -f $_.FullName)
                        . $_.FullName | Out-Null
                    }

Write-Timing ('Testing the module manifest.')
try
{
    $module = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve)
    if( -not $module )
    {
        return
    }

    Write-Timing ('Creating aliases.')
    [string[]]$functionNames = $module.ExportedFunctions.Keys
    foreach( $functionName in $functionNames )
    {
        $oldFunctionName = $functionName -replace '-C','-'
        Set-Alias -Name $oldFunctionName -Value $functionName
    }

    Write-Timing ('Exporting module members.')
    Export-ModuleMember -Alias '*' -Function $functionNames
}
finally
{
    Write-Timing ('DONE')
}
