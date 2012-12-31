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

# IIS
Add-Type -AssemblyName "System.Web"
$microsoftWebAdministrationPath = Join-Path $env:SystemRoot system32\inetsrv\Microsoft.Web.Administration.dll
if( (Test-Path -Path $microsoftWebAdministrationPath -PathType Leaf) )
{
    Add-Type -Path $microsoftWebAdministrationPath
}

# Services
Add-Type -AssemblyName System.ServiceProcess

$CarbonBinDir = Join-Path $PSScriptRoot bin -Resolve

$TrustedHostsPath = 'WSMan:\localhost\Client\TrustedHosts'

Get-ChildItem $PSScriptRoot *.ps1 -Recurse | 
    Where-Object { $_.BaseName -ne 'Import-Carbon' -and $_.Extension -eq '.ps1' } |
    ForEach-Object {
        Write-Debug ("Importing sub-module {0}." -f $_.FullName)
        . $_.FullName
    }

$CarbonImported = $true

Export-ModuleMember -Function * -Cmdlet * -Variable CarbonImported -Alias *
