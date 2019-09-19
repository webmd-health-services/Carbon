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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)

$ShareName = $null
$SharePath = $TestDir
$fullAccessGroup = 'Carbon Share Full'
$changeAccessGroup = 'CarbonShareChange'
$readAccessGroup = 'CarbonShareRead'
$noAccessGroup = 'CarbonShareNone'
$Remarks = [Guid]::NewGuid().ToString()

Install-Group -Name $fullAccessGroup -Description 'Carbon module group for testing full share permissions.'
Install-Group -Name $changeAccessGroup -Description 'Carbon module group for testing change share permissions.'
Install-Group -Name $readAccessGroup -Description 'Carbon module group for testing read share permissions.'

function Start-Test
{
    $shareName = 'CarbonInstallShareTest{0}' -f [IO.Path]::GetRandomFileName()
    Remove-Share
}

function Stop-Test
{
    Remove-Share
}

function Remove-Share
{
    $share = Get-Share
    if( $share -ne $null )
    {
        $share.Delete()
    }
}

function Invoke-NewShare($Path = $TestDir, $FullAccess = @(), $ChangeAccess = @(), $ReadAccess = @(), $Remarks = '')
{
    Install-SmbShare -Name $ShareName -Path $Path -Description $Remarks `
                     -FullAccess $FullAccess `
                     -ChangeAccess $ChangeAccess `
                     -ReadAccess $ReadAccess 
    Assert-ShareCreated
}

function Get-Share
{
    return Get-WmiObject Win32_Share -Filter "Name='$ShareName'"
}


function Test-ShouldCreateShare
{
    Invoke-NewShare
    Assert-Share -ReadAccess 'EVERYONE'
}

function Test-ShouldGrantPermissions
{
    Assert-True ($fullAccessGroup -like '* *') 'full access group must contain a space.'
    Invoke-NewShare -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, FULL" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details "Remark            "
}

function Test-ShouldGrantPermissionsTwice
{
    Assert-True ($fullAccessGroup -like '* *') 'full access group must contain a space.'
    Invoke-NewShare -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    Invoke-NewShare -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, FULL" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details "Remark            "
}

function Test-ShouldGrantMultipleFullAccessPermissions
{
    Install-SmbShare -Name $shareName -Path $TestDir -Description $Remarks -FullAccess $fullAccessGroup,$changeAccessGroup,$readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, FULL" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, FULL" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, FULL" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("Remark            {0}" -f $Remarks)
}

function Test-ShouldGrantMultipleChangeAccessPermissions
{
    Install-SmbShare -Name $shareName -Path $TestDir -Description $Remarks -ChangeAccess $fullAccessGroup,$changeAccessGroup,$readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, CHANGE" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("Remark            {0}" -f $Remarks)
}

function Test-ShouldGrantMultipleFullAccessPermissions
{
    Install-SmbShare -Name $shareName -Path $TestDir -Description $Remarks -ReadAccess $fullAccessGroup,$changeAccessGroup,$readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, READ" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("Remark            {0}" -f $Remarks)
}

function Test-ShouldSetRemarks
{
    $expectedRemarks = 'Hello, workd.'
    Invoke-NewShare -Remarks $expectedRemarks
    
    $details = Get-Share
    Assert-Equal $expectedRemarks $details.Description 'Share description not set.'
}

function Test-ShouldHandlePathWithTrailingSlash
{
    Install-SmbShare $ShareName -Path "$TestDir\"
    
    Assert-ShareCreated
}

function Test-ShouldCreateShareDirectory
{
    $tempDir = New-TempDir -Prefix 'Carbon_Test-InstallSmbShare'
    $shareDir = Join-Path -Path $tempDir -ChildPath 'Grandparent\Parent\Child'
    Assert-DirectoryDoesNotExist $shareDir
    Invoke-NewShare -Path $shareDir
    Assert-ShareCreated
    Assert-DirectoryExists $shareDir
}

function Test-ShouldUpdatePath
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    try
    {
        Install-FileShare -Name $ShareName -Path $SharePath 
        Assert-Share -ReadAccess 'Everyone'

        Install-FileShare -Name $ShareName -Path $tempDir 
        Assert-Share -Path $tempDir.FullName -ReadAccess 'Everyone'
    }
    finally
    {
        Remove-Item -Path $tempDir
    }
}

function Test-ShouldUpdateDescription
{
    Install-FileShare -Name $ShareName -Path $SharePath -Description 'first'
    Assert-Share -ReadAccess 'Everyone' -Description 'first'

    Install-FileShare -Name $ShareName -Path $SharePath -Description 'second'
    Assert-Share -ReadAccess 'everyone' -Description 'second'
}

function Test-ShouldAddNewPermissionsToExistingShare
{
    Install-FileShare -Name $ShareName -Path $SharePath 
    Assert-Share -ReadAccess 'Everyone'

    Install-FileShare -Name $ShareName -Path $SharePath -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    Assert-Share -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
}

function Test-ShouldRemoveExistingPermissions
{
    Install-FileShare -Name $ShareName -Path $SharePath -FullAccess $fullAccessGroup
    Assert-Share -FullAccess $fullAccessGroup

    Install-FileShare -Name $ShareName -Path $SharePath
    Assert-Share -ReadAccess 'Everyone'
}

function Test-ShouldUpdateExistingPermissions
{
    Install-FileShare -Name $ShareName -Path $SharePath -FullAccess $changeAccessGroup
    Assert-Share -FullAccess $changeAccessGroup

    Install-FileShare -Name $ShareName -Path $SharePath -ChangeAccess $changeAccessGroup
    Assert-Share -ChangeAccess $changeAccessGroup
}

function Test-ShouldDeleteFileShareIfForced
{
    $output = Install-FileShare -Name $ShareName -Path $SharePath 
    Assert-Null $output

    $share = Get-FileShare -Name $ShareName
    $share.SetShareInfo( 1, $share.Description, $null )

    $output = Install-FileShare -Name $ShareName -Path $SharePath -Force
    Assert-Null $output

    $share = Get-FileShare -Name $ShareName
    Assert-NotEqual 1 $share.MaximumAllowed
}

function Test-ShouldShareDrive
{
    $drive = Split-Path -Qualifier -Path $PSScriptRoot
    $result = Install-FileShare -Name $ShareName -Path $drive
    Assert-Null $result
    Assert-NoError
    Assert-ShareCreated
}

function Assert-ShareCreated
{
    $share = Get-Share
    Assert-NotNull $share "Share not created."
}

function Assert-Share
{
    param(
        $Name = $ShareName,
        $Path = $SharePath,
        $Description = '',
        $FullAccess,
        $ChangeAccess,
        $ReadAccess
    )

    Assert-True (Test-FileShare -Name $Name)

    $share = Get-FileShare -Name $Name
    Assert-NotNull $share

    Assert-Equal $Description $share.Description
    Assert-Equal $Path $share.Path

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
                $perm = Get-FileSharePermission -Name $Name -Identity $idName
                Assert-NotNull $perm
                Assert-Equal $perm.ShareRights $ExpectedRigths
            }
        }
        else
        {
            Assert-Null (Get-FileSharePermission -Name $Name | Where-Object { $_.ShareRights -eq $ExpectedRigths }) ('found {0} access rules when there shouldn''t be' -f $ExpectedRigths)
        }
    }

    Assert-ShareRight $FullAccess ([Carbon.Security.ShareRights]::FullControl)
    Assert-ShareRight $ChangeAccess ([Carbon.Security.ShareRights]::Change)
    Assert-ShareRight $ReadAccess ([Carbon.Security.ShareRights]::Read)
}
