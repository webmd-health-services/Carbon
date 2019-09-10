
function Unlock-CIisConfigurationSection
{
    <#
    .SYNOPSIS
    Unlocks a section in the IIS server configuration.

    .DESCRIPTION
    Some sections/areas are locked by IIS, so that websites can't enable those settings, or have their own custom configurations.  This function will unlocks those locked sections.  You have to know the path to the section.  You can see a list of locked sections by running:

        C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Unlock-IisConfigSection -Name 'system.webServer/cgi'

    Unlocks the CGI section so that websites can configure their own CGI settings.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The path to the section to unlock.  For a list of sections, run
        #
        #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
        $SectionPath
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $SectionPath |
        ForEach-Object {
            $section = Get-CIisConfigurationSection -SectionPath $_
            $section.OverrideMode = 'Allow'
            if( $pscmdlet.ShouldProcess( $_, 'unlocking IIS configuration section' ) )
            {
                $section.CommitChanges()
            }
        }
}


