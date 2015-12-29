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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldGetCanonicalCaseForDirectory
{
    $currentDir = (Resolve-Path '.').Path
    foreach( $badPath in ($currentDir.ToUpper(),$currentDir.ToLower()) )
    {
        $canonicalCase = Resolve-PathCase -Path $badPath
        Assert-True ($currentDir -ceq $canonicalCase) ('{0} != {1}' -f $currentDir,$canonicalCase)
    }
}

function Test-ShouldGetCanonicalCaseForFile
{
    $currentFile = Join-Path $TestDir 'Test-ResolvePathCase.ps1' -Resolve
    $canonicalCase = Resolve-PathCase -Path ($currentFile.ToUpper())
    Assert-True ($currentFile -ceq $canonicalCase) ('{0} != {1}' -f $currentFile,$canonicalCase)
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
            Assert-True ( $_.StartsWith( 'C:\Windows' ) ) ('{0} doesn''t start with C:\Windows' -f $_)
        }
    Assert-True $gotSomething
    
}

function Test-ShouldGetRelativePath
{
    Push-Location -Path $PSScriptRoot
    try
    {
        $path = '..\..\Carbon\Import-Carbon.ps1'
        $canonicalCase = Resolve-PathCase ($path.ToUpper())
        Assert-Equal (Resolve-Path -Path $path).Path $canonicalCase -CaseSensitive

    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldGetPathToShare
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath 
    $shareName = Split-Path -Leaf -Path $tempDir
    try
    {
        Install-FileShare -Name $shareName -Path $tempDir.FullName -ReadAccess 'Everyone'
        try
        {
            $path = '\\{0}\{1}' -f $env:COMPUTERNAME,$shareName
            $canonicalCase = Resolve-PathCase ($path.ToUpper()) -ErrorAction SilentlyContinue
            Assert-Error -Last -Regex 'UNC .* not supported'
            Assert-Null $canonicalCase
        }
        finally
        {
            Uninstall-FileShare -Name $shareName
        }
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

