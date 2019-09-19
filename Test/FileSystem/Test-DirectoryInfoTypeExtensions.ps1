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

$junctionName = $null
$junctionPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $junctionName = [IO.Path]::GetRandomFilename()    
    $junctionPath = Join-Path $env:Temp $junctionName
    New-Junction -Link $junctionPath -Target $TestDir
}

function Stop-Test
{
    Remove-Junction -Path $junctionPath
}

function Test-ShouldAddIsJunctionProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-True $dirInfo.IsJunction
    
    $dirInfo = Get-Item $TestDir
    Assert-False $dirInfo.IsJunction
}

function Test-ShouldAddTargetPathProperty
{
    $dirInfo = Get-Item $junctionPath
    Assert-Equal $TestDir $dirInfo.TargetPath
    
    $dirInfo = Get-Item $Testdir
    Assert-Null $dirInfo.TargetPath
    
}

