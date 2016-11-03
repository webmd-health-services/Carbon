
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)


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

        It 'should enable inheritance' {
            $acl = Get-Acl -Path $path
            $acl.AreAccessRulesProtected | Should Be $false
            $acl = $null
        }

        It 'should remove explicit access rules' {
            Get-Permission -Path $path | Should BeNullOrEmpty
        }
    }

    Describe ('Enable-AclInheritance when ACL inheritance is already disabled on the {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider

        Enable-AclInheritance -Path $path

        Mock -CommandName 'Set-Acl' -ModuleName 'Carbon' -Verifiable

        Enable-AclInheritance -Path $path

        It 'should not enable inheritance twice' {
            Assert-MockCalled -CommandName 'Set-Acl' -ModuleName 'Carbon' -Times 0
        }
    }

    Describe ('Enable-AclInheritance whould preserve existing explicit access rules on the {0}' -f $provider) {
        $path = New-TestContainer -Provider $provider

        Enable-AclInheritance -Path $path -Preserve

        It 'should preservice explicit access rules' {
            Get-Permission -Path $path | Should Not BeNullOrEmpty
        }
    }
}