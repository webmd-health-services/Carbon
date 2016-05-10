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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

Describe 'Carbon_EnvironmentVariable' {
    function Assert-EnvironmentVariable
    {
        param(
            $Name,
            $Value
        )
    
        Set-StrictMode -Version 'Latest'
    
        $stdOutPath = Join-Path -Path $env:Temp -ChildPath ([IO.Path]::GetRandomFileName())
        $stderrPath = Join-Path -Path $env:Temp -ChildPath ([IO.Path]::GetRandomFileName())
        ($stdoutpath,$stderrPath) | ForEach-Object { New-Item -ItemType 'File' -Path $_ } | Out-Null
        try
        {
            Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c',('echo %{0}%' -f $Name)) -UseNewEnvironment -Wait -RedirectStandardError $stderrPath -RedirectStandardOutput $stdOutPath -NoNewWindow
            $stderr = Get-Content -Path $stderrPath -Raw #-Encoding BigEndianUnicode
            $stdErr | Should BeNullOrEmpty
            $stdout = Get-Content -Path $stdOutPath -Raw
            $stdout = $stdout.Trim()
            if( $value -eq $null )
            {
                $stdout | Should Be ('%{0}%' -f $Name)
            }
            else
            {
                $stdout | Should Be $value
            }
        }
        finally
        {
            ($stdoutpath,$stderrPath) | Where-Object { Test-Path -Path $_ -PathType leaf } | Remove-Item
        }
    
    }
    
    BeforeAll {
        Start-CarbonDscTestFixture 'EnvironmentVariable'
        [Environment]::SetEnvironmentVariable('fubar',$null,'Machine')
        [Environment]::SetEnvironmentVariable('fubar',$null,'Process')
    }
    
    AfterAll {
        Stop-CarbonDscTestFixture
        [Environment]::SetEnvironmentVariable('fubar',$null,'Machine')
        [Environment]::SetEnvironmentVariable('fubar',$null,'Process')
    }

    BeforeEach {
        $Global:Error.Clear()
    }
    
    It 'test target resource' {
        (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Present') | Should Be $false
        (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Absent') | Should Be $true
        (Test-TargetResource -Name 'Path' -Value ([Environment]::GetEnvironmentVariable('Path','Machine')) -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Name 'Path' -Value ([Environment]::GetEnvironmentVariable('Path','Machine')) -Ensure 'Absent') | Should Be $false
    }
    
    It 'get target resource' {
        $resource = Get-TargetResource -Name 'fubar'
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be 'fubar'
        Assert-DscResourceAbsent $resource
        $resource.Value | Should BeNullOrEmpty
    
        $resource = Get-TargetResource -Name 'TEMP'
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be 'TEMP'
        Assert-DscResourcePresent $resource
        $resource.Value | Should Be ([Environment]::GetEnvironmentVariable('TEMP','Machine'))
    }
    
    It 'set target resource' {
        $value = [Guid]::NewGuid().ToString()
        Set-TargetResource -Name 'fubar' -Value $value -Ensure 'Present'
    
        $value | Should Be ([Environment]::GetEnvironmentVariable('fubar','Machine'))
        $value | Should Be ([Environment]::GetEnvironmentVariable('fubar','Process'))
    
        Set-TargetResource -Name 'fubar' -Ensure 'Absent'
    }
    
    configuration ShouldSetEnvironmentVariable
    {
        param(
            $Value,
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_EnvironmentVariable setEnvVariable
            {
                Name = 'CarbonDscEnvironmentVariable';
                Value = $Value;
                Ensure = $Ensure;
            }
        }
    }
    It 'should run through dsc' {
        $value = [Guid]::NewGuid().ToString()
    
        & ShouldSetEnvironmentVariable -Value $value -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        Assert-EnvironmentVariable 'CarbonDscEnvironmentVariable' $value
    
        & ShouldSetEnvironmentVariable -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        Assert-EnvironmentVariable 'CarbonDscEnvironmentVariable' $null


        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_EnvironmentVariable' } | Should Not BeNullOrEmpty
    }
}
