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

$mof1Path = $null
$mof2Path = $null
$notAMofPath = $null
$mof3Path = $null
$tempDir = $null
$mof = $null
$clearedMof = @'
/*
@TargetNode='********'
*/

/* ...snip... */

        
instance of OMI_ConfigurationDocument
{
    Version="1.0.0";
};
'@

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    $mof1Path = Join-Path -Path $tempDir -ChildPath 'computer1.mof'
    $mof2Path = Join-Path -Path $tempDir -ChildPath 'computer2.mof'
    $mof3Path = Join-Path -Path $tempDir -ChildPath 'computer3.txt'
    $notAMofPath = Join-Path -Path $tempDir -ChildPath 'computer2.txt'

    $mof = @'
/*
@TargetNode='********'
@GeneratedBy=********
@GenerationDate=08/19/2014 13:29:15
@GenerationHost=********
*/

/* ...snip... */

        
instance of OMI_ConfigurationDocument
{
    Version="1.0.0";
    Author="********;
    GenerationDate="08/19/2014 13:29:15";
    GenerationHost="********";
};
'@ 

    $mof | Set-Content -Path $mof1Path
    $mof | Set-Content -Path $mof2Path
    $mof | Set-Content -Path $mof3Path
    $mof | Set-Content -Path $notAMofPath
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
}

function Test-ShouldClearAuthoringMetadataFromFile
{
    Clear-MofAuthoringMetadata -Path $mof1Path
    Assert-Equal $clearedMof (Get-Content -Raw $mof1Path).Trim()
    Assert-Equal $mof (Get-Content -Raw $mof2Path).Trim()
    Assert-Equal $mof (Get-Content -Raw $mof3Path).Trim()
    Assert-Equal $mof (Get-Content -Raw $notAMofPath).Trim()
}

function Test-ShouldClearAuthoringMetadataFromFileWithoutMofExtension
{
    Clear-MofAuthoringMetadata -Path $mof3Path
    Assert-Equal $clearedMof (Get-Content -Raw $mof3Path).Trim()
    Assert-Equal $mof (Get-Content -Raw $mof2Path).Trim()
    Assert-Equal $mof (Get-Content -Raw $mof1Path).Trim()
    Assert-Equal $mof (Get-Content -Raw $notAMofPath).Trim()
}

function Test-ShouldClearAuthoringMetadataFromDirectory
{
    Clear-MofAuthoringMetadata -Path $tempDir.FullName
    Assert-Equal $clearedMof (Get-Content -Raw $mof1Path).Trim() $mof1Path
    Assert-Equal $clearedMof (Get-Content -Raw $mof2Path).Trim() $mof2Path
    Assert-Equal $mof (Get-Content -Raw $mof3Path).Trim() $mof3Path
    Assert-Equal $mof (Get-Content -Raw $notAMofPath).Trim() $notAMofPath
}

function Test-ShouldCheckIfPathExists
{
    Clear-MofAuthoringMetadata -Path ('C:\{0}' -f ([IO.Path]::GetRandomFileName())) -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'does not exist'
    Assert-Equal 1 $Error.Count
}

function Test-ShouldSupportWhatIf
{
    Clear-MofAuthoringMetadata -Path $mof1Path -WhatIf
    Assert-Equal $mof (Get-Content -Raw $mof1Path).Trim() $mof1Path
}
