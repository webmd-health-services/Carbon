<#
.SYNOPSIS
Saves the Carbon signing key.

.DESCRIPTION
Carbon's signing key is required to build Carbon assemblies. On the build server, the key is stored in a secure environment variable. This script grabs the environment variable and saves it as the signing key.
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

#Requires -Version 4
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$base64Snk = $env:SNK
if( -not $base64Snk )
{
    return
}

$snkPath = Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.snk'
Write-Verbose -Message ('Saving signing key to "{0}".' -f $snkPath)
[IO.File]::WriteAllBytes($snkPath, [Convert]::FromBase64String($base64Snk))
