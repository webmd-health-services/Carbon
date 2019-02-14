<#
.SYNOPSIS
Packages and publishes Carbon packages.
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

[CmdletBinding(DefaultParameterSetName='Build')]
param(
    [Parameter(Mandatory=$true,ParameterSetName='Clean')]
    [Switch]
    # Runs the build in clean mode, which removes any files, tools, packages created by previous builds.
    $Clean,

    [Parameter(Mandatory=$true,ParameterSetName='Initialize')]
    [Switch]
    # Initializes the repository.
    $Initialize,
    
    [string]
    $PipelineName,

    [string]
    $Configuration
)

#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Whiskey\Import-Whiskey.ps1' -Resolve)

$optionalParams = @{ }
if( $PipelineName )
{
    $optionalParams['PipelineName'] = $PipelineName
}

if( $Clean )
{
    $optionalParams['Clean'] = $true
}

if( $Initialize )
{
    $optionalParams['Initialize'] = $true
}

$whiskeyYmlPath = Join-Path -Path $PSScriptRoot -ChildPath 'whiskey.yml'
$context = New-WhiskeyContext -Environment 'Dev' -ConfigurationPath $whiskeyYmlPath

if( $Configuration )
{
    $context.MSBuildConfiguration = $Configuration
}

$apiKeys = @{
                'powershellgallery.com' = 'POWERSHELL_GALLERY_API_KEY';
                'nuget.org' = 'NUGET_ORG_API_KEY';
                'chocolatey.org' = 'CHOCOLATEY_ORG_API_KEY';
                'github.com' = 'GITHUB_ACCESS_TOKEN'
            }
foreach( $apiKeyID in $apiKeys.Keys )
{
    $envVarName = $apiKeys[$apiKeyID]
    $envVarPath = 'env:{0}' -f $envVarName
    if( -not (Test-Path -Path $envVarPath) )
    {
        continue
    }

    Write-Verbose ('Adding API key "{0}" from environment variable "{1}".' -f $apiKeyID,$envVarName)
    Add-WhiskeyApiKey -Context $context -ID $apiKeyID -Value (Get-Item -Path $envVarPath).Value
}

$envVarsToSkip = $apiKeys.Values
Get-ChildItem -Path 'env:' |
    Where-Object { $_.Name -notin $envVarsToSkip } |
    Format-Table

Invoke-WhiskeyBuild -Context $context @optionalParams
