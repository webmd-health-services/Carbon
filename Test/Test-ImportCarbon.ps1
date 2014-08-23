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

$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

function Start-Test
{
    if( (Get-Module 'Carbon') )
    {
        Remove-Module 'Carbon'
    }
}

function Test-ShouldImport
{
    & $importCarbonPath
    Assert-NotNull (Get-Command -Module 'Carbon')
}

function Test-ShouldImportWithPrefix
{
    & $importCarbonPath -Prefix 'C'
    $carbonCmds = Get-Command -Module 'Carbon'
    Assert-NotNull $carbonCmds
    foreach( $cmd in $carbonCmds )
    {
        Assert-Match $cmd.Name '^.+-C.+$'
    }
}
