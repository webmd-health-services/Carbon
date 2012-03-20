

$Path = $null

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $Path = @([IO.Path]::GetTempFileName())[0]
}

function TearDown
{
    if( Test-Path $Path )
    {
        Remove-Item $Path
    }
}

function Invoke-GrantPermissions($Identity, $Permissions)
{
    Grant-Permissions -Identity $Identity -Permission $Permissions -Path $Path.ToString()
}

function Test-ShouldGrantPermissionOnFile
{
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionOnDirectory
{
    $Path = New-TempDir
    
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Write-Host $SCRIPT:Dir
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionsOnRegistryKey
{
    $regKey = 'hkcu:\TestGrantPermissions'
    New-Item $regKey
    
    try
    {
        Grant-Permissions -Identity 'BUILTIN\Administrators' -Permissions 'ReadKey' -Path $regKey
        Assert-Permissions 'BUILTIN\Administrators' -Permissions 'ReadKey' -Path $regKey
    }
    finally
    {
        Remove-Item $regKey
    }
}

function Test-ShouldFailIfIncorrectPermissions
{
    $failed = $false
    try
    {
        Invoke-GrantPermissions 'BUILTIN\Administrators' 'BlahBlahBlah'
    }
    catch
    {
        $failed = $_ -like 'Invalid FileSystemRights: BlahBlahBlah.  Must be one of ListDirectory*'
    }
    
    Assert-True $failed "Didn't fail to set permissions with a bad permission."
    
}

function Assert-Permissions($identity, $permissions, $path = $Path)
{
    $providerName = (Get-PSDrive (Split-Path -Qualifier (Resolve-Path $path)).Trim(':')).Provider.Name
    
    $rights = 0
    foreach( $permission in $permissions )
    {
        $rights = $rights -bor ($permission -as "Security.AccessControl.$($providerName)Rights")
    }
    
    $acl = Get-Acl $path
    Assert-NotNull $acl "Didn't get ACLs for $path."
    
    $hasPermission = $false
    foreach( $accessRights in $acl.Access )
    {
        $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
        if( Test-Path $path -PathType Container )
        {
            $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                                        [Security.AccessControl.InheritanceFlags]::ObjectInherit
        }
        $hasExpectedInheritance = ($accessRights.InheritanceFlags -band $expectedInheritanceFlags) -eq $expectedInheritanceFlags
        $hasExpectedRights = ($accessRights."$($providerName)Rights" -band $rights) -eq $rights
        $isExpectedIdentity = ($accessRights.IdentityReference -eq $identity )
        
        if( $hasExpectedInheritance -and $hasExpectedRights -and $isExpectedIdentity )
        {
            $hasPermission = $true
            break
        }
    }
    
    Assert-True $hasPermission "$identity doesn't have $permissions on $path."
}

