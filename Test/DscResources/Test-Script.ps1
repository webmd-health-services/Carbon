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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force
$tempDir = $null

$getScriptBlock = {
    param(
        [Parameter(Position=1)]
        [string]
        $Ensure
    )

    return @{
        Ensure = $Ensure;
    }
}

$setScriptBlock = {
    param(
        [Parameter(Position=1)]
        $Path
    )

    New-Item -ItemType 'File' -Path $Path
}

$testScriptBlock = {
    param(
        [Parameter(Position=1)]
        [string]
        $Result
    )

    [bool]$bool = $false
    if( [bool]::TryParse($Result, [ref]$bool) )
    {
        return $bool
    }
}

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'Script'
}

function Start-Test
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null
}

function Stop-Test
{
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldInvokeGetScript
{
    $resource = Get-TargetResource -GetScript $getScriptBlock -GetArgumentList 'Present' `
                                   -TestScript $testScriptBlock `
                                   -SetScript $setScriptBlock
    Assert-NotNull $resource
    Assert-Equal 'Present' $resource.Ensure
}

function Test-ShouldHandleError
{
    $resource = Get-TargetResource -GetScript { Write-Error 'Blarg!' } -TestScript { } -SetScript { } -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'Blarg'
    Assert-Null $resource
}

function Test-ShouldRequireHashtableReturnValue
{
    $resource = Get-TargetResource -GetScript { return 'Blarg!' } -TestScript { } -SetScript { } -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'hashtable'
    Assert-Null $resource
}

function Test-ShouldInvokeSetScript
{
    $Path = Join-Path -Path $tempDir -ChildPath ([IO.Path]::GetRandomFileName())
    Set-TargetResource -GetScript $getScriptBlock `
                                   -TestScript $testScriptBlock `
                                   -SetScript $setScriptBlock `
                                   -SetArgumentList $Path
    Assert-NoError
    Assert-FileExists $Path
}

function Test-ShouldInvokeTestScript
{
    Assert-True (Test-TargetResource -GetScript { } -SetScript { } -TestScript $testScriptBlock -TestArgumentList $true)
    Assert-False (Test-TargetResource -GetScript { } -SetScript { } -TestScript $testScriptBlock -TestArgumentList $false)
}

function Test-ShouldRequireBoolReturnType
{
    $result = Test-TargetResource -GetScript { } -SetScript { } -TestScript $testScriptBlock -TestArgumentList 'Blarg!' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'bool'
    Assert-Null $result
}

function Test-ShouldHandleErrorInTestScript
{
    $result = Test-TargetResource -GetScript { } -SetScript { } -TestScript { Write-Error 'Blarg!' } -TestArgumentList $true -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'Blarg'
    Assert-Null $result
}

configuration DscConfiguration
{
    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        Carbon_Script set
        {
            GetScript = {
                Write-Verbose $args[0]
                New-Item -Path (Join-Path $args[0] 'GetScript') -ItemType 'File' | Out-Null
                @{
                    $args[0] = $args[0]
                }
            }
            GetArgumentList = @( $tempDir );

            SetScript = {
                Write-Verbose $args[0]
                New-Item -Path (Join-Path $args[0] 'SetScript') -ItemType 'File' | Out-Null
            }
            SetArgumentList = @( $tempDir );

            TestScript = {
                Write-Verbose $args[0]
                $resource = Get-TargetResource @PSBoundParameters
                New-Item -Path (Join-Path $args[0] 'TestScript') -ItemType 'File' | Out-Null
                return $false
            }
            TestArgumentList = @( $tempDir );
        }
    }
}

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot
    Assert-NoError
    Assert-FileExists (Join-Path $tempDir 'TestScript')
    Assert-FileExists (Join-Path $tempDir 'SetScript')
    Assert-FileExists (Join-Path $tempDir 'GetScript')
}
