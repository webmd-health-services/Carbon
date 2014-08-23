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

# To convert C:\Users\schedu~1 to C:\Users\scheduleuser
$tempDir = [IO.Path]::GetFullPath( $env:TEMP )
$junctionPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $junctionPath = Join-Path $tempDir ('Carbon_Test-InstallJunction_{0}' -f ([IO.Path]::GetRandomFileName()))
}

function Stop-Test
{
    if( Test-Path -Path $junctionPath -PathType Container )
    {
        Remove-Junction -Path $junctionPath
    }
}

function Test-ShouldCreateJunction
{
    Assert-DirectoryDoesNotExist $junctionPath

    Install-Junction -Link $junctionPath -Target $PSScriptRoot

    Assert-Junction
}

function Test-ShouldUpdateExistingJunction
{
    Assert-DirectoryDoesNotExist $junctionPath

    Install-Junction -Link $junctionPath -Target $env:windir
    Assert-Junction -ExpectedTarget $env:windir

    Install-Junction -LInk $junctionPath -Target $PSScriptRoot
    Assert-Junction
}

function Test-ShouldGiveAnErrorIfLinkExistsAndIsADirectory
{
    New-Item -Path $junctionPath -ItemType Directory
    $Error.Clear()
    try
    {
        Install-Junction -Link $junctionPath -Target $PSScriptRoot -ErrorAction SilentlyContinue
        Assert-Error -Last 'exists'
    }
    finally
    {
        Remove-Item $junctionPath -Recurse
    }
}

function Test-ShouldSupportWhatIf
{
    Install-Junction -Link $junctionPath -Target $PSScriptRoot -WhatIf
    Assert-DirectoryDoesNotExist $junctionPath

    Install-Junction -Link $junctionPath -Target $env:windir
    Install-Junction -Link $junctionPath -Target $PSScriptRoot -WhatIf
    Assert-Junction -ExpectedTarget $env:windir
}

function Test-ShouldFailIfTargetDoesNotExist
{
    $target = 'C:\Hello\World\Foo\Bar'
    Assert-DirectoryDoesNotExist $target
    $Error.Clear()
    Install-Junction -Link $junctionPath -Target $target -ErrorAction SilentlyContinue
    Assert-Equal 1 $Error.Count
    Assert-Like $Error[0].Exception.Message '*not found*'
    Assert-DirectoryDoesNotExist $target
    Assert-DirectoryDoesNotExist $junctionPath
}

function Test-ShouldFailIfTargetIsAFile
{
    $target = Get-ChildItem -Path $PSScriptRoot | Select-Object -First 1
    Assert-NotNull $target
    $Error.Clear()
    Install-Junction -Link $junctionPath -Target $target.FullName -ErrorAction SilentlyContinue
    Assert-Equal 1 $Error.Count
    Assert-Like $Error[0].Exception.Message '*file*'
    Assert-DirectoryDoesNotExist $junctionPath
}

function Test-ShouldCreateTargetIfItDoesNotExist
{
    $target = 'Carbon_Test-InstallJunction_{0}' -f [IO.Path]::GetRandomFileName()
    $target = Join-Path -Path $tempDir -ChildPath $target
    Assert-DirectoryDoesNotExist $target
    Install-Junction -Link $junctionPath -Target $target -Force
    Assert-Equal 0 $Error.Count
    Assert-Junction -ExpectedTarget $target
}

function Test-ShouldCreateJunctionWithRelativePaths
{
    Push-Location $tempDir
    try
    {
        $target = ('..\{0}' -f (Split-Path -Leaf $tempDir))
        $link = '.\{0}' -f (Split-Path -Leaf -Path $junctionPath)

        Install-Junction -Link $link -Target $target

        Assert-Junction -ExpectedTarget $tempDir
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldHandleHiddenFile
{
    Install-Junction -Link $junctionPath -Target $PSScriptRoot
    $junction = Get-Item -Path $junctionPath
    $junction.Attributes = $junction.Attributes -bor [IO.FileAttributes]::Hidden
    Install-Junction -Link $junctionPath -Target $PSScriptRoot
    Assert-NoError
}

function Assert-Junction
{
    param(
        $ExpectedTarget = $PSScriptRoot
    )

    Assert-Equal 0 $Error.Count
    Assert-DirectoryExists $junctionPath

    $junction = Get-Item $junctionPath
    Assert-True $junction.IsJunction
    Assert-Equal $ExpectedTarget $junction.TargetPath
}
