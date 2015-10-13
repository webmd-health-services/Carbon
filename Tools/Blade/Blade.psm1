# Copyright 2012 - 2015 Aaron Jensen
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

Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\*.ps1') | 
    ForEach-Object { . $_.FullName }

$privateFunctions = @{ 
                        'Remove-ItemWithRetry' = $true; 
                        'Invoke-Test' = $true;
                        'Get-FunctionsInFile' = $true;
                    }

$publicFunctions = Get-ChildItem -Path 'function:\' |
                        Where-Object { $_.ModuleName -eq 'Blade' } |
                        Where-Object { -not $privateFunctions.ContainsKey( $_.Name ) } |
                        Select-Object -ExpandProperty 'Name'

Export-ModuleMember -Function $publicFunctions -Alias *
