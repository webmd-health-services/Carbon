
function Install-CGroup
{
    <#
    .SYNOPSIS
    Creates a new local group, or updates the settings for an existing group.

    .DESCRIPTION
    `Install-CGroup` creates a local group, or, updates a group that already exists.

    YOu can get a `System.DirectoryServices.AccountManagement.GroupPrincipal` object representing the group returned to you by using the `PassThru` switch. This object implements the `IDisposable` interface, which means it uses external resources that don't get garbage collected. When you're done using the object, make sure you call `Dispose()` to free those resources, otherwise you'll leak memory. All over the place.

    .EXAMPLE
    Install-CGroup -Name TIEFighters -Description 'Users allowed to be TIE fighter pilots.' -Members EMPIRE\Pilots,EMPIRE\DarthVader

    If the TIE fighters group doesn't exist, it is created with the given description and default members.  If it already exists, its description is updated and the given members are added to it.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group.
        $Name,
        
        [string]
        # A description of the group.
        $Description = '',
        
        [Alias('Members')]
        [string[]]
        # Members of the group.
        $Member = @(),

        [Switch]
        # Return the group as a `System.DirectoryServices.AccountManagement.GroupPrincipal`.
        #
        # This object uses external resources that don't get cleaned up by .NET's garbage collector. In order to avoid memory leaks, make sure you call its `Dispose()` method when you're done with it.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $group = Get-CGroup -Name $Name -ErrorAction Ignore

    if( $group )
    {
        $ctx = $group.Context
    }
    else
    {
        $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    }

    $operation = 'update'
    $save = $false
    $new = $false
    if( -not $group )
    {
        $operation = 'create'
        $new = $true
        $group = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
        $group.Name = $Name
        $group.Description = $Description
        $save = $true
    }
    else
    {
        # We only update the description if one or the other has a value. This guards against setting description to $null from empty string and vice-versa.
        if( $group.Description -ne $Description -and ($group.Description -or $Description) )
        {
            Write-Verbose -Message ('[{0}] Description  {1} -> {2}' -f $Name,$group.Description,$Description)
            $group.Description = $Description
            $save = $true
        }
    }

    try
    {

        if( $save -and $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), $operation ) )
        {
            if( $new )
            {
                Write-Verbose -Message ('[{0}]              +' -f $Name)
            }
            $group.Save()
        }

        if( $Member -and $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), 'adding members' ) )
        {
            Add-CGroupMember -Name $Name -Member $Member
        }
    
        if( $PassThru )
        {
            return $group
        }
    }
    finally
    {
        if( -not $PassThru )
        {
            $group.Dispose()
            $ctx.Dispose()
        }

    }
}

