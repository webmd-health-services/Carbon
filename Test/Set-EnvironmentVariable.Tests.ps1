
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:varName = ''
    $script:testNum = 0

    function Assert-TestEnvironmentVariableIs
    {
        param(
            [Object] $ExpectedValue,

            $Scope,

            $ExpectedName = $script:varName,

            [switch]$Force
        )

        if ($Scope -eq 'Computer')
        {
            $Scope = 'Machine'
        }

        $actualValue = [Environment]::GetEnvironmentVariable($ExpectedName, $Scope)

        if ($null -eq $ExpectedValue)
        {
            $actualValue | Should -BeNullOrEmpty
        }
        else
        {
            $actualValue | Should -Be $ExpectedValue
        }

        if ($Scope -eq 'Process')
        {
            if (-not $Force)
            {
                $envPath = 'env:{0}' -f $ExpectedName
                if ($null -eq $ExpectedValue)
                {
                    Test-Path -Path $envPath | Should -BeFalse
                }
                else
                {
                    Test-Path -Path $envPath | Should -BeTrue
                }
            }
        }
    }

    function Assert-TestEnvironmentVariableSetInEnvDrive
    {
        param(
            $ExpectedName = $script:varName,
            $ExpectedValue
        )

        $envPath = 'env:{0}' -f $ExpectedName
        Test-Path -Path $envPath | Should -BeTrue
        (Get-Item -Path $envPath).Value | Should -Be $ExpectedValue
    }

    function Set-TestEnvironmentVariable
    {
        param(
            $Scope,
            $Value
        )

        $setArgs = @{ "For$Scope" = $true }

        Set-CEnvironmentVariable -Name $script:varName -Value $value @setArgs
        Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
        return $value
    }

    function New-TestValue
    {
        [Guid]::NewGuid().ToString()
    }
}

AfterAll {
    & {
            [Environment]::GetEnvironmentVariables('Process').Keys
            [Environment]::GetEnvironmentVariables('User').Keys
            [Environment]::GetEnvironmentVariables('Machine').Keys
        } |
        Where-Object { $_ -like 'CARBON_SETENVVAR_TEST_*' } |
        Select-Object -Unique |
        ForEach-Object {
            Remove-CEnvironmentVariable -Name $_ -ForProcess -ForUser -ForComputer
        }
}

Describe 'Set-CEnvironmentVariable' {
    BeforeEach {
        while ($true)
        {
            $script:testNum += 1
            $script:varName = "CARBON_SETENVVAR_TEST_${script:testNum}"
            if (-not [Environment]::GetEnvironmentVariable($script:varName, 'Process') -and
                -not [Environment]::GetEnvironmentVariable($script:varName, 'User') -and
                -not [Environment]::GetEnvironmentVariable($script:varName, 'Machine') -and
                -not (Test-Path -Path "env:${script:varName}"))
            {
                break
            }
        }
    }

    It 'sets machine-level variable' {
        $value = New-TestValue
        Set-TestEnvironmentVariable -Scope Computer -Value $value
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope User
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope Process
    }

    It 'sets user-level variable for current user' {
        $value = New-TestValue
        Set-TestEnvironmentVariable -Scope User -Value $value
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope Process
    }

    It 'sets process-level variable' {
        $name = 'Carbon+Set-CEnvironmentVariable+ForProcess'
        $value = New-TestValue
        Remove-CEnvironmentVariable -Name $name -ForProcess -ForUser -ForComputer

        Set-CEnvironmentVariable -Name $name -Value $value -ForProcess
        try
        {
            Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer' -ExpectedName $name
            Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User' -ExpectedName $name
            Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope 'Process' -ExpectedName $name
            Assert-TestEnvironmentVariableSetInEnvDrive -ExpectedValue $value  -ExpectedName $name
        }
        finally
        {
            Remove-CEnvironmentVariable -Name $name -ForProcess -ForUser -ForComputer
        }
    }

    Context '<_> scope' -ForEach 'Computer','User','Process' {
        $scope = $_
        It 'overwrites existing variable' -ForEach $scope {
            $scope = $_
            $value = New-TestValue
            $scopeParam = @{
                                ('For{0}' -f $scope) = $true
                        }
            Set-CEnvironmentVariable -Name $script:varName -Value $value -Force @scopeParam
            Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $scope -Force
            Assert-TestEnvironmentVariableSetInEnvDrive -ExpectedValue $value
        }
    }

    It 'supports WhatIf' {
        Remove-CEnvironmentVariable -Name $script:varName -ForProcess -ForUser -ForComputer
        Set-CEnvironmentVariable -Name $script:varName -Value 'Doesn''t matter.' -ForProcess -WhatIf
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User'
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Process'
    }

    It 'sets variable for another user' {
        $name = [Guid]::NewGuid().ToString()
        $expectedValue = New-TestValue
        Set-CEnvironmentVariable -Name $name -Value $expectedValue -ForUser -Credential $CarbonTestUser
        $job = Start-Job -ScriptBlock {
            Get-Item -Path ('env:{0}' -f $using:name) | Select-Object -ExpandProperty 'Value'
        } -Credential $CarbonTestUser
        $actualValue = $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force -ErrorAction Ignore

        $actualValue | Should -Be $expectedValue
    }
}
