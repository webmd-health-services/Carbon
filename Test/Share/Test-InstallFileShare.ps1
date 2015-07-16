# Copyright 2012 Aaron Jensen
# 
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

$ShareName = 'New Share Test'
$SharePath = $TestDir
$fullAccessGroup = 'Carbon Share Full'
$changeAccessGroup = 'CarbonShareChange'
$readAccessGroup = 'CarbonShareRead'
$noAccessGroup = 'CarbonShareNone'
$Remarks = [Guid]::NewGuid().ToString()

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    Install-Group -Name $fullAccessGroup -Description 'Carbon module group for testing full share permissions.'
    Install-Group -Name $changeAccessGroup -Description 'Carbon module group for testing change share permissions.'
    Install-Group -Name $readAccessGroup -Description 'Carbon module group for testing read share permissions.'
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

function Test-ShouldDeleteThenRecreateShare
{
    Invoke-NewShare -FullAccess 'Administrators'
    
    Invoke-NewShare
    $details = net share """$ShareName"""
    Assert-ContainsNotLike $details "Administrators, FULL" "Share not deleted and re-created."
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

function Assert-ShareCreated
{
    $share = Get-Share
    Assert-NotNull $share "Share not created."
}
