function Install-Share
{
    <#
    .SYNOPSIS
    Creates a share, replacing the existing share (if any).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The share's name.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the share.
        $Path,
            
        [string]
        # A description of the share
        $Description = '',
        
        [string[]]
        # The share's permissions. Each item should be of the form: user,[READ | CHANGE | FULL]
        $Permissions = @()
    )

    $share = Get-WmiObject Win32_Share -Filter "Name='$Name'"
    if( $share -ne $null )
    {
        Write-Verbose "Share '$Name' exists and will be deleted."
        [void] $share.Delete()
    }

    $PermissionsArg = ''
    if( $Permissions.Length -gt 0 )
    {
        $PermissionsArg = $Permissions -join """ /GRANT:"""
        $PermissionsArg = """/GRANT:$PermissionsArg"""
    }
    
    net share $Name=$($Path.Trim('\')) /REMARK:$Description $PermissionsArg /CACHE:NONE /UNLIMITED
}
