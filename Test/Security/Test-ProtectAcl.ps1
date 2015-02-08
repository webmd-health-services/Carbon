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

$parentFSPath = $null 
$childFSPath = $null
$originalAcl = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
	$parentFSPath = New-TempDir
	$childFSPath = Join-Path $parentFSPath 'TestUnprotectAclAccessRules'
	
    $null = New-Item $childFSPath -ItemType Container
    Grant-Permission -Identity Everyone -Permission FullControl -Path $childFSPath
    $originalAcl = Get-Acl $childFSPath
}

function Stop-Test
{
    Remove-Item $parentFSPath -Recurse -Force
}

function Test-ShouldRemoveInheritedAccess
{
    Protect-Acl -Path $childFSPath
    Assert-InheritedPermissionRemoved
}

function Test-ShouldPreserveInheritedAccessRules
{
    Protect-Acl -Path $childFSPath -Preserve
    $acl = Get-Acl $childFSPath
    Assert-True ($acl.Access.Count -le $originalAcl.Access.Count)
    for( $idx = 0; $idx -lt $acl.Access.Count; $idx++ )
    {
        $expectedRule = $originalAcl.Access[$idx]
        $actualRule = $originalAcl.Access[$idx]
        Assert-Equal $expectedRule.FileSystemRights $actualRule.FileSystemRights
        Assert-Equal $expectedRule.AccessControlType $actualRule.AccessControlType
        Assert-Equal $expectedRule.IdentityReference.Value $actualRule.IdentityReference.Value
        Assert-Equal $expectedRule.IsInherited $actualRule.IsInherited
        Assert-Equal $expectedRule.InheritanceFlags $actualRule.InheritanceFlags
        Assert-Equal $expectedRule.PropagationFlags $actualRule.PropagationFlags
    }
}

function Test-ShouldAcceptPathFromPipelineInput
{
    Get-Item $childFSPath | Protect-Acl
    Assert-InheritedPermissionRemoved
}

function Assert-InheritedPermissionRemoved
{
    [object[]]$inherited = $originalAcl.Access | Where-Object { $_.IsInherited }
    $acl = Get-Acl $childFSPath
    Assert-Equal ($originalAcl.Access.Count - $inherited.Count) $acl.Access.Count
    $acl.Access | 
        ForEach-Object { Assert-False $_.IsInherited }
}