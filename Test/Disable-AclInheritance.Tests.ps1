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

$parentFSPath = $null 
$childFSPath = $null
$originalAcl = $null

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-AclInheritanceDisabled
{
    param(
        $Path
    )

    It 'should disable access rule inheritance' {
        (Get-Acl -Path $Path).AreAccessRulesProtected | Should Be $true
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
        $path = ('hkcu:\Carbon+{0}\Disable-AclInheritance.Tests' -f [IO.Path]::GetRandomFileName())
        Install-RegistryKey -Path $path
    }
    else
    {
        throw $Provider
    }

    Grant-Permission -Path $path -Identity $env:USERNAME -Permission FullControl

    It 'should have inheritance enabled' {
        $acl = Get-Acl -Path $path
        $acl.AreAccessRulesProtected | Should Be $false
        $acl = $null
    }

    It 'should have inherited access rules' {
        Get-Permission -Path $path -Inherited | Should Not BeNullOrEmpty
    }

    return $path
}

foreach( $provider in @( 'FileSystem', 'Registry' ) )
{
    
    Describe ('Disable-AclInheritance on {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Protect-Acl -Path $path
        Assert-AclInheritanceDisabled -Path $path
        It 'should not preserve inherited access rules' {
            [object[]]$perm = Get-Permission -Path $path -Inherited 
            $perm.Count | Should Be 1
            $perm[0].IdentityReference | Should Be (Resolve-IdentityName -Name $env:USERNAME)
        }
    }
    
    Describe ('Disable-AclInheritance on {0} when preserving inherited rules' -f $provider) {
        $path = New-TestContainer -Provider $provider
        [Security.AccessControl.AccessRule[]]$inheritedPermissions = Get-Permission -Path $path -Inherited | Where-Object { $_.IsInherited }
        Protect-Acl -Path $path -Preserve
        Assert-AclInheritanceDisabled -Path $path
        It 'should preserve inherited access rules' {
            [object[]]$currentPermissions = Get-Permission -Path $path -Inherited 
            $currentPermissions.Count | Should Be $inheritedPermissions.Count
            for( $idx = 0; $idx -lt $currentPermissions.Count; ++$idx )
            {
                $currentPermission = $currentPermissions[$idx]
                $inheritedPermission = $inheritedPermissions | Where-Object { $_.IdentityReference -eq $currentPermission.IdentityReference }

                $currentPermission.IdentityReference | Should Be $inheritedPermission.IdentityReference
            }
        }
    }
    
    Describe ('Disable-AclInheritance on {0} when part of a pipeline' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Get-Item -Path $path | Disable-AclInheritance 
        Assert-AclInheritanceDisabled -Path $path

        $path = New-TestContainer -Provider $provider
        $path | Disable-AclInheritance
        Assert-AclInheritanceDisabled -Path $path
    }

    Describe ('Disable-AclInheritandce on {0} when inheritance already disabled' -f $provider) {
        $path = New-TestContainer -Provider $provider
        Disable-AclInheritance -Path $path
        Assert-AclInheritanceDisabled -Path $path

        Mock -CommandName 'Set-Acl' -ModuleName 'Carbon' -Verifiable
        Disable-AclInheritance -Path $path
        It 'should not disable an already disabled ACL' {
            Assert-MockCalled -CommandName 'Set-Acl' -ModuleName 'Carbon' -Times 0
        }
    }
}

Get-ChildItem -Path 'hkcu:\Carbon+*' | Remove-Item -Recurse -ErrorAction Ignore
