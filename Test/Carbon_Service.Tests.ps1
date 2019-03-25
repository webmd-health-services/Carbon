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

$credential = New-Credential -User 'CarbonDscTestUser' -Password ([Guid]::NewGuid().ToString())
$tempDir = $null
$servicePath = $null
$serviceName = 'CarbonDscTestService'
Install-CUser -Credential $credential

Start-CarbonDscTestFixture 'Service'

function Init
{
    Uninstall-CService -Name $serviceName
    $Global:Error.Clear()
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Service\NoOpService.exe') -Destination $TestDrive.FullName
    $script:servicePath = Join-Path -Path $TestDrive.FullName -ChildPath 'NoOpService.exe'
}

Describe 'Carbon_Service.when getting resource' {
    Init
    It 'should get existing services' {
        Get-Service |
            # Some services can't be retrieved di-rectly.
            Where-Object { (Get-Service -Name $_.Name -ErrorAction Ignore) -and (@('lltdsvc','lltdio') -notcontains $_.Name) } |
            Where-Object { (-Not [string]::IsNullOrWhitespace($_.Name)) } |
            ForEach-Object {
                Write-Verbose -Message ($_.Name) -Verbose
                $resource = Get-TargetResource -Name $_.Name
                $Global:Error.Count | Should Be 0
                $resource | Should Not BeNullOrEmpty
                $resource.Name | Should Be $_.Name
                $path,$argumentList = [Carbon.Shell.Command]::Split($_.Path)
                $resource.Path | Should Be $path
                $resource.ArgumentList | Should Be $argumentList
                $resource.StartupType | Should Be $_.StartMode
                $resource.Delayed | Should Be $_.DelayedAutoStart
                $resource.OnFirstFailure | Should Be $_.FirstFailure
                $resource.OnSecondFailure | Should Be $_.SecondFailure
                $resource.OnThirdFailure | Should Be $_.ThirdFailure
                $resource.ResetFailureCount | Should Be $_.ResetPeriod
                $resource.RestartDelay | Should Be $_.RestartDelay
                $resource.RebootDelay | Should Be $_.RebootDelay
                $resource.Command | Should Be $_.FailureProgram
                $resource.RunCommandDelay | Should Be $_.RunCommandDelay
                $resource.DisplayName | Should Be $_.DisplayName
                $resource.Description | Should Be $_.Description
                ($resource.Dependency -join ',') | Should Be (($_.ServicesDependedOn | Select-Object -ExpandProperty 'Name') -join ',')
                if( $_.UserName -and (Test-Identity -Name $_.UserName) )
                {
                    $resource.UserName | Should Be (Resolve-IdentityName -Name $_.UserName)
                }
                else
                {
                    $resource.UserName | Should Be $_.UserName
                }
                $resource.Credential | Should BeNullOrEmpty
                Assert-DscResourcePresent $resource
            }
    }
}

