
$ErrorActionPreference = 'Stop'

# Extended Type
if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'GetCarbonFileInfo') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (GetCarbonFileInfo).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptMethod -MemberName 'GetCarbonFileInfo' -Value {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            # The name of the Carbon file info property to get.
            $Name
        )

        Set-StrictMode -Version 'Latest'

        if( -not $this.Exists )
        {
            return
        }

        if( -not ($this | Get-Member -Name 'CarbonFileInfo') )
        {
            $this | Add-Member -MemberType NoteProperty -Name 'CarbonFileInfo' -Value (New-Object 'Carbon.IO.FileInfo' $this.FullName)
        }

        if( $this.CarbonFileInfo | Get-Member -Name $Name )
        {
            return $this.CarbonFileInfo.$Name
        }
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'FileIndex') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (FileIndex).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'FileIndex' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'FileIndex' )
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'LinkCount') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (LinkCount).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'LinkCount' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'LinkCount' )
    }
}

if( -not (Test-CTypeDataMember -TypeName 'System.IO.FileInfo' -MemberName 'VolumeSerialNumber') )
{
    Write-Timing ('Updating System.IO.FileInfo type data (ColumeSerialNumber).')
    Update-TypeData -TypeName 'System.IO.FileInfo' -MemberType ScriptProperty -MemberName 'VolumeSerialNumber' -Value {
        Set-StrictMode -Version 'Latest'
        return $this.GetCarbonFileInfo( 'VolumeSerialNumber' )
    }
}

