
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

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
            $stdErr | Should -BeNullOrEmpty
            $stdout = Get-Content -Path $stdOutPath -Raw
            $stdout = $stdout.Trim()
            if( $value -eq $null )
            {
                $stdout | Should -Be ('%{0}%' -f $Name)
            }
            else
            {
                $stdout | Should -Be $value
            }
        }
        finally
        {
            ($stdoutpath,$stderrPath) | Where-Object { Test-Path -Path $_ -PathType leaf } | Remove-Item
        }
    }

    Start-CarbonDscTestFixture 'EnvironmentVariable'
    [Environment]::SetEnvironmentVariable('fubar',$null,'Machine')
    [Environment]::SetEnvironmentVariable('fubar',$null,'Process')
}

AfterAll {
    Stop-CarbonDscTestFixture
    [Environment]::SetEnvironmentVariable('fubar',$null,'Machine')
    [Environment]::SetEnvironmentVariable('fubar',$null,'Process')
}

Describe 'Carbon_EnvironmentVariable' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'test target resource' {
        (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Present') | Should -BeFalse
        (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Absent') | Should -BeTrue
        (Test-TargetResource -Name 'Path' -Value ([Environment]::GetEnvironmentVariable('Path','Machine')) -Ensure 'Present') | Should -BeTrue
        (Test-TargetResource -Name 'Path' -Value ([Environment]::GetEnvironmentVariable('Path','Machine')) -Ensure 'Absent') | Should -BeFalse
    }

    It 'get target resource' {
        $resource = Get-TargetResource -Name 'fubar'
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be 'fubar'
        Assert-DscResourceAbsent $resource
        $resource.Value | Should -BeNullOrEmpty

        $resource = Get-TargetResource -Name 'TEMP'
        $resource | Should -Not -BeNullOrEmpty
        $resource.Name | Should -Be 'TEMP'
        Assert-DscResourcePresent $resource
        $resource.Value | Should -Be ([Environment]::GetEnvironmentVariable('TEMP','Machine'))
    }

    It 'set target resource' {
        $value = [Guid]::NewGuid().ToString()
        Set-TargetResource -Name 'fubar' -Value $value -Ensure 'Present'

        $value | Should -Be ([Environment]::GetEnvironmentVariable('fubar','Machine'))
        $value | Should -Be ([Environment]::GetEnvironmentVariable('fubar','Process'))

        Set-TargetResource -Name 'fubar' -Ensure 'Absent'
    }

    $skipDscTest =
        (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' -and $PSVersionTable['PSVersion'].Major -eq 7

    It 'should run through dsc' -Skip:$skipDscTest {
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

        $value = [Guid]::NewGuid().ToString()

        & ShouldSetEnvironmentVariable -Value $value -Ensure 'Present' -OutputPath $CarbonDscOutputRoot

        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        Assert-EnvironmentVariable 'CarbonDscEnvironmentVariable' $value

        & ShouldSetEnvironmentVariable -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should -Be 0
        Assert-EnvironmentVariable 'CarbonDscEnvironmentVariable' $null


        $result = Get-DscConfiguration
        $Global:Error.Count | Should -Be 0
        $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_EnvironmentVariable' } | Should -Not -BeNullOrEmpty
    }
}
