
function Write-IisVerbose
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The name of the site.
        $SiteName,

        [string]
        $VirtualPath = '',

        [Parameter(Position=1)]
        [string]
        # The name of the setting.
        $Name,

        [Parameter(Position=2)]
        [string]
        $OldValue = '',

        [Parameter(Position=3)]
        [string]
        $NewValue = ''
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $VirtualPath )
    {
        $SiteName = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath
    }

    Write-Verbose -Message ('[IIS Website] [{0}] {1,-34} {2} -> {3}' -f $SiteName,$Name,$OldValue,$NewValue)
}

