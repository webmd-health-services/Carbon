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

$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()
$tempDir = $null
Install-User -Credential (New-Credential -UserName $UserName -Password $Password)

function New-MockDir
{
    $path = (Join-Path -Path (Get-Item -Path 'TestDrive:').FullName -ChildPath ([Guid]::NewGuid().ToString()))
    Install-Directory -Path $path
    return $path
}


Describe 'Carbon_Permission when non-existent permissions should be absent' {

    Start-CarbonDscTestFixture 'Permission'

    $tempDir = New-MockDir

    Context 'the user' {
        It 'should not have access to the directory' {
            Get-Permission -Path $tempDir -Identity $UserName -Inherited | Should BeNullOrEmpty
        }
    }
    Test-TargetResource -Identity $UserName -Path $tempDir -Ensure Absent -ErrorVariable 'errors'

    It 'should not throw any errors' {
        $errors | Should BeNullOrEmpty
    }
}

Describe 'Carbon_Permission when no permissions should be present' {

    Start-CarbonDscTestFixture 'Permission'

    $tempDir = New-MockDir
    Grant-Permission -Path $tempDir -Identity $UserName -Permission FullControl 

    Context 'the user' {
        It 'should have access to the directory' {
            Get-Permission -Path $tempDir -Identity $UserName -Inherited | Should Not BeNullOrEmpty
        }
    }
    Test-TargetResource -Identity $UserName -Path $tempDir -Ensure Present -ErrorVariable 'errors' -ErrorAction SilentlyContinue

    It 'should throw an error' {
        $errors | Should Not BeNullOrEmpty
        $errors | Should Match 'is mandatory'
    }
}

Describe 'Carbon_Permission.when appending permissions' {

    Start-CarbonDscTestFixture 'Permission'

    $tempDir = New-MockDir

    $rule1 = @{
                    Identity = $UserName;
                    Path = $tempDir;
                    Permission = 'ReadAndExecute';
                    ApplyTo = 'ContainerAndSubContainersAndLeaves';
                    Append = $true;
                    Ensure = 'Present';
               }

    $rule2 = @{
                    Identity = $UserName;
                    Path = $tempDir;
                    Permission = 'Write';
                    ApplyTo = 'ContainerAndLeaves';
                    Append = $true;
                    Ensure = 'Present';
               }

    It ('should report correct resource state') {
        $result = Test-TargetResource @rule1
        $result | Should -BeFalse
        $result = Test-TargetResource @rule2
        $result | Should -BeFalse
    }

    Set-TargetResource @rule1

    It ('should report correct resource state') {
        $result = Test-TargetResource @rule1
        $result | Should -BeTrue
        $result = Test-TargetResource @rule2
        $result | Should -BeFalse
    }

    Set-TargetResource @rule2

    It ('should report correct resource state') {
        $result = Test-TargetResource @rule1
        $result | Should -BeTrue
        $result = Test-TargetResource @rule2
        $result | Should -BeTrue
    }


    It 'should add two rules to directory' {
        $perm = Get-Permission -Path $tempDir -Identity $UserName #-Inherited 
        $perm | Should -HaveCount 2
    }
}

Describe 'Carbon_Permission.when granting permissions on registry' {
    Start-CarbonDscTestFixture 'Permission'
    $tempDir = New-MockDir
    $Global:Error.Clear()
    It 'should grant permission on registry' {
        $keyPath = 'hkcu:\{0}' -f (Split-Path -Leaf -Path $tempDir)
        New-Item -Path $keyPath
        try
        {
            (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact) | Should Be $false
            (Test-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -Ensure Present) | Should Be $false
    
            Set-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Ensure Present
            $Global:Error.Count | Should Be 0
            (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact) | Should Be $true
            (Test-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -Ensure Present) | Should Be $true
    
            Set-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Ensure Absent
            $Global:Error.Count | Should Be 0
            (Test-Permission -Identity $UserName -Path $keyPath -Permission ReadKey -ApplyTo Container -Exact) | Should Be $false
            (Test-TargetResource -Identity $UserName -Path $keyPath -Permission ReadKey -Ensure Absent) | Should Be $true
        }
        finally
        {
            Remove-Item -Path $keyPath
        }
    }
}

