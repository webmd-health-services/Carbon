
function Resolve-WindowsFeatureName
{
    <#
    .SYNOPSIS
    INTERNAL.  DO NOT USE.  Converts a Carbon-specific, common Windows feature name, into the feature name used on the current computer.
    
    .DESCRIPTION
    Windows feature names change between versions.  This function converts a Carbon-specific name into feature names used on the current computer's version of Windows.
    
    **This function is not available on Windows 8/2012.**
    
    .EXAMPLE
    Resolve-WindowsFeatureNames -Name 'Iis','Msmq'
    
    Returns `'IIS-WebServer','MSMQ-Server'` if running Windows 7/Windows 2008 R2, or `'Web-WebServer','MSMQ-Server'` if on Windows 2008.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The Carbon feature names to convert to Windows-specific feature names.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name

    Assert-WindowsFeatureFunctionsSupported -WarningAction SilentlyContinue | Out-Null

    $featureMap = @{
                        Iis = 'Web-WebServer';
                        IisHttpRedirection = 'Web-Http-Redirect';
                        Msmq = 'MSMQ-Server';
                        MsmqHttpSupport = 'MSMQ-HTTP-Support';
                        MsmqActiveDirectoryIntegration = 'MSMQ-Directory';
                   }

    if( $useOCSetup )
    {
        $featureMap = @{
                            Iis = 'IIS-WebServer';
                            IisHttpRedirection = 'IIS-HttpRedirect';
                            Msmq = 'MSMQ-Server';
                            MsmqHttpSupport = 'MSMQ-HTTP';
                            MsmqActiveDirectoryIntegration = 'MSMQ-ADIntegration';
                       }
    }
    
    $Name | 
        Where-Object { $featureMap.ContainsKey( $_ ) } |
        ForEach-Object { $featureMap[$_] }

}

