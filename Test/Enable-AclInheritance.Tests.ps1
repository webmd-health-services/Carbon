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

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-InheritanceEnabled
{
    param(
        $Path
    )

    It 'should enable inheritance' {
        $acl = Get-Acl -Path $path
        $acl.AreAccessRulesProtected | Should Be $false
        $acl = $null
    }

}

function New-TestContainer
{
    param(
        [Parameter(Mandatory=$true)]
        $Provider
    )

    if( $Provider -eq 'FileSystem' )
    {
        $testRoot = (Get-Item -Path 'TestDrive:').FullName
        $path = Join-Path -Path $testRoot -ChildPath ([IO.Path]::GetRandomFileName())
        Install-Directory -Path $path
    }
    elseif( $Provider -eq 'Registry' )
    {
        $path = ('hkcu:\Carbon+{0}\Enable-AclInheritance.Tests' -f [IO.Path]::GetRandomFileName())
        Install-RegistryKey -Path $path
    }
    else
    {
        throw $Provider
    }

    Disable-AclInheritance -Path $path -Preserve

    It 'should have inheritance disabled' {
        $acl = Get-Acl -Path $path
        $acl.AreAccessRulesProtected | Should Be $true
        $acl = $null
    }

    It 'should have explicit access rules' {
        Get-Permission -Path $path | Should Not BeNullOrEmpty
    }

    return $path
}

foreach( $provider in @( "FileSystem", 'Registry' ) )
{
    Describe ('Enable-AclInheritance when ACL inheritance is disabled on the {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Enable-AclInheritance -Path $path
        
        Assert-InheritanceEnabled -Path $path

        It 'should remove explicit access rules' {
            Get-Permission -Path $path | Should BeNullOrEmpty
        }
    }

    Describe ('Enable-AclInheritance when ACL inheritance is already disabled on the {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider

        Enable-AclInheritance -Path $path

        Assert-InheritanceEnabled -Path $path

        Mock -CommandName 'Set-Acl' -ModuleName 'Carbon' -Verifiable

        Enable-AclInheritance -Path $path

        Assert-InheritanceEnabled -Path $path

        It 'should not enable inheritance twice' {
            Assert-MockCalled -CommandName 'Set-Acl' -ModuleName 'Carbon' -Times 0
        }
    }

    Describe ('Enable-AclInheritance whould preserve existing explicit access rules on the {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider

        Enable-AclInheritance -Path $path -Preserve

        Assert-InheritanceEnabled -Path $path

        It 'should preservice explicit access rules' {
            Get-Permission -Path $path | Should Not BeNullOrEmpty
        }
    }

    Describe ('Enable-AclInheritance when part of a pipeline on the {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Get-Item -Path $path | Enable-AclInheritance
        Assert-InheritanceEnabled -Path $path

        $path = New-TestContainer -Provider $provider
        $path | Enable-AclInheritance
        Assert-InheritanceEnabled -Path $path
    }

}

Get-ChildItem -Path 'hkcu:\Carbon+*' | Remove-Item -Recurse -ErrorAction Ignore
