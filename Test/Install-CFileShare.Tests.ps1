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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

if (-not (Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore))
{
    $msgs = 'Install-CFileShare tests will not be run because because the Get-WmiObject command does not exist.'
    Write-Warning $msgs
    return
}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:baseShareName = $PSCommandPath | Split-Path -Leaf
    $script:ShareName = $null
    $script:SharePath = $PSScriptRoot
    $script:fullAccessGroup = 'Carbon Share Full'
    $script:changeAccessGroup = 'CarbonShareChange'
    $script:readAccessGroup = 'CarbonShareRead'
    $script:noAccessGroup = 'CarbonShareNone'
    $script:Remarks = [Guid]::NewGuid().ToString()
    $script:testNum = 0

    Install-CGroup -Name $script:fullAccessGroup -Description 'Carbon group for testing full share permissions.'
    Install-CGroup -Name $script:changeAccessGroup -Description 'Carbon group for testing change share permissions.'
    Install-CGroup -Name $script:readAccessGroup -Description 'Carbon group for testing read share permissions.'

    function Assert-ShareCreated
    {
        $share = Get-Share
        $share | Should -Not -BeNullOrEmpty
    }

    function Assert-Share
    {
        param(
            $Name = $script:ShareName,
            $Path = $script:SharePath,
            $Description = '',
            $FullAccess,
            $ChangeAccess,
            $ReadAccess
        )

        (Test-CFileShare -Name $Name) | Should -BeTrue

        $share = Get-CFileShare -Name $Name
        $share | Should -Not -BeNullOrEmpty

        $share.Description | Should -Be $Description
        $share.Path | Should -Be $Path

        function Assert-ShareRight
        {
            param(
                $IdentityName,
                $ExpectedRigths
            )

            if( $IdentityName )
            {
                foreach( $idName in $IdentityName )
                {
                    $perm = Get-CFileSharePermission -Name $Name -Identity $idName
                    $perm | Should -Not -BeNullOrEmpty
                    $ExpectedRigths | Should -Be $perm.ShareRights
                }
            }
            else
            {
                (Get-CFileSharePermission -Name $Name | Where-Object { $_.ShareRights -eq $ExpectedRigths }) |
                    Should -BeNullOrEmpty
            }
        }

        Assert-ShareRight $FullAccess ([Carbon.Security.ShareRights]::FullControl)
        Assert-ShareRight $ChangeAccess ([Carbon.Security.ShareRights]::Change)
        Assert-ShareRight $ReadAccess ([Carbon.Security.ShareRights]::Read)
    }

    function Remove-Share
    {
        $share = Get-Share -ErrorAction Ignore
        if ($null -ne $share)
        {
            $share.Delete()
        }
    }

    function Invoke-NewShare
    {
        param(
            [String] $Path = $PSScriptRoot,
            $FullAccess = @(),
            $ChangeAccess = @(),
            $ReadAccess = @(),
            $Remarks = ''
        )
        Install-CFileShare -Name $script:ShareName `
                           -Path $Path `
                           -Description $Remarks `
                           -FullAccess $FullAccess `
                           -ChangeAccess $ChangeAccess `
                           -ReadAccess $ReadAccess
        Assert-ShareCreated
    }

    function Get-Share
    {
        [CmdletBinding()]
        param(
        )

        Get-CFileShare -Name $script:ShareName -AsWmiObject -ErrorAction $ErrorActionPreference
    }

}

AfterAll {
    Get-CFileShare -Name "$($script:baseShareName)*" -AsWmiObject | ForEach-Object { $_.Delete() }
}

Describe 'Install-CFileShare' {
    BeforeEach {
        $script:shareName = "$($script:baseShareName)$($script:testNum)"
        $Global:Error.Clear()
    }

    AfterEach {
        $script:testNum += 1
        Remove-Share
    }

    It 'should create share' {
        Invoke-NewShare
        Assert-Share -ReadAccess 'EVERYONE'
    }

    It 'should grant permissions' {
        $script:fullAccessGroup | Should -BeLike '* *'
        Invoke-NewShare -FullAccess $script:fullAccessGroup -ChangeAccess $script:changeAccessGroup -ReadAccess $script:readAccessGroup
        $details = (net share $script:ShareName) -join ([Environment]::NewLine)
        $details | Should -BeLike ("*{0}, FULL*" -f $script:fullAccessGroup)
        $details | Should -BeLike ("*{0}, CHANGE*" -f $script:changeAccessGroup)
        $details | Should -BeLike ("*{0}, READ*" -f $script:readAccessGroup)
        $details | Should -BeLike "*Remark            *"
    }

    It 'should grant permissions twice' {
        $script:fullAccessGroup | Should -BeLike '* *'
        Invoke-NewShare -FullAccess $script:fullAccessGroup -ChangeAccess $script:changeAccessGroup -ReadAccess $script:readAccessGroup
        Invoke-NewShare -FullAccess $script:fullAccessGroup -ChangeAccess $script:changeAccessGroup -ReadAccess $script:readAccessGroup
        $details = (net share $script:ShareName) -join ([Environment]::NewLine)
        $details | Should -BeLike ("*{0}, FULL*" -f $script:fullAccessGroup)
        $details | Should -BeLike ("*{0}, CHANGE*" -f $script:changeAccessGroup)
        $details | Should -BeLike ("*{0}, READ*" -f $script:readAccessGroup)
        $details | Should -BeLike "*Remark            *"
    }

    It 'should grant multiple full access permissions' {
        Install-SmbShare -Name $shareName -Path $PSScriptRoot -Description $script:Remarks -FullAccess $script:fullAccessGroup,$script:changeAccessGroup,$script:readAccessGroup
        $details = (net share $script:ShareName) -join ([Environment]::NewLine)
        $details | Should -BeLike ("*{0}, FULL*" -f $script:fullAccessGroup)
        $details | Should -BeLike ("*{0}, FULL*" -f $script:changeAccessGroup)
        $details | Should -BeLike ("*{0}, FULL*" -f $script:readAccessGroup)
        $details | Should -BeLike "*Remark            *"
    }

    It 'should grant multiple change access permissions' {
        Install-SmbShare -Name $shareName -Path $PSScriptRoot -Description $script:Remarks -ChangeAccess $script:fullAccessGroup,$script:changeAccessGroup,$script:readAccessGroup
        $details = (net share $script:ShareName) -join ([Environment]::NewLine)
        $details | Should -BeLike ("*{0}, CHANGE*" -f $script:fullAccessGroup)
        $details | Should -BeLike ("*{0}, CHANGE*" -f $script:changeAccessGroup)
        $details | Should -BeLike ("*{0}, CHANGE*" -f $script:readAccessGroup)
        $details | Should -BeLike "*Remark            *"
    }

    It 'should grant multiple full access permissions' {
        Install-SmbShare -Name $shareName -Path $PSScriptRoot -Description $script:Remarks -ReadAccess $script:fullAccessGroup,$script:changeAccessGroup,$script:readAccessGroup
        $details = (net share $script:ShareName) -join ([Environment]::NewLine)
        $details | Should -BeLike ("*{0}, READ*" -f $script:fullAccessGroup)
        $details | Should -BeLike ("*{0}, READ*" -f $script:changeAccessGroup)
        $details | Should -BeLike ("*{0}, READ*" -f $script:readAccessGroup)
        $details | Should -BeLike "*Remark            *"
    }

    It 'should set remarks' {
        $expectedRemarks = 'Hello, workd.'
        Invoke-NewShare -Remarks $expectedRemarks

        $details = Get-Share
        $details.Description | Should -Be $expectedRemarks
    }

    It 'should handle path with trailing slash' {
        Install-SmbShare $script:ShareName -Path "$PSScriptRoot\"

        Assert-ShareCreated
    }

    It 'should create share directory' {
        $tempDir = New-CTempDirectory -Prefix 'Carbon_Test-InstallSmbShare'
        $shareDir = Join-Path -Path $tempDir -ChildPath 'Grandparent\Parent\Child'
        $shareDir | Should -Not -Exist
        Invoke-NewShare -Path $shareDir
        Assert-ShareCreated
        $shareDir | Should -Exist
    }

    It 'should update path' {
        $tempDir = New-CTempDirectory -Prefix $PSCommandPath
        try
        {
            Install-CFileShare -Name $script:ShareName -Path $script:SharePath
            Assert-Share -ReadAccess 'Everyone'

            Install-CFileShare -Name $script:ShareName -Path $tempDir
            Assert-Share -Path $tempDir.FullName -ReadAccess 'Everyone'
        }
        finally
        {
            Remove-Item -Path $tempDir
        }
    }

    It 'should update description' {
        Install-CFileShare -Name $script:ShareName -Path $script:SharePath -Description 'first'
        Assert-Share -ReadAccess 'Everyone' -Description 'first'

        Install-CFileShare -Name $script:ShareName -Path $script:SharePath -Description 'second'
        Assert-Share -ReadAccess 'everyone' -Description 'second'
    }

    It 'should add new permissions to existing share' {
        Install-CFileShare -Name $script:ShareName -Path $script:SharePath
        Assert-Share -ReadAccess 'Everyone'

        Install-CFileShare -Name $script:ShareName -Path $script:SharePath -FullAccess $script:fullAccessGroup -ChangeAccess $script:changeAccessGroup -ReadAccess $script:readAccessGroup
        Assert-Share -FullAccess $script:fullAccessGroup -ChangeAccess $script:changeAccessGroup -ReadAccess $script:readAccessGroup
    }

    It 'should remove existing permissions' {
        Install-CFileShare -Name $script:ShareName -Path $script:SharePath -FullAccess $script:fullAccessGroup
        Assert-Share -FullAccess $script:fullAccessGroup

        Install-CFileShare -Name $script:ShareName -Path $script:SharePath
        Assert-Share -ReadAccess 'Everyone'
    }

    It 'should update existing permissions' {
        Install-CFileShare -Name $script:ShareName -Path $script:SharePath -FullAccess $script:changeAccessGroup
        Assert-Share -FullAccess $script:changeAccessGroup

        Install-CFileShare -Name $script:ShareName -Path $script:SharePath -ChangeAccess $script:changeAccessGroup
        Assert-Share -ChangeAccess $script:changeAccessGroup
    }

    It 'should delete file share if forced' {
        $output = Install-CFileShare -Name $script:ShareName -Path $script:SharePath
        $output | Should -BeNullOrEmpty

        $share = Get-CFileShare -Name $script:ShareName -AsWmiObject
        $share.SetShareInfo(1, $share.Description, $null)

        $output = Install-CFileShare -Name $script:ShareName -Path $script:SharePath -Force
        $output | Should -BeNullOrEmpty

        $share = Get-CFileShare -Name $script:ShareName
        $share.MaximumAllowed | Should -Not -Be 1
    }

    It 'should share drive' {
        $drive = Split-Path -Qualifier -Path $PSScriptRoot
        $result = Install-CFileShare -Name $script:ShareName -Path $drive
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
        Assert-ShareCreated
    }
}
