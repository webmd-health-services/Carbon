
function Enable-CIEActivationPermission
{
    <#
    .SYNOPSIS
    Grants all users permission to start/launch Internet Explorer.
    
    .DESCRIPTION
    By default, unprivileged users can't launch/start Internet Explorer. This prevents those users from using Internet Explorer to run automated, browser-based tests.  This function modifies Windows so that all users can launch Internet Explorer.
    
    You may also need to call Disable-CIEEnhancedSecurityConfiguration, so that Internet Explorer is allowed to visit all websites.
    
    .EXAMPLE
    Enable-CIEActivationPermission

    .LINK
    Disable-CIEEnhancedSecurityConfiguration
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sddlForIe =   "O:BAG:BAD:(A;;CCDCSW;;;SY)(A;;CCDCLCSWRP;;;BA)(A;;CCDCSW;;;IU)(A;;CCDCLCSWRP;;;S-1-5-21-762517215-2652837481-3023104750-5681)"
    $binarySD = ([wmiclass]"Win32_SecurityDescriptorHelper").SDDLToBinarySD($sddlForIE)
    $ieRegPath = "hkcr:\AppID\{0002DF01-0000-0000-C000-000000000046}"
    $ieRegPath64 = "hkcr:\Wow6432Node\AppID\{0002DF01-0000-0000-C000-000000000046}"

    if(-not (Test-Path "HKCR:\"))
    {
        $null = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }

    if( $PSCmdlet.ShouldProcess( 'Internet Explorer', 'enabling launch and activation permission' ) )
    {
        Set-CRegistryKeyValue -Path $ieRegPath -Name '(Default)' -String "Internet Explorer(Ver 1.0)"
        Set-CRegistryKeyValue -Path $ieRegPath64 -Name '(Default)' -String "Internet Explorer(Ver 1.0)"

        Set-CRegistryKeyValue -Path $ieRegPath -Name 'LaunchPermission' -Binary $binarySD.binarySD
        Set-CRegistryKeyValue -Path $ieRegPath64 -Name 'LaunchPermission' -Binary $binarySD.binarySD
    }
}

Set-Alias -Name 'Enable-IEActivationPermissions' -Value 'Enable-CIEActivationPermission'
