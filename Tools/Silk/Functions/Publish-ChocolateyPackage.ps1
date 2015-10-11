<#
.SYNOPSIS
Publishes a Chocolatey package to chocolatey.org.
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
    [string]
    # The path to the nupkg file to publish.
    $FilePath,

    [Parameter(Mandatory=$true)]
    [string]
    # The API key to use.
    $ApiKey
)

Set-StrictMode -Version 'Latest'

if( -not (Get-Command -Name 'choco.exe') )
{
    return
}

if( -not (Test-Path -Path $FilePath -PathType Leaf) )
{
    Write-Error ('Chocolatey package ''{0}'' not found.' -f $FilePath)
    return
}

choco.exe push $FilePath --source=https://chocolatey.org --apikey $ApiKey

