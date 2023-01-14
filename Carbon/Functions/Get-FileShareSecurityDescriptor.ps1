
function Get-CFileShareSecurityDescriptor
{
    <#
    .SYNOPSIS
    INTERNAL

    .DESCRIPTION
    INTERNAL

    .EXAMPLE
    INTERNAL
    #>
    [CmdletBinding()]
    param(
        # The share's name.
        [Parameter(Mandatory=$true)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name $Name
    if( -not $share )
    {
        return
    }

    $lsss = Get-CCimInstance -Class 'Win32_LogicalShareSecuritySetting' -Filter "name='$($Name)'"
    if( -not $lsss )
    {
        return
    }

    if( Test-CCimAvailable )
    {
        $result = Invoke-CimMethod -InputObject $lsss -MethodName 'GetSecurityDescriptor'
    }
    else
    {
        $result = $lsss.GetSecurityDescriptor()
    }

    if( -not $result )
    {
        return
    }

    if( $result.ReturnValue )
    {
        $win32lsssErrors = @{
            [uint32]2 = 'Access Denied';
            [uint32]8 = 'Unknown Failure';
            [uint32]9 = 'Privilege Missing';
            [uint32]21 = 'Invalid Parameter';
        }

        $msg = "Failed to get ""$($Name)"" share''s security descriptor: WMI error code $($result.ReturnValue): " +
               "$($win32lsssErrors[$result.ReturnValue])."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return $result.Descriptor
}

