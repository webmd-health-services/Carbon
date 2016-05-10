<#
.SYNOPSIS
Runs Carbon tests.
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

# Let's get full stack traces in our errors.
$prependFormats = @(
                        (Join-Path -Path $PSScriptRoot -ChildPath 'System.Management.Automation.ErrorRecord.format.ps1xml'),
                        (Join-Path -Path $PSScriptRoot -ChildPath 'System.Exception.format.ps1xml')
                    )
Update-FormatData -PrependPath $prependFormats

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$installRoot = Get-PowerShellModuleInstallPath
$carbonModuleRoot = Join-Path -Path $installRoot -ChildPath 'Carbon'
Install-Junction -Link $carbonModuleRoot -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon' -Resolve) | Format-Table | Out-String | Write-Verbose
Clear-DscLocalResourceCache

$bladeTestParam = @{ }
if( $Test )
{
    $bladeTestParam.Test = $Test
}

try
{
    $xmlLogPath = Split-Path -Qualifier -Path $PSScriptRoot
    $xmlLogPath = Join-Path -Path $xmlLogPath -ChildPath 'BuildOutput\Carbon\CodeQuality\Carbon.blade.xml'
    & (Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Blade\blade.ps1' -Resolve) -Path $Path -XmlLogPath $xmlLogPath @bladeTestParam -Recurse:$Recurse -PassThru:$PassThru

    $xmlLogPath = Join-Path -Path (Split-Path -Parent -Path $xmlLogPath) -ChildPath 'Carbon.pester.xml'
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Pester\3.3.14\Pester.psd1' -Resolve)
    $result = Invoke-Pester -Script $Path -OutputFile $xmlLogPath -OutputFormat LegacyNUnitXml -PassThru |
                    Select-Object -Last 1
    if( $result.FailedCount )
    {
        Write-Error -Message ('{0} Pester tests failed. Check the NUnit reports for more details.' -f $result.FailedCount)
    }
}
finally
{
    Uninstall-Junction -Path $carbonModuleRoot
}
