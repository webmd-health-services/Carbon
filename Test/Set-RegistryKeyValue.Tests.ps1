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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$rootKey = 'hklm:\Software\Carbon\Test\Test-SetRegistryKeyValue'

<#
    BeforeEach {
        if( -not (Test-Path $rootKey -PathType Container) )
        {
            New-Item $rootKey -ItemType RegistryKey -Force
        }
    }
    
    AfterEach {
        Remove-Item $rootKey -Recurse
    }
#>

function Remove-RootKey
{
    if( (Test-Path -Path $rootKey) )
    {
        Remove-Item -Path $rootKey -Recurse
    }
        
}

Describe 'Set-RegistryKeyValue when the key doesn''t exist' {

    Remove-RootKey
        
    $keyPath = Join-Path $rootKey 'ShouldCreateNewKeyAndValue'
    $name = 'Title'
    $value = 'This is Sparta!'

    It 'should create the registry key' {
        (Test-RegistryKeyValue -Path $keyPath -Name $name) | Should Be $false
        Set-RegistryKeyValue -Path $keyPath -Name $name -String $value
        (Test-RegistryKeyValue -Path $keyPath -Name $name) | Should Be $true
    }
        
    It 'should set the registry key''s value' {        
        $actualValue = Get-RegistryKeyValue -Path $keyPath -Name $name
        $actualValue | Should Be $value
    }
}

Describe 'Set-RegistryKeyValue when the key exists and has a value' {
    $name = 'ShouldChangeAnExistingValue'
    $value = 'foobar''ed'

    It 'should set the initial value' {
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        (Get-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $value
    }

    It 'should change the value' {
        $newValue = 'Ok'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue
        (Get-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $newValue
    }
}
    
Describe 'Set-RegistryKeyValue when setting values of different types' {
    It 'should set binary value' {
        Set-RegistryKeyValue -Path $rootKey -Name 'Binary' -Binary ([byte[]]@( 1, 2, 3, 4))
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'Binary'
        $value | Should Not BeNullOrEmpty
        $value.GetType() | Should Be 'System.Object[]'
        $value[0] | Should Be 1
        $value[1] | Should Be 2
        $value[2] | Should Be 3
        $value[3] | Should Be 4
    }

    It 'should set dword value' {
        $number = [Int32]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name 'DWord' -DWord $number
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'DWord'
        $value | Should Not BeNullOrEmpty
        $value.GetType() | Should Be 'int'
        $value | Should Be $number
    }

    It 'should set qword value' {
        $number = [Int64]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name 'QWord' -QWord $number
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'QWord'
        $value | Should Not BeNullOrEmpty
        $value.GetType() | Should Be 'long'
        $value | Should Be $number
    }
    
    It 'should set multi string value' {
        $strings = @( 'Foo', 'Bar' )
        Set-RegistryKeyValue -Path $rootKey -Name 'Strings' -Strings $strings
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'Strings'
        $value | Should Not BeNullOrEmpty
        $value.Length | Should Be $strings.Length
        $value[0] | Should Be $strings[0]
        $value[1] | Should Be $strings[1]
    }
    
    It 'should set expanding string value' {
        Set-RegistryKeyValue -Path $rootKey -Name 'Expandable' -String '%ComputerName%' -Expand
        $value = Get-RegistryKeyValue -Path $rootKey -Name 'Expandable'
        $value | Should Not BeNullOrEmpty
        $value | Should Be $env:ComputerName
    }

    It 'should set to unsigned int64' {
        $name = 'uint64maxvalue'
        $value = [uint64]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name $name -UQWord $value
        $setValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $setValue | Should Be $value
    }
    
    It 'should set to unsigned int32' {
        $name = 'uint32maxvalue'
        $value = [uint32]::MaxValue
        Set-RegistryKeyValue -Path $rootKey -Name $name -UDWord $value
        $setValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $setValue | Should Be $value
    }

    It 'should set string value' {
        $name = 'string'
        $value = 'fubarsnafu'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        Test-RegistryKeyValue -Path $rootKey -Name $name | Should Be $true
        Get-RegistryKeyValue -Path $rootKey -Name $name | Should Be $value
    }
    
    It 'should set string value to null string' {
        $name = 'string'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $null
        Test-RegistryKeyValue -Path $rootKey -Name $name | Should Be $true
        Get-RegistryKeyValue -Path $rootKey -Name $name | Should Be ''
    }
    
    It 'should set string value to empty string' {
        $name = 'string'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String ''
        Test-RegistryKeyValue -Path $rootKey -Name $name | Should Be $true
        Get-RegistryKeyValue -Path $rootKey -Name $name | Should Be ''
    }
}

Describe 'Set-RegistryKeyValue when user needs to change the value''s type' {
    It 'should remove and recreate value' {
        $name = 'ShouldChangeAnExistingValue'
        $value = 'foobar''ed'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        (Get-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $value
        
        $newValue = 8439
        Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $newValue -Force
        $newActualValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $newActualValue | Should Be $newValue
        $newActualValue.GetType() | Should Be 'int'
    }
 }

 Describe 'Set-RegistryKeyValue when user uses -Force and the value doesn''t exist' {
    Remove-RootKey

    It 'should still create new value' {
        $name = 'NewWithForce'
        $value = 8439
        (Test-REgistryKeyValue -Path $rootKey -Name $name) | Should Be $false
        Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $value -Force
        $actualValue = Get-RegistryKeyValue -Path $rootKey -Name $name
        $actualValue | Should Be $value
        $actualValue.GetType() | Should Be 'int'
    }
    
}

Describe 'Set-RegistryKeyValue when using -WhatIf switch' {    
    It 'should not create a new value' {
        $name = 'newwithwhatif'
        $value = 'value'
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $false
        Set-REgistryKeyValue -Path $rootKey -Name $name -String $value -WhatIf
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $false
    }

    It 'should not update an existing value' {
        $name = 'newwithwhatif'
        $value = 'value'
        $newValue = 'newvalue'
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $true
        
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue -WhatIf
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $true
        (Get-REgistryKeyValue -Path $rootKey -Name $name) | Should Be $value
    
        Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue -WhatIf -Force
        (Test-RegistryKeyValue -Path $rootKey -Name $name) | Should Be $true
        (Get-REgistryKeyValue -Path $rootKey -Name $name) | Should Be $value
    }
}

Describe 'Set-RegistryKeyValue when DWord value is an int32' {

    $name = 'maxvalue'
    foreach( $value in @( [int32]::MaxValue, 0, -1, [int32]::MinValue, [uint32]::MaxValue, [uint32]::MinValue ) )
    {
        It ('should set int32 value {0} as a uint32' -f $value) {
            Write-Debug -Message ('T {0} -is {1}' -f $value,$value.GetType())
            $bytes = [BitConverter]::GetBytes( $value )
            $int32 = [BitConverter]::ToInt32( $bytes, 0 )
            Write-Debug -Message ('T {0} -is {1}' -f $value,$value.GetType())
            Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $int32
            $setValue = Get-RegistryKeyValue -Path $rootKey -Name $name
            Write-Debug -Message ('T {0} -is {1}' -f $setValue,$setValue.GetType())
            Write-Debug -Message '-----'
            $uint32 = [BitConverter]::ToUInt32( $bytes, 0 )
            $setValue | Should Be $uint32
        }
    }
}
