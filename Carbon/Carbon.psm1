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

# Used to detect how to manager windows features. Determined at run time to improve import speed.
$windowsFeaturesNotSupported = $null
$useServerManager = $null
$useOCSetup = $false
$supportNotFoundErrorMessage = 'Unable to find support for managing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'

$IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
if( $IsPSCore )
{
    $carbonAssemblyDir = Join-Path -Path $CarbonBinDir -ChildPath 'coreclr' -Resolve
}

Write-Timing ('Loading Carbon assemblies from "{0}".' -f $carbonAssemblyDir)
Get-ChildItem -Path (Join-Path -Path $carbonAssemblyDir -ChildPath '*') -Filter 'Carbon*.dll' -Exclude 'Carbon.Iis.dll' |
    ForEach-Object { Add-Type -Path $_.FullName }

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
    }
}

Write-Timing ('Dot-sourcing functions.')
$functionRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Functions' -Resolve

Get-ChildItem -Path (Join-Path -Path $functionRoot -ChildPath '*') -Filter '*.ps1' -Exclude '*Iis*','Initialize-Lcm.ps1' | 
    ForEach-Object { 
        . $_.FullName 
    }

if( $IsWindows -and [Environment]::Is64BitOperatingSystem -and [Environment]::Is64BitProcess ) 
{
    . (Join-Path -Path $functionRoot -ChildPath 'Initialize-Lcm.ps1')
}

if( $exportIisFunctions )
{
    Write-Timing ('Dot-sourcing IIS functions.')
    Get-ChildItem -Path $functionRoot -Filter '*Iis*.ps1' |
        ForEach-Object { . $_.FullName }
        
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
