
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

[Carbon.Identity]$user = $null
$url = 'http://test-granthttpurlpermission:10383/'

function Start-Test
{
    Install-User -Credential (New-Credential -UserName 'CarbonTestUser' -Password 'Password1')
    $user = Resolve-Identity -Name 'CarbonTestUser'
}

function Stop-Test
{
    netsh http delete urlacl url=$url
}

function Test-ShouldRegisterAUrl
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Register
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Register)
}

function Test-ShouldGrantJustDelegatePermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Delegate
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Delegate)
}

function Test-ShouldGrantJustReadPermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Read
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Read)
}

function Test-ShouldChangePermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Register
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Register)

    Grant-HttpUrlPermission -Url $url -Principal $user -Permission RegisterAndDelegate
    Assert-NoError
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::RegisterAndDelegate)
}

function Test-ShouldGrantMultipleUsersPermission
{
    Grant-HttpUrlPermission -Url $url -Principal $user -Permission Register
    Assert-NoError

    Install-User -Credential (New-Credential -UserName 'CarbonTestUser2' -Password 'Password1') -PassThru
    $user2 = Resolve-Identity -Name 'CarbonTestUser2'

    Grant-HttpUrlPermission -Url $url -Principal $user2.FullName -Permission Register
    Assert-NoError

    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Register)
    Assert-Permission -ExpectedPermission ([Carbon.Security.HttpUrlAccessRights]::Register) -ExpectedUser $user2.FullName
}

function Assert-Permission
{
    param(
        $ExpectedUser = $user.FullName,
        $ExpectedPermission
    )

    $acl = Get-HttpUrlAcl -Url $url
    Assert-NoError
    Assert-NotNull $acl
    Assert-Equal $acl.Url $url
    $rule = $acl.Access | Where-Object { $_.IdentityReference -eq $ExpectedUser }
    Assert-NotNull $rule
    Assert-Equal $ExpectedPermission $rule.HttpUrlAccessRights $ExpectedUser
}