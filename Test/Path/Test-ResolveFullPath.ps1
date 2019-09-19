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


function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-GetFullPath
{
    $fullpath = Resolve-FullPath (Join-Path $TestDir '..\Tests' )
    $expectedFullPath = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\Tests') )
    Assert-Equal $expectedFullPath $fullPath "Didn't get full path for '..\Tests'."
}

function Test-ResolvesRelativePath
{
    Push-Location (Join-Path $env:WinDir system32)
    try
    {
        $fullPath = Resolve-FullPath -Path '..\..\Program Files'
        Assert-Equal $env:ProgramFiles $fullPath
    }
    finally
    {
        Pop-Location
    }
}

