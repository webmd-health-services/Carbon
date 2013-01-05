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

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
	
	$parentFSPath = New-TempDir
	$childFSPath = Join-Path $parentFSPath 'TestUnprotectAclAccessRules'
	
    $null = New-Item $childFSPath -ItemType Container
    Grant-Permissions -Identity Everyone -Permissions FullControl -Path $childFSPath
}

function TearDown
{
    
    Remove-Item $parentFSPath -Recurse -Force
    
    REmove-Module Carbon
}

function Test-ShouldRemoveInheritedAccess
{
    $previousAcl = Get-Acl $childFSPath
    Protect-Acl -Path $childFSPath
    $acl = Get-Acl $childFSPath
    Assert-NotEqual $previousAcl.Access.Count $acl.Access.Count
    Assert-Equal 1 $acl.Access.Count
    $acl.Access | 
        ForEach-Object { Assert-False $_.IsInherited }
}

function Test-ShouldPreserveInheritedAccessRules
{
    $previousAcl = Get-Acl $childFSPath
    Protect-Acl -Path $childFSPath -Preserve
    $acl = Get-Acl $childFSPath
    Assert-Equal $previousAcl.Access.Count $acl.Access.Count
    for( $idx = 0; $idx -lt $acl.Access.Count; $idx++ )
    {
        $expectedRule = $previousAcl.Access[$idx]
        $actualRule = $previousAcl.Access[$idx]
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
    $acl = Get-Acl $childFSPath
    Assert-Equal 1 $acl.Access.Count
}