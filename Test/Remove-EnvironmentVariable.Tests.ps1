
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:envVarName = "CarbonRemoveEnvironmentVar"

    function Assert-NoTestEnvironmentVariableAt( $Scope )
    {
        $actualValue = [Environment]::GetEnvironmentVariable($script:envVarName, $Scope)
        $actualValue | Should -BeNullOrEmpty
    }

    function Set-TestEnvironmentVariable($Scope)
    {
        $EnvVarValue = [Guid]::NewGuid().ToString()
        [Environment]::SetEnvironmentVariable($script:envVarName, $EnvVarValue, $Scope)
        Set-Item -Path ('env:{0}' -f $script:envVarName) -Value $EnvVarValue

        $actualValue = [Environment]::GetEnvironmentVariable($script:envVarName, $Scope)
        $actualValue | Should -Be $EnvVarValue
        Test-Path -Path ('env:{0}' -f $script:envVarName) | Should -BeTrue

        return $EnvVarValue
    }
}

AfterAll {
    Remove-CEnvironmentVariable -Name $script:envVarName -ForProcess -ForUser -ForComputer
}

Describe 'Remove-CEnvironmentVariable' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'removes computer-level variable' {
        Set-TestEnvironmentVariable 'Machine'
        Remove-CEnvironmentVariable -Name $script:envVarName -ForComputer
        Assert-NoTestEnvironmentVariableAt -Scope Machine
    }

    It 'removes user-level variable' {
        Set-TestEnvironmentVariable 'User'
        Remove-CEnvironmentVariable -Name $script:envVarName -ForUser
        Assert-NoTestEnvironmentVariableAt -Scope User
    }

    It 'removes process-level variable' {
        Set-TestEnvironmentVariable 'Process'
        Remove-CEnvironmentVariable -Name $script:envVarName -ForProcess
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
            Remove-CEnvironmentVariable -Name $script:envVarName @scopeParam -Force
            Assert-NoTestEnvironmentVariableAt -Scope $setScope
            Test-Path -Path ('env:{0}' -f $script:envVarName) | Should -BeFalse
        }
    }

    It 'ignores non-existent variable' {
        Remove-CEnvironmentVariable -Name "IDoNotExist" -ForComputer
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'supports WhatIf' {
        $envVarValue = Set-TestEnvironmentVariable -Scope Process

        Remove-CEnvironmentVariable -Name $script:envVarName -ForProcess -WhatIf

        $actualValue = [Environment]::GetEnvironmentVariable($script:envVarName, 'Process')
        $actualValue | Should -Not -BeNullOrEmpty
        $envVarValue | Should -Be $actualValue
    }

    It 'removes from all scopes at once' {
        $value = [Guid]::NewGuid().ToString()
        Set-EnvironmentVariable -Name $script:envVarName -Value $value -ForProcess -ForUser -ForComputer
        Remove-CEnvironmentVariable -Name $script:envVarName -ForProcess -ForUser -ForComputer
        Assert-NoTestEnvironmentVariableAt -Scope Machine
        Assert-NoTestEnvironmentVariableAt -Scope User
        Assert-NoTestEnvironmentVariableAt -Scope Process
    }

    It 'requires at least one scope' {
        Remove-CEnvironmentVariable -Name $script:envVarName -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'target not specified'
    }

    It 'removes variable for another user' {
        $name = [Guid]::NewGuid().ToString()
        $value = [Guid]::NewGuid().ToString()
        Set-EnvironmentVariable -Name $name -Value $value -ForUser -Credential $CarbonTestUser
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