Describe 'Carbon_Permission' {
    BeforeAll {
        Start-CarbonDscTestFixture 'Permission'
    }
    
    BeforeEach {
        $Global:Error.Clear()
        $tempDir = New-MockDir
    }
    
    AfterEach {
        if( (Test-Path -Path $tempDir -PathType Container) )
        {
            Remove-Item -Path $tempDir -Recurse
        }
    }

    It 'should grant permission on file system' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        $Global:Error.Count | Should Be 0
        (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Exact) | Should Be $true
    }
    
    It 'should grant permission with inheritence on file system' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo Container -Ensure Present
        $Global:Error.Count | Should Be 0
        (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo Container -Exact) | Should Be $true
    }
    
    It 'should grant permission on private key' {
        $cert = Install-Certificate -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve) -StoreLocation LocalMachine -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint -Resolve
            (Get-Permission -Path $certPath -Identity $UserName) | Should BeNullOrEmpty
            (Test-TargetResource -Path $certPath -Identity $UserName -Permission 'GenericRead') | Should Be $false
    
            Set-TargetResource -Identity $UserName -Path $certPath -Permission GenericRead -Ensure Present
            (Get-Permission -Path $certPath -Identity $UserName) | Should Not BeNullOrEmpty
            (Test-TargetResource -Path $certPath -Identity $UserName -Permission 'GenericRead') | Should Be $true
    
            Set-TargetResource -Identity $UserName -Path $certPath -Permission GenericRead -Ensure Absent
            (Get-Permission -Path $certPath -Identity $UserName) | Should BeNullOrEmpty
            (Test-TargetResource -Path $certPath -Identity $UserName -Permission 'GenericRead' -Ensure Absent) | Should Be $true
        }
        finally
        {
            Uninstall-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }
    
    It 'should change permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present
        (Test-Permission -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Exact) | Should Be $true
    }
    
    It 'should revoke permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        Set-TargetResource -Identity $UserName -Path $tempDir -Ensure Absent
        (Test-Permission -Identity $UserName -Path $tempDir -Permission FullControl -Exact) | Should Be $false
    }
    
    It 'should require permission when granting' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Ensure Present -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'mandatory'
        (Get-Permission -Path $tempDir -Identity $UserName) | Should BeNullOrEmpty
    }
    
    It 'should get no permission' {
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        $resource | Should Not BeNullOrEmpty
        $resource.Identity | Should Be $UserName
        $resource.Path | Should Be $tempDir
        $resource.Permission | Should BeNullOrEmpty
        $resource.ApplyTo | Should BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }
    
    It 'should get current permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        $resource | Should Not BeNullOrEmpty
        $resource.Identity | Should Be $UserName
        $resource.Path | Should Be $tempDir
        $resource.Permission | Should Be 'FullControl'
        $resource.ApplyTo | Should Be 'ContainerAndSubContainersAndLeaves'
        Assert-DscResourcePresent $resource
    }
    
    It 'should get multiple permissions' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read,Write -Ensure Present
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        ,$resource.Permission | Should BeOfType 'string[]'
        ($resource.Permission -join ',') | Should Be 'Write,Read'
    }
    
    
    It 'should get current container inheritance flags' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo SubContainers -Ensure Present
        $resource = Get-TargetResource -Identity $UserName -Path $tempDir
        $resource | Should Not BeNullOrEmpty
        $resource.ApplyTo | Should Be 'SubContainers'
    }
    
    It 'should test no permission' {
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -Ensure Absent) | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission FullControl -ApplyTo ContainerAndSubContainersAndLeaves -Ensure Absent) | Should Be $true
    }
    
    It 'should test existing permission' {
        Set-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -Ensure Present) | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Present) | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -Ensure Absent) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Container -Ensure Absent) | Should Be $false
    
        # Now, see what happens if permissions are wrong
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Write -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Leaves -Ensure Present) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Write -Ensure Absent) | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission Read -ApplyTo Leaves -Ensure Absent) | Should Be $false
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
            Carbon_Permission set
            {
                Identity = $UserName;
                Path = $tempDir;
                Permission = 'Read','Write';
                ApplyTo = 'Container';
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Present') | Should Be $true
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Absent') | Should Be $false
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Present') | Should Be $false
        (Test-TargetResource -Identity $UserName -Path $tempDir -Permission 'Read','Write' -ApplyTo 'Container' -Ensure 'Absent') | Should Be $true

        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_Permission' } | Should Not BeNullOrEmpty
    }

    configuration DscConfiguration2
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Permission set
            {
                Identity = $UserName;
                Path = $tempDir;
                Ensure = 'Absent';
            }
        }
    }
    
    It 'should not fail when user doesn''t have permission' {
        Revoke-Permission -Path $tempDir -Identity $UserName
        & DscConfiguration2 -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    }
    
    configuration DscConfiguration3
    {
        param(
            $Ensure
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_Permission SetRead
            {
                Identity = $UserName;
                Path = $tempDir;
                Permission = 'ReadAndExecute'
                ApplyTo = 'ContainerAndSubContainersAndLeaves';
                Append = $true;
                Ensure = 'Present';
            }
            Carbon_Permission SetWrite
            {
                Identity = ('.\{0}' -f $UserName);
                Path = $tempDir;
                Permission = 'Write'
                ApplyTo = 'ContainerAndLeaves';
                Append = $true;
                Ensure = 'Present';
            }
        }
    }
    
    It 'should apply multiple permissions' {
        Revoke-Permission -Path $tempDir -Identity $UserName
        & DscConfiguration3 -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        Get-CPermission -Path $tempDir -Identity $UserName | Should -HaveCount 2
    }
    
}

Stop-CarbonDscTestFixture
