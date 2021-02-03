
function Test-CGroupMember
{
    <#
    .SYNOPSIS
    Tests if a user or group is a member of a *local* group.

    .DESCRIPTION
    The `Test-CGroupMember` function tests if a user or group is a member of a *local* group using [.NET's DirectoryServices.AccountManagement APIs](https://msdn.microsoft.com/en-us/library/system.directoryservices.accountmanagement.aspx). If the group or member you want to check don't exist, you'll get errors and `$null` will be returned. If `Member` is in the group, `$true` is returned. If `Member` is not in the group, `$false` is returned.

    The user running this function must have permission to access whatever directory the `Member` is in and whatever directory current members of the group are in.

    This function was added in Carbon 2.1.0.

    .LINK
    Add-CGroupMember

    .LINK
    Install-CGroup

    .LINK
    Remove-CGroupMember

    .LINK
    Test-CGroup

    .LINK
    Uninstall-CGroup

    .EXAMPLE
    Test-CGroupMember -GroupName 'SithLords' -Member 'REBELS\LSkywalker'

    Demonstrates how to test if a user is a member of a group. In this case, it tests if `REBELS\LSkywalker` is in the local `SithLords`, *which obviously he isn't*, so `$false` is returned.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group whose membership is being tested.
        $GroupName,

        [Parameter(Mandatory=$true)]
        [string] 
        # The name of the member to check.
        $Member
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CGroup -Name $GroupName) )
    {
        Write-Error -Message ('Group ''{0}'' not found.' -f $GroupName)
        return
    }

    $group = Get-CGroup -Name $GroupName
    if( -not $group )
    {
        return
    }
    
    $principal = Resolve-CIdentity -Name $Member
    if( -not $principal )
    {
        return
    }

    try
    {
        return $principal.IsMemberOfLocalGroup($group.Name)
    }
    catch
    {
        Write-Error -Message ('Checking if "{0}" is a member of local group "{1}" failed: {2}' -f $principal.FullName,$group.Name,$_)
    }
}
