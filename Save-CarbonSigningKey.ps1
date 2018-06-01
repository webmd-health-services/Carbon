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

$signAssemblyRegex = ([regex]::Escape('<SignAssembly>false</SignAssembly>'))
Get-ChildItem -Path $PSScriptRoot -Filter '*.csproj' -Recurse |
    Where-Object { Select-String -Pattern $signAssemblyRegex -InputObject $_ } |
    ForEach-Object {
        Write-Verbose -Message ('Enabling assembly signing in "{0}".' -f $_.FullName)
        $xml = Get-Content -Path $_.FullName | ForEach-Object { $_ -replace $signAssemblyRegex,'<SignAssembly>true</SignAssembly>' }
        $xml | Set-Content -Path $_.FullName
    }

$internalsVisibleToRegex = [regex]::Escape('[assembly: InternalsVisibleTo("Carbon.Test")]')
$internalsVisibleToSigned = '[assembly: InternalsVisibleTo("Carbon.Test,PublicKey=0024000004800000940000000602000000240000525341310004000001000100a3d2a6d2d3764691c47ee02daeb68fed39fe5a5bdb07b72568d4febe8a37cc3468bb3fc0a2dae7ccd305d436c1ab8a00d063268332d6bb179303003ee8d8c01d96a3acf3a0ee61a146ae96f55ecc0f0b18f732c920ba0143ece0b403e9b92b41f58bd69ec12277507835fb4788a8f37652c5184b2757d81b0ad3b50457ae5b90")]'

$assemblyInfoPath = Join-Path -Path $PSScriptRoot -ChildPath 'Source\Properties\AssemblyInfo.cs'
$assemblyInfo = Get-Content -Path $assemblyInfoPath |
                    ForEach-Object { $_ -replace $internalsVisibleToRegex,$internalsVisibleToSigned }
$assemblyInfo | Set-Content -Path $assemblyInfoPath
Write-Verbose -Message ($assemblyInfoPath)
$assemblyInfo | ForEach-Object { Write-Verbose ('    {0}' -f $_) }

$snkPath = Join-Path -Path $PSScriptRoot -ChildPath 'Source\Carbon.snk'
Write-Verbose -Message ('Saving signing key to "{0}".' -f $snkPath)
[IO.File]::WriteAllBytes($snkPath, [Convert]::FromBase64String($base64Snk))
