
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Invoke-FindUserOrGroup($name)
{
    return Find-UserOrGroup -Name $name
}

function Ignore-ShouldFindLocalUser
{
    $user = Invoke-FindUserOrGroup 'Administrator'
    Assert-IsNotNull $user 'Unable to find Administrator.'
    Assert-Equal 'Administrator' $user.Name
}

function Test-ShouldFindLocalGroup
{
    $group = Invoke-FindUserOrGroup 'Administrators'
    Assert-IsNotNull $group 'Unable to find administrators'
    Assert-Equal 'Administrators' $group.Name
}

function Test-ShouldNotFindNonExistentGroup
{
    $group = Invoke-FindUserOrGroup 'fdsjklfjsdakfjsdlkfjlskdfjsldkafj'
    Assert-Null $group 'Found a non-existent user/group.'
}