
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

[Carbon.Identity]$user = $null
$url = 'http://test-revokehttpurlpermission:10383/'

function Start-Test
{
    Install-User -Credential (New-Credential -UserName 'CarbonTestUser' -Password 'Password1')
    $user = Resolve-Identity -Name 'CarbonTestUser'
    Grant-HttpUrlPermission -Url $url -Principal $user.FullName -Permission Listen
}

function Stop-Test
{
    netsh http delete urlacl url=$url
}

function Test-ShouldRevokePermission
{
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Assert-NoError
    Assert-Null (Get-HttpUrlAcl -Url $url -ErrorAction Ignore)
}

function Test-ShouldRevokePermissionMultipleTimes
{
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Revoke-HttpUrlPermission -Url $url -Principal $user
    Assert-NoError
    Assert-Null (Get-HttpUrlAcl -Url $url -ErrorAction Ignore)
}