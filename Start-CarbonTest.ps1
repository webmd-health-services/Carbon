<#
.SYNOPSIS
Gets the Carbon tests ready to run.

.DESCRIPTION
The `Start-CarbonTest.ps1` script makes sure that Carbon can be loaded automatically by the local configuration manager. When running under Appveyor, it adds the current directory to the `PSModulePath` environment variable. Otherwise, it creates a junction to Carbon into the Modules directory where modules get installed.

Run `Complete-CarbonTest.ps1` to reverse the changes this script makes.
#>
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
[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$installRoot = Get-CPowerShellModuleInstallPath
$carbonModuleRoot = Join-Path -Path $installRoot -ChildPath 'Carbon'
Install-CJunction -Link $carbonModuleRoot -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon' -Resolve) #| Format-Table | Out-String | Write-Verbose

if( (Test-Path -Path 'env:APPVEYOR') )
{
    Grant-Permission -Path ($PSScriptRoot | Split-Path) -Identity 'Everyone' -Permission 'FullControl'
    Grant-Permission -Path ('C:\Users\appveyor\Documents') -Identity 'Everyone' -Permission 'FullControl'

    $wmiprvse = Get-Process -Name 'wmiprvse'
    #$wmiprvse | Format-Table
    $wmiprvse | Stop-Process -Force
    #Get-Process -Name 'wmiprvse' | Format-Table
}

configuration Yolo
{
    node 'localhost'
    {
        Script AvailableModules
        {
            GetScript = {
                return @{ PID = $PID }

            }

            SetScript = {
            
            }

            TestScript =  {
                $PID | Write-Verbose
                Get-Module -ListAvailable | Format-Table | Out-String | Write-Verbose
                Get-DscResource | Format-Table | Out-String | Write-Verbose
                return $true
            }

        }
    }
}

#$dscOutputRoot = Join-Path -Path $PSScriptRoot -ChildPath '.output\Yolo'
#& Yolo -OutputPath $dscOutputRoot
#Start-DscConfiguration -Wait -Verbose -Path $dscOutputRoot -ComputerName 'localhost'

#Get-Module -ListAvailable | Format-Table

#$modulePaths = $env:PSModulePath -split ';'
#$modulePaths

#Get-ChildItem $modulePaths | Format-Table

#Get-DscResource | Format-Table

Clear-CDscLocalResourceCache
