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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)

function Test-ShouldGetMsi
{
    $msi = Get-Msi -Path (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi' -Resolve)
}

function Test-ShouldAcceptPipelineInput
{
    $msi = Get-ChildItem -Path $PSScriptRoot -Filter *.msi | Get-Msi
    Assert-NotNull $msi
    $msi | ForEach-Object {  Assert-CarbonMsi $_ }
}

function Test-ShouldAcceptArrayOfStrings
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi'

    $msi = Get-Msi -Path @( $path, $path )
    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Test-ShouldAcceptArrayOfFileInfo
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi'

    $item = Get-Item -Path $path
    $msi = Get-Msi -Path @( $item, $item )

    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Test-ShouldSupportWildcards
{
    $msi = Get-Msi -Path (Join-Path -Path $PSScriptRoot -ChildPath '*.msi')
    Assert-Is $msi ([object[]])
    foreach( $item in $msi )
    {
        Assert-CarbonMsi $item
    }
}

function Assert-CarbonMsi
{
    param(
        $msi
    )

    Assert-NotNull $msi
    Assert-Is $msi ([Carbon.Msi.MsiInfo])
    Assert-Equal 'Carbon' $msi.Manufacturer
    Assert-Like $msi.ProductName 'Carbon *' 
    Assert-NotNull $msi.ProductCode
    Assert-NotEqual $msi.ProductCode ([Guid]::Empty)
    Assert-Equal 1033 $msi.ProductLanguage
    Assert-Equal '1.0.0' $msi.ProductVersion
    Assert-NotNull $msi.Properties
    Assert-GreaterThan $msi.Properties.Count 5
}
