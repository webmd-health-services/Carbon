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

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)

    Remove-Share
}

function TearDown
{
    Remove-Share
    
    Remove-Module Carbon
}

function Remove-Share
{
    $share = Get-Share
    if( $share -ne $null )
    {
        $share.Delete()
    }
}

function Invoke-NewShare($Permissions = @(), $Remarks = '')
{
    Install-Share -Name $ShareName -Path $TestDir -Permissions $Permissions -Description $Remarks
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
    Invoke-NewShare -Permissions 'ADMINISTRATORs,FULL'
    $details = net share """$ShareName"""
    Assert-ContainsLike $details "BUILTIN\Administrators, FULL" 'Permissions not set on share.'
}

function Test-ShouldDeleteThenRecreateShare
{
    Invoke-NewShare -Permissions 'Administrators,FULL'
    
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
    Install-Share $ShareName -Path "$TestDir\"
    
    Assert-ShareCreated
}

function Assert-ShareCreated
{
    $share = Get-Share
    Assert-NotNull $share "Share not created."
}
