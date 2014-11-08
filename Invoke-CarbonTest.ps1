<#
.SYNOPSIS
Runs Carbon tests.
#>
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
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]
    $Path,

    [Parameter()]
    [string[]]
    $Test,

    [Switch]
    $Recurse,

    [Switch]
    $PassThru
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$installRoot = Get-PowerShellModuleInstallPath
$carbonModuleRoot = Join-Path -Path $installRoot -ChildPath 'Carbon'
Install-Junction -Link $carbonModuleRoot -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon' -Resolve) | Format-Table | Out-String | Write-Verbose
Clear-DscLocalResourceCache -Verbose:$VerbosePreference

$bladeTestParam = @{ }
if( $Test )
{
    $bladeTestParam.Test = $Test
}

$bladePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Blade\blade.ps1' -Resolve

try
{
    $Path | ForEach-Object {

            Get-Item -Path $_

            if( $Recurse -and (Test-Path -Path $_ -PathType Container) )
            {
                Get-ChildItem -Path $_ -Directory
            }

        } | ForEach-Object {
            Start-Job -Name $_.FullName -ScriptBlock { 
                param(
                    $BladePath,
                    $Path,
                    [hashtable]
                    $BladeTestParam,
                    [Switch]
                    $Recurse,
                    [Switch]
                    $PassThru
                )

                Write-Verbose $Path
                & $BladePath -Path $Path @BladeTestParam -PassThru:$PassThru
            } -ArgumentList $bladePath,$_.FullName,$bladeTestParam,$Recurse,$PassThru
        } |
            Wait-Job |
            ForEach-Object {
                $job = $_

                $job.Name
                Receive-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job

                foreach( $errorItem in $Error )
                {
                    $errorItem | Out-String | ForEach-Object { $_.TrimEnd() }
                    if( $error | Get-Member -Name 'ScriptStackTrace' )
                    {
                        $errorItem.ScriptStackTrace | Out-String 
                    }
                }
                $Error.Clear()
            }
}
finally
{
    $installRoot = Get-PowerShellModuleInstallPath
    Remove-Junction -Path $carbonModuleRoot
}
