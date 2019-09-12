
function Uninstall-CIisWebsite
{
    <#
    .SYNOPSIS
    Removes a website

    .DESCRIPTION
    Pretty simple: removes the website named `Name`.  If no website with that name exists, nothing happens.

    Beginning with Carbon 2.0.1, this function is not available if IIS isn't installed.

    .LINK
    Get-CIisWebsite
    
    .LINK
    Install-CIisWebsite
    
    .EXAMPLE
    Uninstall-CIisWebsite -Name 'MyWebsite'
    
    Removes MyWebsite.

    .EXAMPLE
    Uninstall-CIisWebsite 1

    Removes the website whose ID is 1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        # The name or ID of the website to remove.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( Test-CIisWebsite -Name $Name )
    {
        $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
        try
        {
            $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
            $manager.Sites.Remove( $site )
            $manager.CommitChanges()
        }
        finally
        {
            $manager.Dispose()
        }
    }
}

Set-Alias -Name 'Remove-IisWebsite' -Value 'Uninstall-CIisWebsite'

