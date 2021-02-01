
function Uninstall-CGroup
{
    <#
    .SYNOPSIS
    Removes a *local* group.
    
    .DESCRIPTION
    The `Uninstall-CGroup` function removes a *local* group using .NET's [DirectoryServices.AccountManagement API](https://msdn.microsoft.com/en-us/library/system.directoryservices.accountmanagement.aspx). If the group doesn't exist, returns without doing any work or writing any errors.
    
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
    Test-CGroupMember

    .INPUTS
    System.String

    .EXAMPLE
    Uninstall-WhsGroup -Name 'TestGroup1'
    
    Demonstrates how to uninstall a group. In this case, the `TestGroup1` group is removed.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        # The name of the group to remove/uninstall.
        $Name
    )

	Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CGroup -Name $Name) )
    {
        return
    }

    $group = Get-CGroup -Name $Name
    if( -not $group )
    {
        return
    }

    if( $PSCmdlet.ShouldProcess(('local group {0}' -f $Name), 'remove') )
    {
        Write-Verbose -Message ('[{0}]              -' -f $Name)
        $group.Delete()
    }

}