Describe 'Carbon_Service' {
    BeforeEach {
        Init
    }

    It 'should get non existent service' {
        $name = [Guid]::NewGuid().ToString()
        $resource = Get-TargetResource -Name $name
    
        $Global:Error.Count | Should Be 0
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be $name
        $resource.Path | Should BeNullOrEmpty
        $resource.StartupType | Should BeNullOrEmpty
        $resource.Delayed | Should BeNullOrEmpty
        $resource.OnFirstFailure | Should BeNullOrEmpty
        $resource.OnSecondFailure | Should BeNullOrEmpty
        $resource.OnThirdFailure | Should BeNullOrEmpty
        $resource.ResetFailureCount | Should BeNullOrEmpty
        $resource.RestartDelay | Should BeNullOrEmpty
        $resource.RebootDelay | Should BeNullOrEmpty
        $resource.Dependency | Should BeNullOrEmpty
        $resource.Command | Should BeNullOrEmpty
        $resource.RunCommandDelay | Should BeNullOrEmpty
        $resource.DisplayName | Should BeNullOrEmpty
        $resource.Description | Should BeNullOrEmpty
        $resource.UserName | Should BeNullOrEmpty
        $resource.Credential | Should BeNullOrEmpty
        $resource.ArgumentList | Should Be $null
        Assert-DscResourceAbsent $resource
    }
        
    It 'should install service' {
        Set-TargetResource -Path $servicePath -Name $serviceName -Ensure Present
        $Global:Error.Count | Should Be 0
        $resource = Get-TargetResource -Name $serviceName
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be $serviceName
        $resource.Path | Should Be $servicePath
        $resource.StartupType | Should Be 'Automatic'
        $resource.Delayed | Should Be $false
        $resource.OnFirstFailure | Should Be 'TakeNoAction'
        $resource.OnSecondFailure | Should Be 'TakeNoAction'
        $resource.OnThirdFailure | Should Be 'TakeNoAction'
        $resource.ResetFailureCount | Should Be 0
        $resource.RestartDelay | Should Be 0
        $resource.RebootDelay | Should Be 0
        $resource.Dependency | Should BeNullOrEmpty
        $resource.Command | Should BeNullOrEmpty
        $resource.RunCommandDelay | Should Be 0
        $resource.UserName | Should Be 'NT AUTHORITY\NETWORK SERVICE'
        $resource.Credential | Should BeNullOrEmpty
        $resource.DisplayName | Should Be $serviceName
        $resource.Description | Should BeNullOrEmpty
        $resource.ArgumentList | Should Be $null
        Assert-DscResourcePresent $resource
    }
    
    It 'should install service with all options' {
        Set-TargetResource -Path $servicePath `
                           -Name $serviceName `
                           -Ensure Present `
                           -StartupType Manual `
                           -OnFirstFailure RunCommand `
                           -OnSecondFailure Restart `
                           -OnThirdFailure Reboot `
                           -ResetFailureCount (60*60*24*2) `
                           -RestartDelay (1000*60*5) `
                           -RebootDelay (1000*60*10) `
                           -Command 'fubar.exe' `
                           -RunCommandDelay (60*1000) `
                           -Dependency 'W3SVC' `
                           -DisplayName 'Display Name' `
                           -Description 'Description description description' `
                           -Credential $credential
        $Global:Error.Count | Should Be 0
        $resource = Get-TargetResource -Name $serviceName
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be $serviceName
        $resource.Path | Should Be $servicePath
        $resource.StartupType | Should Be 'Manual'
        $resource.Delayed | Should Be $false
        $resource.OnFirstFailure | Should Be 'RunCommand'
        $resource.OnSecondFailure | Should Be 'Restart'
        $resource.OnThirdFailure | Should Be 'Reboot'
        $resource.ResetFailureCount | Should Be (60*60*24*2)
        $resource.RestartDelay | Should Be (1000*60*5)
        $resource.RebootDelay | Should Be (1000*60*10)
        $resource.Dependency | Should Be 'W3SVC'
        $resource.Command | Should Be 'fubar.exe'
        $resource.RunCommandDelay | Should Be (60*1000)
        $resource.DisplayName | Should Be 'Display Name'
        $resource.Description | Should Be 'Description description description'
        $resource.UserName | Should Be (Resolve-Identity -Name $credential.UserName).FullName
        $resource.Credential | Should BeNullOrEmpty
        $resource.ArgumentList | Should Be $null
        Assert-DscResourcePresent $resource    
    }
    
    It 'should install service as automatic delayed' {
        Set-TargetResource -Path $servicePath -Name $serviceName -StartupType Automatic -Delayed  -Ensure Present
        $Global:Error.Count | Should Be 0
        $resource = Get-TargetResource -Name $serviceName
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be $serviceName
        $resource.Path | Should Be $servicePath
        $resource.StartupType | Should Be 'Automatic'
        $resource.Delayed | Should Be $true
        $resource.OnFirstFailure | Should Be 'TakeNoAction'
        $resource.OnSecondFailure | Should Be 'TakeNoAction'
        $resource.OnThirdFailure | Should Be 'TakeNoAction'
        $resource.ResetFailureCount | Should Be 0
        $resource.RestartDelay | Should Be 0
        $resource.RebootDelay | Should Be 0
        $resource.Dependency | Should BeNullOrEmpty
        $resource.Command | Should BeNullOrEmpty
        $resource.RunCommandDelay | Should Be 0
        $resource.UserName | Should Be 'NT AUTHORITY\NETWORK SERVICE'
        $resource.Credential | Should BeNullOrEmpty
        $resource.DisplayName | Should Be $serviceName
        $resource.Description | Should BeNullOrEmpty
        $resource.ArgumentList | Should Be $null
        Assert-DscResourcePresent $resource
    }

    It 'should install service with argumentlist' {
        Set-TargetResource -Path $servicePath -Name $serviceName -StartupType Automatic -Delayed  -Ensure Present -ArgumentList @('arg1', 'arg2')
        $Global:Error.Count | Should Be 0
        $resource = Get-TargetResource -Name $serviceName -ArgumentList @('arg1', 'arg2')
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be $serviceName
        $resource.Path | Should Be $servicePath
        $resource.StartupType | Should Be 'Automatic'
        $resource.Delayed | Should Be $true
        $resource.OnFirstFailure | Should Be 'TakeNoAction'
        $resource.OnSecondFailure | Should Be 'TakeNoAction'
        $resource.OnThirdFailure | Should Be 'TakeNoAction'
        $resource.ResetFailureCount | Should Be 0
        $resource.RestartDelay | Should Be 0
        $resource.RebootDelay | Should Be 0
        $resource.Dependency | Should BeNullOrEmpty
        $resource.Command | Should BeNullOrEmpty
        $resource.RunCommandDelay | Should Be 0
        $resource.UserName | Should Be 'NT AUTHORITY\NETWORK SERVICE'
        $resource.Credential | Should BeNullOrEmpty
        $resource.DisplayName | Should Be $serviceName
        $resource.Description | Should BeNullOrEmpty
        $resource.ArgumentList | Should Be @('arg1', 'arg2')
        Assert-DscResourcePresent $resource
    }
    
    It 'should uninstall service' {
        Set-TargetResource -Name $serviceName -Path $servicePath -Ensure Present
        $Global:Error.Count | Should Be 0
        Assert-DscResourcePresent (Get-TargetResource -Name $serviceName)
        Set-TargetResource -Name $serviceName -Path $servicePath -Ensure Absent
        $Global:Error.Count | Should Be 0
        Assert-DscResourceAbsent (Get-TargetResource -Name $serviceName)
    }
    
    It 'should require path when installing service' {
        Set-TargetResource -Name $serviceName -Ensure Present -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'Path\b.*\bmandatory'
        Assert-DscResourceAbsent (Get-TargetResource -Name $serviceName)
    }
    
    It 'should test existing services' {
        Get-Service | ForEach-Object {
            (Test-TargetResource -Name $_.Name -Ensure Present) | Should Be $true
            (Test-TargetResource -Name $_.Name -Ensure Absent) | Should Be $false
        }
    }
    
    It 'should test missing services' {
        (Test-TargetResource -Name $serviceName -Ensure Absent) | Should Be $true
        (Test-TargetResource -Name $serviceName -Ensure Present) | Should Be $false
    }
    
    It 'should test on credentials' {
        Set-TargetResource -Name $serviceName -Path $servicePath -Credential $credential -Ensure Present
        (Test-TargetResource -Name $serviceName -Path $servicePath -Credential $credential -Ensure Present) | Should Be $true
    }
    
    It 'should not allow both username and credentials' {
        Set-TargetResource -Name $serviceName -Path $servicePath -Credential $credential -username LocalService -Ensure Present -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        (Test-Service -Name $serviceName) | Should Be $false
    }
    
    It 'should test on properties' {
        Set-TargetResource -Name $serviceName -Path $servicePath -Command 'fubar.exe' -Description 'Fubar' -Ensure Present
        $testParams = @{ Name = $serviceName; }
        (Test-TargetResource @testParams -Path $servicePath -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -Path 'C:\fubar.exe' -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -StartupType Automatic -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -StartupType Manual -Ensure Present) | Should Be $false

        (Test-TargetResource @testParams -Delayed -Ensure Present) | Should Be $false
        (Test-TargetResource @testParams -Delayed:$false -Ensure Present) | Should Be $true
    
        (Test-TargetResource @testParams -OnFirstFailure TakeNoAction -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -OnFirstFailure Restart -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -OnSecondFailure TakeNoAction -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -OnSecondFailure Restart -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -OnThirdFailure TakeNoAction -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -OnThirdFailure Restart -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -ResetFailureCount 0 -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -ResetFailureCount 50 -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -RestartDelay 0 -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -RestartDelay 50 -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -RebootDelay 0 -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -RebootDelay 50 -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -Dependency @() -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -Dependency @( 'W3SVC' ) -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -Command 'fubar.exe' -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -Command 'fubar2.exe' -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -RunCommandDelay 0 -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -RunCommandDelay 1000 -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -UserName 'NetworkService' -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -Credential $credential -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -Description 'Fubar' -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -Description 'Description' -Ensure Present) | Should Be $false
    
        (Test-TargetResource @testParams -DisplayName $serviceName -Ensure Present) | Should Be $true
        (Test-TargetResource @testParams -DisplayName 'fubar' -Ensure Present) | Should Be $false
    }
    
    
    configuration DscConfiguration
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Service set
            {
                Name = $serviceName;
                Path = $servicePath;
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Name $serviceName -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Name $serviceName -Ensure 'Absent') | Should Be $false
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Name $serviceName -Ensure 'Present') | Should Be $false
        (Test-TargetResource -Name $serviceName -Ensure 'Absent') | Should Be $true

        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Service' } | Should Not BeNullOrEmpty
    }
    
}

Uninstall-CService -Name $serviceName
Stop-CarbonDscTestFixture
