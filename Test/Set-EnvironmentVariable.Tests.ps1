
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $EnvVarName = 'CarbonTestSetEnvironmentVariable'

    function Assert-TestEnvironmentVariableIs($ExpectedValue, $Scope, $ExpectedName = $EnvVarName, [switch]$Force)
    {
        if( $Scope -eq 'Computer' )
        {
            $Scope = 'Machine'
        }
        $actualValue = [Environment]::GetEnvironmentVariable($ExpectedName, $Scope)

        $qualifer = ''
        if( -not $ExpectedValue )
        {
            $qualifer = 'not '
        }

        $actualValue | Should -Be $ExpectedValue

        if( $Scope -eq 'Process' )
        {
            if( -not $Force )
            {
                $envPath = 'env:{0}' -f $EnvVarName
                Test-Path -Path $envPath | Should -BeFalse
            }
        }
    }

    function Assert-TestEnvironmentVariableSetInEnvDrive
    {
        param(
            $ExpectedName = $EnvVarName,
            $ExpectedValue
        )

        $envPath = 'env:{0}' -f $ExpectedName
        Test-Path -Path $envPath | Should -BeTrue
        (Get-Item -Path $envPath).Value | Should -Be $ExpectedValue
    }

    function Set-TestEnvironmentVariable($Scope, $Value)
    {
        $setArgs = @{ "For$Scope" = $true }

        Remove-CEnvironmentVariable -Name $EnvVarName -ForProcess -ForUser -ForComputer

        Set-CEnvironmentVariable -Name $EnvVarName -Value $value @setArgs
        Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
        return $value
    }

    function New-TestValue
    {
        [Guid]::NewGuid().ToString()
    }
}

AfterAll {
    Remove-CEnvironmentVariable -Name $EnvVarName -ForProcess -ForUser -ForComputer
}

Describe 'Set-CEnvironmentVariable' {
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
            Set-CEnvironmentVariable -Name $EnvVarName -Value $value -Force @scopeParam
            Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $scope -Force
            Assert-TestEnvironmentVariableSetInEnvDrive -ExpectedValue $value
        }
    }

    It 'supports WhatIf' {
        Remove-CEnvironmentVariable -Name $EnvVarName -ForProcess -ForUser -ForComputer
        Set-CEnvironmentVariable -Name $EnvVarName -Value 'Doesn''t matter.' -ForProcess -WhatIf
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
