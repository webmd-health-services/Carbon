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

param(
    [Parameter(Mandatory=$true)]
    [string]
    # The path to the file/test importing this script. Should be set to $PSCommandPath.
    $Path
)

$fixture = Get-Item -Path $Path
$carbonRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve

if( -not (Get-Module -Name 'Carbon') -or (Get-ChildItem -Path $carbonRoot -Recurse -File | Where-Object { $_.LastWriteTime -gt $fixture.LastWriteTime } ) )
{
    Write-Host ('Importing Carbon.')
    & (Join-Path -Path $carbonRoot -ChildPath 'Import-Carbon.ps1' -Resolve)
}
