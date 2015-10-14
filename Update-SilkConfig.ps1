<#
.SYNOPSIS
Updates the navigation settings for the Carbon website.

.DESCRIPTION
Updates the silk settings for the Carbon websites so that the commands are organized by topics instead of grouped together alphabetically.

.EXAMPLE
Update-SilkConfig

Demonstrates how to use the script.
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

$silkJsonPath = Join-Path -Path $PSScriptRoot -ChildPath 'silk.json' -Resolve
$silkJson = Get-Content -Path $silkJsonPath -Raw | ConvertFrom-Json

if( -not (Get-Member -InputObject $silkJson -Name 'Navigation') )
{
    Add-Member -InputObject $silkJson -MemberType NoteProperty -Name 'Navigation' -Value @{ }
}

$silkJson.Navigation = [ordered]@{ }

$moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon'
$categories = Get-ChildItem -Path $moduleRoot -Directory -Exclude 'bin' | 
                Sort-Object -Property 'BaseName'

$dirNameTitleNameMap = @{
                            'ActiveDirectory' = 'Active Directory';
                            'DotNet' = '.NET';
                            'FileSystem' = 'File System';
                            'HostsFile' = 'Hosts File';
                            'InternetExplorer' = 'Internet Explorer';
                            'PerformanceCounters' = 'Performance Counters';
                            'UsersAndGroups' = 'Users and Groups';
                            'WindowsFeatures' = 'Windows Features';
                        }

foreach( $category in $categories )
{
    $categoryName = $category.Name
    if( $dirNameTitleNameMap.ContainsKey($categoryName) )
    {
        $categoryName = $dirNameTitleNameMap.$categoryName
    }
    [object[]]$categoryTopics = Get-ChildItem -Path $category.FullName -Filter '*.ps1' |
                                    Sort-Object -Property BaseName |
                                    Select-Object -ExpandProperty BaseName
    $silkJson.Navigation.$categoryName = $categoryTopics
}

$silkJson | ConvertTo-Json | Set-Content -Path $silkJsonPath
    
