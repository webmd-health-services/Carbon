
$parentFSPath = New-TempDir
$childFSPath = Join-Path $parentFSPath 'TestUnprotectAclAccessRules'

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)

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
    Unprotect-AclAccessRules -Path $childFSPath
    $acl = Get-Acl $childFSPath
    Assert-NotEqual $previousAcl.Access.Count $acl.Access.Count
    Assert-Equal 1 $acl.Access.Count
    $acl.Access | 
        ForEach-Object { Assert-False $_.IsInherited }
}

function Test-ShouldPreserveInheritedAccessRules
{
    $previousAcl = Get-Acl $childFSPath
    Unprotect-AclAccessRules -Path $childFSPath -Preserve
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
    Get-Item $childFSPath | Unprotect-AclAccessRules
    $acl = Get-Acl $childFSPath
    Assert-Equal 1 $acl.Access.Count
}