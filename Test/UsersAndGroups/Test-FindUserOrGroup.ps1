
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

function Test-ShouldFindLocalUser
{
    Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)'" | ForEach-Object {
        $username = $_.Name
        $user = Invoke-FindUserOrGroup $username
        Assert-IsNotNull $user "Unable to find local user $username."
        Assert-Equal $username $user.Name
    }
}

function Test-ShouldFindDomainUser
{
    $user = Invoke-FindUserOrGroup "$($env:USERDOMAIN)\Administrator"
    Assert-IsNotNull $user 'Unable to find Administrator'
    Assert-Equal 'Administrator' $User.Name
}

function Test-ShouldFindLocalGroup
{
    Get-WmiObject Win32_Group -Filter "Domain='$($env:ComputerName)'" | ForEach-Object {
        $groupName = $_.Name
        $group = Invoke-FindUserOrGroup $groupName
        Assert-IsNotNull $group "Unable to find '$groupName'."
        Assert-Equal $groupName $group.Name
    }
}

function Test-ShouldFindDomainGroup
{
    $group = Invoke-FindUserOrGroup "$($env:USERDOMAIN)\Administrator"
    Assert-IsNotNull $group 'Unable to find group'
    Assert-Equal 'Administrator' $group.Name
}

function Test-ShouldNotFindNonExistentGroup
{
    $group = Invoke-FindUserOrGroup 'fdsjklfjsdakfjsdlkfjlskdfjsldkafj'
    Assert-Null $group 'Found a non-existent user/group.'
}