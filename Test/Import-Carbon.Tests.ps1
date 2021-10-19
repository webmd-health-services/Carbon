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

$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

function Init
{
    if( (Get-Module 'Carbon') )
    {
        Remove-Module 'Carbon' -Force
    }
    $Global:Error.Clear()
}

function Reset
{
    if( (Get-Module 'Carbon') )
    {
        Remove-Module 'Carbon' -Force
    }
}

Describe 'Import-Carbon' {

    BeforeEach { Init }
    AfterEach { Reset }
    
    It 'should import' {
        & $importCarbonPath
        (Get-Command -Module 'Carbon') | Should -Not -BeNullOrEmpty
    }
    
    It 'should import with prefix' {
        & $importCarbonPath -Prefix 'C'
        $carbonCmds = Get-Command -Module 'Carbon'
        $carbonCmds | Should -Not -BeNullOrEmpty
        foreach( $cmd in $carbonCmds )
        {
            $cmd.Name | Should -Match '^.+-C.+$'
        }
    }
    
    It 'should handle drives in env path that do not exist' {
        $drive = $null
        for( $idx = [byte][char]'Z'; $idx -ge [byte][char]'A'; --$idx )
        {
            $driveLetter = [char][byte]$idx
            $drive = '{0}:\' -f $driveLetter
            if( -not (Test-Path -Path $drive) )
            {
                break
            }
        }
    
        $badPath = '{0}fubar' -f $drive
        $originalPath = $env:Path
        $env:Path = '{0};{1}' -f $env:Path,$badPath
        try
        {
            & $importCarbonPath
            $Global:Error.Count | Should -Be 0
        }
        finally
        {
            $env:Path = $originalPath
        }
    }

    # This test turned out to be too unreliable in its timings. Too bad.
    It 'should import fast' -Skip {
        # September 2019: average unmerged modules takes about 8.1 seconds to import.
        $maxAvgDuration = 9.0
        if( (Test-Path -Path 'env:APPVEYOR') )
        {
            # September 2019: average merged module takes about .75 seconds to import.
            $maxAvgDuration = 0.8
            # January 2020: Looks like things are slower now. No changes that would affect import speed, yet it's 
            # now taking up to 1.4 seconds to import.
            $maxAvgDuration = 1.5
        }
        $carbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve
        & {
                for( $idx = 0; $idx -lt 7; ++$idx )
                {
                    $job = Start-Job -ScriptBlock {
                        $started = Get-Date
                        Import-Module -Name $using:carbonPath
                        return (Get-Date) - $started
                    }
                    $job | Wait-Job | Receive-Job 
                    $job | Remove-Job -Force
                }
            } |
            Select-Object -ExpandProperty 'TotalSeconds' |
            Sort-Object |
            # Don't use best/worst times
            Select-Object -Skip 1 |
            Select-Object -SkipLast 1 |
            Measure-Object -Average -Maximum -Minimum |
            ForEach-Object { 
                Write-Verbose -Message ('Import-Module Statistics') -Verbose
                Write-Verbose -Message ('========================') -Verbose
                $_ | Format-List | Out-String | Write-Verbose -Verbose
                $_
            } |
            Select-Object -ExpandProperty 'Average' |
            Should -BeLessOrEqual $maxAvgDuration
    }
}

Describe 'Import-CarbonPs1.when importing multiple times from different locations' {
    AfterEach { Reset }
    It 'should import without errors' {
        Init
        $otherCarbonModulesRoot = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $otherCarbonModulesRoot -ItemType 'Directory'
        Copy-Item -Path ($importCarbonPath | Split-Path -Parent) -Destination $otherCarbonModulesRoot -Recurse

        $otherCarbonRoot = Join-Path -Path $otherCarbonModulesRoot -ChildPath 'Carbon'
        $otherCarbonRoot | Should -Exist
        Import-Module -Name $otherCarbonRoot
        & $importCarbonPath
        (Get-Command -Module 'Carbon') | Should -Not -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Import-CarbonPs1.when importing multiple times from same location' {
    AfterEach { Reset }
    It 'should not remove or import' {
        Init
        & $importCarbonPath
        Mock -CommandName 'Import-Module'
        Mock -CommandName 'Remove-Module'
        & $importCarbonPath
        Assert-MockCalled -CommandName 'Remove-Module' -Times 0
        Assert-MockCalled -CommandName 'Import-Module' -Times 1
    }
}

if( (Test-Path -Path 'env:SystemRoot') )
{
    Describe 'Import-CarbonPs1.when IIS isn''t installed' {
        AfterEach { 
            Reset 
            Remove-Item -Path 'env:CARBON_SKIP_IIS_IMPORT'
        }
        It 'should import successfully' {
            Init
            $env:CARBON_SKIP_IIS_IMPORT = 'True'
            & $importCarbonPath
            $Global:Error | Should -BeNullOrEmpty
            (Get-Command -Module 'Carbon') | Should -Not -BeNullOrEmpty
            (Get-Command -Module 'Carbon' -Name '*-Iis*') | Should -BeNullOrEmpty
            (Get-Command -Module 'Carbon' -Name '*-CIis*') | Should -BeNullOrEmpty
        }
    }
}