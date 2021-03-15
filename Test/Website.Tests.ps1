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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe "Carbon Website" {

    $tags = Get-Content -Raw -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\tags.json' -Resolve) | ConvertFrom-Json
    $taggedCommands = @{ }
    $tags | ForEach-Object { $taggedCommands[$_.Name] = $_.Name }

    It 'should have tags for all functions' {

        $missingCommandNames = Get-Command -Module 'Carbon' | 
                                    Where-Object { $_.CommandType -ne [Management.Automation.CommandTypes]::Alias } |
                                    Where-Object { $_.Noun -like 'C' } |
                                    Select-Object -ExpandProperty 'Name' | 
                                    Where-Object { -not $taggedCommands.ContainsKey($_) }

        if( $missingCommandNames )
        {
        @"
The following commands are missing from tags.json:

 * $($missingCommandNames -join ('{0} * ' -f [Environment]::NewLine))

"@ | Should BeNullOrEmpty
        }
    }

    It 'should have tags for all DSC resources' {
        $missingDscResources = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\DscResources' -Resolve) -Directory |
                            Select-Object -ExpandProperty 'Name' |
                            Where-Object { -not $taggedCommands.ContainsKey($_) }

        ,$missingDscResources | Should BeNullOrEmpty
    }
}
