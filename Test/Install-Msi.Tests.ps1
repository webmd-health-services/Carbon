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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$carbonTestInstaller = Join-Path -Path $PSScriptRoot -ChildPath 'MSI\CarbonTestInstaller.msi' -Resolve
$carbonTestInstallerActions = Join-Path -Path $PSScriptRoot -ChildPath 'MSI\CarbonTestInstallerWithCustomActions.msi' -Resolve

Describe 'Install-Msi' {
    
    function Assert-CarbonTestInstallerInstalled
    {
        $Global:Error.Count | Should Be 0
        $maxTries = 100
        $tryNum = 0
        do
        {
            $item = Get-ProgramInstallInfo -Name '*Carbon*'
            if( $item )
            {
                break
            }
    
            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )
        $item | Should Not BeNullOrEmpty
    }
    
    function Assert-CarbonTestInstallerNotInstalled
    {
        $maxTries = 100
        $tryNum = 0
        do
        {
            $item = Get-ProgramInstallInfo -Name '*Carbon*'
            if( -not $item )
            {
                break
            }

            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )

        $item | Should BeNullOrEmpty
    }
    
    function Uninstall-CarbonTestInstaller
    {
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'MSI') -Filter *.msi |
            Get-Msi |
            Where-Object { Get-ProgramInstallInfo -Name $_.ProductName } |
            ForEach-Object {
                msiexec /f $_.Path /quiet
                msiexec /uninstall $_.Path /quiet
            }
        Assert-CarbonTestInstallerNotInstalled
    }

    BeforeEach {
        $Global:Error.Clear()
        Uninstall-CarbonTestInstaller
    }
    
    AfterEach {
        Uninstall-CarbonTestInstaller
    }
    
    It 'should validate file is an MSI' {
        Invoke-WindowsInstaller -Path $PSCommandPath -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
    }
    
    It 'should support what if' {
        Assert-CarbonTestInstallerNotInstalled
        Invoke-WindowsInstaller -Path $carbonTestInstaller -WhatIf
        $Global:Error.Count | Should Be 0
        Assert-CarbonTestInstallerNotInstalled
    }
    
    It 'should install msi' {
        Assert-CarbonTestInstallerNotInstalled
        Install-Msi -Path $carbonTestInstaller
        Assert-CarbonTestInstallerInstalled
    }
    
    It 'should warn quiet switch is obsolete' {
        $warnings = @()
        Install-Msi -Path $carbonTestInstaller -Quiet -WarningVariable 'warnings'
        $warnings.Count | Should Be 1
        Assert-Like $warnings[0] '*obsolete*'
    }
    
    It 'should handle failed installer' {
        Set-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -Value $true -ForComputer
        try
        {
            Install-Msi -Path $carbonTestInstallerActions -ErrorAction SilentlyContinue
            Assert-CarbonTestInstallerNotInstalled
        }
        finally
        {
            Remove-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -ForComputer
        }
    }
    
    It 'should support wildcards' {
        $tempDir = New-TempDirectory -Prefix $PSCommandPath
        try
        {
            Copy-Item $carbonTestInstaller -Destination (Join-Path -Path $tempDir -ChildPath 'One.msi')
            Copy-Item $carbonTestInstaller -Destination (Join-Path -Path $tempDir -ChildPath 'Two.msi')
            Install-Msi -Path (Join-Path -Path $tempDir -ChildPath '*.msi')
            Assert-CarbonTestInstallerInstalled
        }
        finally
        {
            Remove-Item -Path $tempDir -Recurse
        }
    }
    
    It 'should not reinstall if already installed' {
        Install-Msi -Path $carbonTestInstallerActions
        Assert-CarbonTestInstallerInstalled
        $msi = Get-Msi -Path $carbonTestInstallerActions
        $installDir = Join-Path ${env:ProgramFiles(x86)} -ChildPath ('{0}\{1}' -f $msi.Manufacturer,$msi.ProductName)
        Assert-DirectoryExists $installDir
        Remove-Item -Path $installDir -Recurse
        Install-Msi -Path $carbonTestInstallerActions
        Assert-DirectoryDoesNotExist $installDir
    }
    
    It 'should reinstall if forced to' {
        Install-Msi -Path $carbonTestInstallerActions
        Assert-CarbonTestInstallerInstalled
        $msi = Get-Msi -Path $carbonTestInstallerActions
    
        $installDir = Join-Path ${env:ProgramFiles(x86)} -ChildPath ('{0}\{1}' -f $msi.Manufacturer,$msi.ProductName)
        $maxTries = 100
        $tryNum = 0
        do
        {
            if( (Test-Path -Path $installDir -PathType Container) )
            {
                break
            }
            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )
    
        Assert-DirectoryExists $installDir
    
        $tryNum = 0
        do
        {
            Remove-Item -Path $installDir -Recurse -ErrorAction Ignore
            if( -not (Test-Path -Path $installDir -PathType Container) )
            {
                break
            }
            Start-Sleep -Milliseconds 100
        }
        while( $tryNum++ -lt $maxTries )
    
        Assert-DirectoryDoesNotExist $installDir
    
        Install-Msi -Path $carbonTestInstallerActions -Force
        Assert-DirectoryExists $installDir
    }
    
    It 'should install msi with spaces in path' {
        $tempDir = New-TempDirectory -Prefix $PSCommandPath
        try
        {
            $newInstaller = Join-Path -Path $tempDir -ChildPath 'Installer With Spaces.msi'
            Copy-Item -Path $carbonTestInstaller -Destination $newInstaller
            Install-Msi -Path $newInstaller
            Assert-CarbonTestInstallerInstalled
        }
        finally
        {
            Remove-Item -Path $tempDir -Recurse
        }
    
    }
}
