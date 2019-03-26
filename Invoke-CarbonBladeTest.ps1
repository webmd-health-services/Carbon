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

$bladeTestParam = @{ }
if( $Test )
{
    $bladeTestParam['Test'] = $Test
}

$uploadTestResults = $false 
$uploadUri = ''
$isAppVeyor = Test-Path -Path 'env:APPVEYOR'
if( $isAppVeyor )
{
    $uploadTestResults = $true
    $uploadUri = 'https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID 
}

$testsFailed = $false

$xmlLogPath = Join-Path -Path $PSScriptRoot -ChildPath '.output\Carbon.blade.xml'
$bladePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Blade\blade.ps1' -Resolve
& $bladePath -Path $Path -XmlLogPath $xmlLogPath @bladeTestParam -Recurse:$Recurse -PassThru:$PassThru |
    Format-Table -Property Duration,FixtureName,Name
if( $PassThru )
{
    $LastBladeResult
}

if( $isAppVeyor )
{
    & { 
            $LastBladeResult.Failures
            $LastBladeResult.Errors
    } | Format-List
}

if( $LastBladeResult.Errors -or $LastBladeResult.Failures )
{
    $testsFailed = $true
}

if( $uploadTestResults )
{
    $webClient = New-Object 'Net.WebClient'
    $webClient.UploadFile($uploadUri, $xmlLogPath)
}

if( $testsFailed )
{
    throw 'Blade tests failed.'
}
