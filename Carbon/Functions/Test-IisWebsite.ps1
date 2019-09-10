
function Test-CIisWebsite
{
    <#
    .SYNOPSIS
    Tests if a website exists.

    .DESCRIPTION
    Returns `True` if a website with name `Name` exists.  `False` if it doesn't.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Test-CIisWebsite -Name 'Peanuts'

    Returns `True` if the `Peanuts` website exists.  `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose existence to check.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
    try
    {
        $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
        if( $site )
        {
            return $true
        }
        return $false
    }
    finally
    {
        $manager.Dispose()
    }
}

Set-Alias -Name Test-IisWebsiteExists -Value Test-CIisWebsite

