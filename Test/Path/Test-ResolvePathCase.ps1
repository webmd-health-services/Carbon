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

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetCanonicalCaseForDirectory
{
    $currentDir = (Resolve-Path '.').Path
    $canonicalCase = Resolve-PathCase ($currentDir.ToUpper())
    Assert-True ($currentDir -ceq $canonicalCase)
}

function Test-ShouldGetCanonicalCaseForFile
{
    $currentFile = Join-Path $TestDir 'Test-ResolvePathCase.ps1' -Resolve
    $canonicalCase = Resolve-PathCase -Path ($currentFile.ToUpper())
    Assert-True ($currentFile -ceq $canonicalCase)
}

function Test-ShouldNotGetCaseForFileThatDoesNotExist
{
    $error.Clear()
    $result = Resolve-PathCase 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
    Assert-False $result
    Assert-Equal 1 $error.Count
}

function Test-ShouldAcceptPipelineInput
{
    $gotSomething = $false
    Get-ChildItem 'C:\WINDOWS' | 
        ForEach-Object { 
            Assert-True ($_.FullName.StartsWith( 'C:\WINDOWS' ) )
            $_
        } |
        Resolve-PathCase | 
        ForEach-Object { 
            $gotSomething = $true
            Assert-True ( $_.StartsWith( 'C:\Windows' ) )
        }
    Assert-True $gotSomething
    
}