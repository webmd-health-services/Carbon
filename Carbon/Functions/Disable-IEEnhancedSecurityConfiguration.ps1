
function Disable-CIEEnhancedSecurityConfiguration
{
    <#
    .SYNOPSIS
    Disables Internet Explorer's Enhanced Security Configuration. 
    .DESCRIPTION
    By default, Windows locks down Internet Explorer so that users can't visit certain sites.  This function disables that enhanced security.  This is necessary if you have automated processes that need to run and interact with Internet Explorer.
    
    You may also need to call `Enable-CIEActivationPermission`, so that processes have permission to start Internet Explorer.
    
    .EXAMPLE
    Disable-CIEEnhancedSecurityConfiguration
    .LINK
    http://technet.microsoft.com/en-us/library/dd883248(v=WS.10).aspx
    .LINK
    Enable-CIEActivationPermission
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $adminPath = "SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $userPath =  "SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    # Yes.  They are different. Right                                     here ^

    $paths = @( $adminPath, $userPath )

    if( $PSCmdlet.ShouldProcess( 'Internet Explorer', 'disabling enhanced security configuration' ) )
    {
        foreach( $path in $paths )
        {
            $hklmPath = Join-Path -Path 'hklm:\' -ChildPath $path
            if( -not (Test-Path -Path $hklmPath) )
            {
                Write-Warning ('Applying Enhanced Security Configuration registry key ''{0}'' not found.' -f $hklmPath)
                return
            }
            Set-CRegistryKeyValue -Path $hklmPath -Name 'IsInstalled' -DWord 0
        }

        Write-Verbose ('Calling iesetup.dll hardening methods.')
        Rundll32 iesetup.dll, IEHardenLMSettings
        Rundll32 iesetup.dll, IEHardenUser
        Rundll32 iesetup.dll, IEHardenAdmin 

        foreach( $path in $paths )
        {
            $hkcuPath = Join-Path -Path 'hkcu:\' -ChildPath $path
            if( Test-Path -Path $hkcuPath )
            {
                Remove-Item -Path $hkcuPath
            }
        }

    }
}

