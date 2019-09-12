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

$siteName = 'CarbonSetIisHttpHeader'
$sitePort = 47938

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-IisWebsite -Name $siteName -Path $TestDir -Binding ('http/*:{0}:*' -f $sitePort)
}

function Stop-Test
{
    Remove-IisWebsite -Name $siteName
}

function Test-ShouldCreateNewHeader()
{
    $name = 'X-Carbon-SetIisHttpHeader'
    $value = 'Brownies'
    $header = Get-IisHttpHeader -SiteName $siteName -Name $name
    Assert-Null $header
    $result = Set-IisHttpHeader -SiteName $siteName -Name $name -Value $value
    Assert-Null $result 'something returned from Set-IisHttpHeader'
    $header = Get-IisHttpHeader -SiteName $siteName -Name $name
    Assert-NotNull $header 'header not created'
    Assert-Equal $name $header.Name
    Assert-Equal $value $header.Value
}

function Test-ShouldSetExistingHeader()
{
    $name = 'X-Carbon-SetIisHttpHeader'
    $value = 'Brownies'
    Set-IisHttpHeader -SiteName $siteName -Name $name -Value $value
    
    $newValue = 'Blondies'
    $result = Set-IisHttpHeader -SiteName $siteName -Name $name -Value $newValue
    Assert-Null $result 'something returned from Set-IisHttpHeader'
    
    $header = Get-IisHttpHeader -SiteName $siteName -Name $name
    Assert-NotNull $header 'header not created'
    Assert-Equal $name $header.Name
    Assert-Equal $newValue $header.Value
}

function Test-ShouldSetHeaderOnPath
{
    $name = 'X-Carbon-SetIisHttpHeader'

    $value = 'Parent'
    Set-IisHttpHeader -SiteName $siteName -Name $name -Value $value
    
    $subValue = 'Child'
    Set-IisHttpHeader -SiteName $siteName -Path SubFolder -Name $name -Value $subValue
    
    $header = Get-IisHttpHeader -SiteName $siteName -Name $name
    Assert-NotNull $header 'header not created'
    Assert-Equal $name $header.Name
    Assert-Equal $value $header.Value
    
    $header = Get-IisHttpHeader -SiteName $siteName -Path SubFolder -Name $name
    Assert-NotNull $header 'header not created'
    Assert-Equal $name $header.Name
    Assert-Equal $subValue $header.Value
}

function Test-ShouldSupportWhatIf()
{
    $name = 'X-Carbon-SetIisHttpHeader'
    $value = 'Brownies'
    $header = Get-IisHttpHeader -SiteName $siteName -Name $name
    Assert-Null $header
    Set-IisHttpHeader -SiteName $siteName -Name $name -Value $value -WhatIf
    $header = Get-IisHttpHeader -SiteName $siteName -Name $name
    Assert-Null $header 'HTTP header created'
}