Write-Timing ('Testing the module manifest.')
try
{
    $module = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve)
    if( -not $module )
    {
        return
    }

    Write-Timing ('Creating shims.')
    # We only need to shim functions that existed at the time we created this shim functionality.
    $shimmedFunctions = @(
        'Add-CGroupMember',
        'Add-CIisDefaultDocument',
        'Add-CTrustedHost',
        'Assert-CAdminPrivilege',
        'Assert-CFirewallConfigurable',
        'Assert-CService',
        'Clear-CDscLocalResourceCache',
        'Clear-CMofAuthoringMetadata',
        'Clear-CTrustedHost',
        'Complete-CJob',
        'Compress-CItem',
        'ConvertFrom-CBase64',
        'Convert-CSecureStringToString',
        'ConvertTo-CBase64',
        'ConvertTo-CContainerInheritanceFlags',
        'ConvertTo-CInheritanceFlag',
        'ConvertTo-CPropagationFlag',
        'ConvertTo-CSecurityIdentifier',
        'Convert-CXmlFile',
        'Copy-CDscResource',
        'Disable-CAclInheritance',
        'Disable-CFirewallStatefulFtp',
        'Disable-CIEEnhancedSecurityConfiguration',
        'Disable-CIisSecurityAuthentication',
        'Disable-CNtfsCompression',
        'Enable-CAclInheritance',
        'Enable-CFirewallStatefulFtp',
        'Enable-CIEActivationPermission',
        'Enable-CIisDirectoryBrowsing',
        'Enable-CIisSecurityAuthentication',
        'Enable-CIisSsl',
        'Enable-CNtfsCompression',
        'Expand-CItem',
        'Find-CADUser',
        'Format-CADSearchFilterValue',
        'Get-CADDomainController',
        'Get-CCertificate',
        'Get-CCertificateStore',
        'Get-CComPermission',
        'Get-CComSecurityDescriptor',
        'Get-CDscError',
        'Get-CDscWinEvent',
        'Get-CFileShare',
        'Get-CFileSharePermission',
        'Get-CFirewallRule',
        'Get-CGroup',
        'Get-CHttpUrlAcl',
        'Get-CIisApplication',
        'Get-CIisAppPool',
        'Get-CIisConfigurationSection',
        'Get-CIisHttpHeader',
        'Get-CIisHttpRedirect',
        'Get-CIisMimeMap',
        'Get-CIisSecurityAuthentication',
        'Get-CIisVersion',
        'Get-CIisWebsite',
        'Get-CIPAddress',
        'Get-CMsi',
        'Get-CMsmqMessageQueue',
        'Get-CMsmqMessageQueuePath',
        'Get-CPathProvider',
        'Get-CPathToHostsFile',
        'Get-CPerformanceCounter',
        'Get-CPermission',
        'Get-CPowerShellModuleInstallPath',
        'Get-CPowershellPath',
        'Get-CPrivilege',
        'Get-CProgramInstallInfo',
        'Get-CRegistryKeyValue',
        'Get-CScheduledTask',
        'Get-CServiceAcl',
        'Get-CServiceConfiguration',
        'Get-CServicePermission',
        'Get-CServiceSecurityDescriptor',
        'Get-CSslCertificateBinding',
        'Get-CTrustedHost',
        'Get-CUser',
        'Get-CWmiLocalUserAccount',
        'Grant-CComPermission',
        'Grant-CHttpUrlPermission',
        'Grant-CMsmqMessageQueuePermission',
        'Grant-CPermission',
        'Grant-CPrivilege',
        'Grant-CServiceControlPermission',
        'Grant-CServicePermission',
        'Initialize-CLcm',
        'Install-CCertificate',
        'Install-CDirectory',
        'Install-CFileShare',
        'Install-CGroup',
        'Install-CIisApplication',
        'Install-CIisAppPool',
        'Install-CIisVirtualDirectory',
        'Install-CIisWebsite',
        'Install-CJunction',
        'Install-CMsi',
        'Install-CMsmq',
        'Install-CMsmqMessageQueue',
        'Install-CPerformanceCounter',
        'Install-CRegistryKey',
        'Install-CScheduledTask',
        'Install-CService',
        'Install-CUser',
        'Invoke-CAppCmd',
        'Invoke-CPowerShell',
        'Join-CIisVirtualPath',
        'Lock-CIisConfigurationSection',
        'New-CCredential',
        'New-CJunction',
        'New-CRsaKeyPair',
        'New-CTempDirectory',
        'Protect-CString',
        'Read-CFile',
        'Remove-CDotNetAppSetting',
        'Remove-CEnvironmentVariable',
        'Remove-CGroupMember',
        'Remove-CHostsEntry',
        'Remove-CIisMimeMap',
        'Remove-CIniEntry',
        'Remove-CJunction',
        'Remove-CRegistryKeyValue',
        'Remove-CSslCertificateBinding',
        'Reset-CHostsFile',
        'Reset-CMsmqQueueManagerID',
        'Resolve-CFullPath',
        'Resolve-CIdentity',
        'Resolve-CIdentityName',
        'Resolve-CNetPath',
        'Resolve-CPathCase',
        'Resolve-CRelativePath',
        'Restart-CRemoteService',
        'Revoke-CComPermission',
        'Revoke-CHttpUrlPermission',
        'Revoke-CPermission',
        'Revoke-CPrivilege',
        'Revoke-CServicePermission',
        'Set-CDotNetAppSetting',
        'Set-CDotNetConnectionString',
        'Set-CEnvironmentVariable',
        'Set-CHostsEntry',
        'Set-CIisHttpHeader',
        'Set-CIisHttpRedirect',
        'Set-CIisMimeMap',
        'Set-CIisWebsiteID',
        'Set-CIisWebsiteSslCertificate',
        'Set-CIisWindowsAuthentication',
        'Set-CIniEntry',
        'Set-CRegistryKeyValue',
        'Set-CServiceAcl',
        'Set-CSslCertificateBinding',
        'Set-CTrustedHost',
        'Split-CIni',
        'Start-CDscPullConfiguration',
        'Test-CAdminPrivilege',
        'Test-CDotNet',
        'Test-CDscTargetResource',
        'Test-CFileShare',
        'Test-CFirewallStatefulFtp',
        'Test-CGroup',
        'Test-CGroupMember',
        'Test-CIdentity',
        'Test-CIisAppPool',
        'Test-CIisConfigurationSection',
        'Test-CIisSecurityAuthentication',
        'Test-CIisWebsite',
        'Test-CIPAddress',
        'Test-CMsmqMessageQueue',
        'Test-CNtfsCompression',
        'Test-COSIs32Bit',
        'Test-COSIs64Bit',
        'Test-CPathIsJunction',
        'Test-CPerformanceCounter',
        'Test-CPerformanceCounterCategory',
        'Test-CPermission',
        'Test-CPowerShellIs32Bit',
        'Test-CPowerShellIs64Bit',
        'Test-CPrivilege',
        'Test-CRegistryKeyValue',
        'Test-CScheduledTask',
        'Test-CService',
        'Test-CSslCertificateBinding',
        'Test-CTypeDataMember',
        'Test-CUncPath',
        'Test-CUser',
        'Test-CWindowsFeature',
        'Test-CZipFile',
        'Uninstall-CCertificate',
        'Uninstall-CDirectory',
        'Uninstall-CFileShare',
        'Uninstall-CGroup',
        'Uninstall-CIisAppPool',
        'Uninstall-CIisWebsite',
        'Uninstall-CJunction',
        'Uninstall-CMsmqMessageQueue',
        'Uninstall-CPerformanceCounterCategory',
        'Uninstall-CScheduledTask',
        'Uninstall-CService',
        'Uninstall-CUser',
        'Unlock-CIisConfigurationSection',
        'Unprotect-CString',
        'Write-CDscError',
        'Write-CFile'
    )

    [Collections.Generic.List[String]]$functionNames = New-Object 'Collections.Generic.List[String]'
    foreach( $functionName in $shimmedFunctions )
    {
        [void]$functionNames.Add($functionName)

        $oldFunctionName = $functionName -replace '-C','-'
        $oldFunctionPath = "function:\$($oldFunctionName)"
        if( (Test-Path -Path $oldFunctionPath) )
        {
            $functionInfo = Get-Item -Path $oldFunctionPath
            if( $functionInfo.Source -eq 'Carbon' )
            {
                # For some reason, we had to implement a non-dynamic version of this function.
                [void]$functionNames.Add($oldFunctionName)
                continue
            }

            $functionSource = ''
            if( $functionInfo.Source )
            {
                $functionSource = " in module ""$($functionInfo.Source)"""
            }
            $msg = "Skipping export of Carbon function ""$($oldFunctionName)"": that function already " +
                   "exists$($functionSource)."
            Write-Warning -Message $msg

            continue
        }

        $functionPath = "function:$($functionName)"
        if( -not (Test-Path -Path $functionPath) )
        {
            # Some functions don't exist in 32-bit PowerShell.
            if( $functionName -in @('Initialize-CLcm') )
            {
                continue
            }

            if( -not $exportIisFunctions -and $functionName -like '*-CIis*' )
            {
                Write-Debug "Skipping ""$($functionName)"": IIS isn't installed or not loaded."
                continue
            }

            $msg = "Failed to create $($oldFunctionName) shim because target function $($functionName) does not exist."
            Write-Error -Message $msg
            continue
        }

        Write-Timing "  $($oldFunctionName) -> $($functionName)"
        $cFunctionInfo = Get-Item -Path "function:$($functionName)"
        $preambleStart = $cFunctionInfo.definition.IndexOf('    [CmdletBinding(')
        if( $preambleStart -lt 0 )
        {
            $msg = "Unable to extract ""$($functionName)"" function's parameters: can't find ""[CmdletBinding()]"" " +
                   'attribute.'
            Write-Error -Message $msg
            continue
        }
        $preamble = $cFunctionInfo.definition.Substring($preambleStart)
        $preambleEnd = $preamble.IndexOf('    )')
        if( $preambleEnd -lt 0 )
        {
            $msg = "Unable to extract ""$($functionName)"" function's parameters: can't find "")"" that closes the " +
                   'parameter block.'
            Write-Error -Message $msg
            continue
        }
        $preamble = $preamble.Substring(0, $preambleEnd + 5)
        New-Item -Path 'function:' -Name $oldFunctionName -Value @"
$($preamble)

begin
{
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet `$PSCmdlet -SessionState `$ExecutionContext.SessionState

    Write-CRenamedCommandWarning -CommandName `$MyInvocation.MyCommand.Name -NewCommandName '$($functionName)'
}

process
{
    $($functionName) @PSBoundParameters
}
"@ | Out-Null
        [void]$functionNames.Add($oldFunctionName)
    }

    Write-Timing ('Exporting module members.')
    $functionsToExport = & {
            $module.ExportedFunctions.Keys
            $functionNames
        } |
        Select-Object -Unique
    Export-ModuleMember -Alias '*' -Function $functionsToExport
}
finally
{
    Write-Timing ('DONE')
}