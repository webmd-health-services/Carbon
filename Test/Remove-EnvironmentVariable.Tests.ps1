
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:varName = ''
    $script:testNum = 0

    function Assert-NoTestEnvironmentVariableAt( $Scope )
    {
        $actualValue = [Environment]::GetEnvironmentVariable($script:varName, $Scope)
        $actualValue | Should -BeNullOrEmpty
    }

    function Set-TestEnvironmentVariable($Scope)
    {
        $EnvVarValue = [Guid]::NewGuid().ToString()
        [Environment]::SetEnvironmentVariable($script:varName, $EnvVarValue, $Scope)
        Set-Item -Path ('env:{0}' -f $script:varName) -Value $EnvVarValue

        $actualValue = [Environment]::GetEnvironmentVariable($script:varName, $Scope)
        $actualValue | Should -Be $EnvVarValue
        Test-Path -Path ('env:{0}' -f $script:varName) | Should -BeTrue

        return $EnvVarValue
    }
}

AfterAll {
    & {
            [Environment]::GetEnvironmentVariables('Process').Keys
            [Environment]::GetEnvironmentVariables('User').Keys
            [Environment]::GetEnvironmentVariables('Machine').Keys
        } |
        Where-Object { $_ -like 'CARBON_REMOVEENVVAR_TEST_*' } |
        Select-Object -Unique |
        ForEach-Object {
            Remove-CEnvironmentVariable -Name $_ -ForProcess -ForUser -ForComputer
        }
}

Describe 'Remove-CEnvironmentVariable' {
    BeforeEach {
        while ($true)
        {
            $script:testNum += 1
            $script:varName = "CARBON_REMOVEENVVAR_TEST_${script:testNum}"
            if (-not [Environment]::GetEnvironmentVariable($script:varName, 'Process') -and
                -not [Environment]::GetEnvironmentVariable($script:varName, 'User') -and
                -not [Environment]::GetEnvironmentVariable($script:varName, 'Machine') -and
                -not (Test-Path -Path "env:${script:varName}"))
            {
                break
            }
        }

        $Global:Error.Clear()
    }

    It 'removes computer-level variable' {
        Set-TestEnvironmentVariable 'Machine'
        Remove-CEnvironmentVariable -Name $script:varName -ForComputer
        Assert-NoTestEnvironmentVariableAt -Scope Machine
    }

    It 'removes user-level variable' {
        Set-TestEnvironmentVariable 'User'
        Remove-CEnvironmentVariable -Name $script:varName -ForUser
        Assert-NoTestEnvironmentVariableAt -Scope User
    }

    It 'removes process-level variable' {
        Set-TestEnvironmentVariable 'Process'
        Remove-CEnvironmentVariable -Name $script:varName -ForProcess
        Assert-NoTestEnvironmentVariableAt -Scope Process
    }

    Context '<_> scope' -ForEach 'Computer','User','Process' {
        $scope = $_
        It 'removes variable with the Force' -ForEach $scope {
            $scope = $_
            $setScope = $scope
            if( $scope -eq 'Computer' )
            {
                $setScope = 'Machine'
            }
            Set-TestEnvironmentVariable $setScope
            $scopeParam = @{
                                ('For{0}' -f $scope) = $true
                        }
            Remove-CEnvironmentVariable -Name $script:varName @scopeParam -Force
            Assert-NoTestEnvironmentVariableAt -Scope $setScope
            Test-Path -Path ('env:{0}' -f $script:varName) | Should -BeFalse
        }
    }

    It 'ignores non-existent variable' {
        Remove-CEnvironmentVariable -Name "IDoNotExist" -ForComputer
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'supports WhatIf' {
        $envVarValue = Set-TestEnvironmentVariable -Scope Process

        Remove-CEnvironmentVariable -Name $script:varName -ForProcess -WhatIf

        $actualValue = [Environment]::GetEnvironmentVariable($script:varName, 'Process')
        $actualValue | Should -Not -BeNullOrEmpty
        $envVarValue | Should -Be $actualValue
    }

    It 'removes from all scopes at once' {
        $value = [Guid]::NewGuid().ToString()
        Set-CEnvironmentVariable -Name $script:varName -Value $value -ForProcess -ForUser -ForComputer
        Remove-CEnvironmentVariable -Name $script:varName -ForProcess -ForUser -ForComputer
        Assert-NoTestEnvironmentVariableAt -Scope Machine
        Assert-NoTestEnvironmentVariableAt -Scope User
        Assert-NoTestEnvironmentVariableAt -Scope Process
    }

    It 'requires at least one scope' {
        Remove-CEnvironmentVariable -Name $script:varName -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'target not specified'
    }

    It 'removes variable for another user' {
        $name = [Guid]::NewGuid().ToString()
        $value = [Guid]::NewGuid().ToString()
        Set-CEnvironmentVariable -Name $name -Value $value -ForUser -Credential $CarbonTestUser
        Remove-CEnvironmentVariable -Name $name -ForUser -Credential $CarbonTestUser
        $actualValue = $value
        $job = Start-Job -ScriptBlock {
            Get-Item -Path ('env:{0}' -f $using:name) -ErrorAction Ignore
        } -Credential $CarbonTestUser
        $actualValue = $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force -ErrorAction Ignore
        $actualValue | Should -BeNullOrEmpty
    }
}